import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/api/api_client.dart';
import '../../../data/api/api_config.dart';
import '../../../data/auth/device_session.dart';
import '../../../data/wallet/rest_wallet_repository.dart';
import '../domain/currency.dart';
import '../domain/currency_engine.dart';
import '../domain/ledger.dart';
import '../domain/money.dart';
import '../domain/payment_method.dart';
import '../domain/recipient.dart';
import '../domain/transaction.dart';
import '../payments/gateways/airtel_money_gateway.dart';
import '../payments/gateways/card_gateway.dart';
import '../payments/gateways/mpesa_gateway.dart';
import '../payments/gateways/selcom_gateway.dart';
import '../payments/idempotency.dart';
import '../payments/payment_gateway.dart';
import '../payments/payment_router.dart';
import 'wallet_repository.dart';

// === Configuration + network seams =========================================

final apiConfigProvider = Provider<ApiConfig>(
  (ref) => ApiConfig.fromEnvironment(),
);

final deviceSessionProvider = Provider<DeviceSession>(
  (ref) => DeviceSession(ref.watch(apiConfigProvider)),
);

final apiClientProvider = Provider<TaifaApiClient>(
  (ref) => HttpApiClient(
    config: ref.watch(apiConfigProvider),
    session: ref.watch(deviceSessionProvider),
  ),
);

// === Dependency injection seams ============================================

/// Selects the wallet backend. When `--dart-define=TAIFA_USE_REMOTE=true`, the
/// app talks to the real payment service; otherwise it runs fully offline on
/// the seed implementation. The UI is identical either way.
final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  final config = ref.watch(apiConfigProvider);
  if (config.useRemoteBackend) {
    return RestWalletRepository(ref.watch(apiClientProvider));
  }
  return SeedWalletRepository(router: ref.watch(paymentRouterProvider));
});

final currencyEngineProvider = Provider<CurrencyEngine>(
  (ref) => const StaticCurrencyEngine(),
);

final idempotencyStoreProvider = Provider<IdempotencyStore>(
  (ref) => InMemoryIdempotencyStore(),
);

/// The registered rails. Adding a provider is a single list entry — nothing
/// else in the app needs to change.
final paymentGatewaysProvider = Provider<List<PaymentGateway>>(
  (ref) => const [
    MpesaGateway(),
    AirtelMoneyGateway(),
    SelcomGateway(),
    CardGateway(),
  ],
);

final paymentRouterProvider = Provider<PaymentRouter>(
  (ref) => PaymentRouter(ref.watch(paymentGatewaysProvider)),
);

// === Wallet state ==========================================================

class WalletState {
  const WalletState({
    this.snapshot,
    this.displayCurrency = Currency.tzs,
    this.isLoading = true,
    this.ledger = const [],
  });

  final WalletSnapshot? snapshot;
  final Currency displayCurrency;
  final bool isLoading;
  final List<LedgerEntry> ledger;

  WalletState copyWith({
    WalletSnapshot? snapshot,
    Currency? displayCurrency,
    bool? isLoading,
    List<LedgerEntry>? ledger,
  }) => WalletState(
    snapshot: snapshot ?? this.snapshot,
    displayCurrency: displayCurrency ?? this.displayCurrency,
    isLoading: isLoading ?? this.isLoading,
    ledger: ledger ?? this.ledger,
  );
}

/// Result of a send attempt. Sealed so the UI handles success and failure
/// explicitly.
sealed class SendResult {
  const SendResult();
}

class SendSuccess extends SendResult {
  const SendSuccess(this.transaction);
  final WalletTransaction transaction;
}

class SendFailure extends SendResult {
  const SendFailure(this.message, {this.code});
  final String message;
  final String? code;
}

sealed class TopUpResult {
  const TopUpResult();
}

class TopUpSuccess extends TopUpResult {
  const TopUpSuccess(this.transaction, {this.settled = true});
  final WalletTransaction transaction;
  final bool settled;
}

class TopUpFailure extends TopUpResult {
  const TopUpFailure(this.message, {this.code});
  final String message;
  final String? code;
}

/// Coordinates the send flow: it enforces the client-side guards (fast UX
/// feedback) and then **delegates execution to the repository**, which is the
/// authority — the seed posts a local ledger entry, the REST repository calls
/// `POST /transfers`. The controller then reflects the outcome into UI state.
class WalletController extends AsyncNotifier<WalletState> {
  @override
  Future<WalletState> build() async {
    final snapshot = await ref.watch(walletRepositoryProvider).load();
    return WalletState(snapshot: snapshot, isLoading: false);
  }

  void setDisplayCurrency(Currency currency) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(displayCurrency: currency));
  }

  /// Reloads balance/history from the repository (used after async STK settle).
  Future<void> refresh() async {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(isLoading: true));
    try {
      final snapshot = await ref.read(walletRepositoryProvider).load();
      state = AsyncData(current.copyWith(snapshot: snapshot, isLoading: false));
    } on WalletException catch (_) {
      state = AsyncData(current.copyWith(isLoading: false));
    }
  }

  /// Computes the fee for a transfer. A dedicated Fee Engine will own tiered
  /// pricing; today transfers are free per spec.
  Money _feeFor(Money amount) => Money.zero(amount.currency);

  Future<SendResult> sendMoney({
    required Recipient recipient,
    required Money amount,
    String? note,
  }) async {
    final current = state.value;
    final snapshot = current?.snapshot;
    if (current == null || snapshot == null) {
      return const SendFailure('Wallet not ready.');
    }
    if (amount.currency != snapshot.balance.currency) {
      return const SendFailure('Cross-currency send is not enabled yet.');
    }
    if (!amount.isPositive) {
      return const SendFailure('Enter an amount greater than zero.');
    }

    final fee = _feeFor(amount);
    final total = amount + fee;
    if (total > snapshot.balance) {
      return SendFailure(
        'Insufficient balance. You have ${snapshot.balance.format()}.',
      );
    }

    final command = TransferCommand(
      recipient: recipient,
      amount: amount,
      fee: fee,
      idempotencyKey: IdempotencyKeys.generate('send'),
      note: note,
    );

    final TransferReceipt receipt;
    try {
      receipt = await ref.read(walletRepositoryProvider).transfer(command);
    } on WalletException catch (e) {
      return SendFailure(e.message, code: e.code);
    }

    final newBalance = receipt.newBalance ?? (snapshot.balance - total);
    final newSnapshot = WalletSnapshot(
      cardholderName: snapshot.cardholderName,
      cardTier: snapshot.cardTier,
      maskedPan: snapshot.maskedPan,
      balance: newBalance,
      sources: snapshot.sources,
      recipients: snapshot.recipients,
      transactions: [receipt.transaction, ...snapshot.transactions],
    );

    state = AsyncData(
      current.copyWith(
        snapshot: newSnapshot,
        ledger: receipt.ledgerEntry != null
            ? [...current.ledger, receipt.ledgerEntry!]
            : current.ledger,
      ),
    );
    return SendSuccess(receipt.transaction);
  }

  Future<TopUpResult> topUp({
    required Money amount,
    required MobileMoneyMethod source,
    String? note,
  }) async {
    final current = state.value;
    final snapshot = current?.snapshot;
    if (current == null || snapshot == null) {
      return const TopUpFailure('Wallet not ready.');
    }
    if (amount.currency != snapshot.balance.currency) {
      return const TopUpFailure('Cross-currency top-up is not enabled yet.');
    }
    if (!amount.isPositive) {
      return const TopUpFailure('Enter an amount greater than zero.');
    }
    if (amount < Money.major(500, Currency.tzs)) {
      return const TopUpFailure('Minimum top-up is TSh 500.');
    }

    final command = TopUpCommand(
      amount: amount,
      msisdn: source.msisdn,
      operator: source.operator,
      idempotencyKey: IdempotencyKeys.generate('topup'),
      note: note,
    );

    final TopUpReceipt receipt;
    try {
      receipt = await ref.read(walletRepositoryProvider).topUp(command);
    } on WalletException catch (e) {
      return TopUpFailure(e.message, code: e.code);
    }

    final settled = receipt.transaction.status == TransactionStatus.succeeded;
    final newBalance =
        receipt.newBalance ??
        (settled ? snapshot.balance + amount : snapshot.balance);

    final newSnapshot = WalletSnapshot(
      cardholderName: snapshot.cardholderName,
      cardTier: snapshot.cardTier,
      maskedPan: snapshot.maskedPan,
      balance: newBalance,
      sources: snapshot.sources,
      recipients: snapshot.recipients,
      transactions: [receipt.transaction, ...snapshot.transactions],
    );

    state = AsyncData(
      current.copyWith(
        snapshot: newSnapshot,
        ledger: receipt.ledgerEntry != null
            ? [...current.ledger, receipt.ledgerEntry!]
            : current.ledger,
      ),
    );
    return TopUpSuccess(receipt.transaction, settled: settled);
  }

  /// Completes a pending remote STK top-up via the gated demo endpoint, then
  /// reloads wallet so the credited balance shows.
  Future<TopUpResult> completeDemoTopUp(String transactionId) =>
      _settlePendingTopUp(
        () =>
            ref.read(walletRepositoryProvider).completeDemoTopUp(transactionId),
      );

  /// Polls Daraja STK query (live sandbox/prod) then reloads wallet.
  Future<TopUpResult> pollTopUpStatus(String transactionId) =>
      _settlePendingTopUp(
        () => ref.read(walletRepositoryProvider).pollTopUpStatus(transactionId),
      );

  Future<TopUpResult> _settlePendingTopUp(
    Future<TopUpReceipt> Function() settle,
  ) async {
    final current = state.value;
    final snapshot = current?.snapshot;
    if (current == null || snapshot == null) {
      return const TopUpFailure('Wallet not ready.');
    }

    final TopUpReceipt receipt;
    try {
      receipt = await settle();
    } on WalletException catch (e) {
      return TopUpFailure(e.message, code: e.code);
    }

    // Authoritative balance lives on the server after settle.
    try {
      final fresh = await ref.read(walletRepositoryProvider).load();
      state = AsyncData(current.copyWith(snapshot: fresh));
    } on WalletException {
      final settled = receipt.transaction.status == TransactionStatus.succeeded;
      final newBalance = settled
          ? snapshot.balance + receipt.transaction.amount
          : snapshot.balance;
      state = AsyncData(
        current.copyWith(
          snapshot: WalletSnapshot(
            cardholderName: snapshot.cardholderName,
            cardTier: snapshot.cardTier,
            maskedPan: snapshot.maskedPan,
            balance: newBalance,
            sources: snapshot.sources,
            recipients: snapshot.recipients,
            transactions: [
              receipt.transaction,
              ...snapshot.transactions.where(
                (t) => t.id != receipt.transaction.id,
              ),
            ],
          ),
        ),
      );
    }

    final settled = receipt.transaction.status == TransactionStatus.succeeded;
    return TopUpSuccess(receipt.transaction, settled: settled);
  }
}

final walletControllerProvider =
    AsyncNotifierProvider<WalletController, WalletState>(WalletController.new);

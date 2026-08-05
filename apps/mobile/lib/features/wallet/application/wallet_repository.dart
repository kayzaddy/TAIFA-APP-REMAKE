import '../domain/currency.dart';
import '../domain/ledger.dart';
import '../domain/money.dart';
import '../domain/payment_method.dart';
import '../domain/recipient.dart';
import '../domain/transaction.dart';
import '../payments/gateways/airtel_money_gateway.dart';
import '../payments/gateways/card_gateway.dart';
import '../payments/gateways/mpesa_gateway.dart';
import '../payments/gateways/selcom_gateway.dart';
import '../payments/payment_gateway.dart';
import '../payments/payment_provider.dart';
import '../payments/payment_router.dart';
import 'wallet_profile.dart';

/// House ledger accounts + the current user's wallet account. In production the
/// chart of accounts lives in Postgres; the identifiers stay stable.
class WalletLedgerAccounts {
  const WalletLedgerAccounts._();

  static const userWalletTzs = LedgerAccount(
    id: 'user:amani:wallet:TZS',
    type: LedgerAccountType.userWallet,
    currency: Currency.tzs,
    owner: 'amani',
  );

  static const feeIncomeTzs = LedgerAccount(
    id: 'house:fee-income:TZS',
    type: LedgerAccountType.feeIncome,
    currency: Currency.tzs,
  );

  static const providerSettlementTzs = LedgerAccount(
    id: 'house:provider-settlement:TZS',
    type: LedgerAccountType.providerSettlement,
    currency: Currency.tzs,
  );
}

/// An immutable snapshot of everything the Wallet surface needs to render.
class WalletSnapshot {
  const WalletSnapshot({
    required this.cardholderName,
    required this.cardTier,
    required this.maskedPan,
    required this.balance,
    required this.sources,
    required this.recipients,
    required this.transactions,
  });

  final String cardholderName;
  final String cardTier;
  final String maskedPan;
  final Money balance; // primary balance, in TZS
  final List<PaymentMethod> sources;
  final List<Recipient> recipients;
  final List<WalletTransaction> transactions;

  /// Builds a snapshot from static profile scaffolding + live money data. Used
  /// by every repository so the two implementations render identically.
  factory WalletSnapshot.fromProfile(
    WalletProfile profile, {
    required Money balance,
    required List<WalletTransaction> transactions,
  }) {
    return WalletSnapshot(
      cardholderName: profile.cardholderName,
      cardTier: profile.cardTier,
      maskedPan: profile.maskedPan,
      balance: balance,
      sources: profile.sources,
      recipients: profile.recipients,
      transactions: transactions,
    );
  }
}

/// An intent to move money out of the wallet. Built by the controller and handed
/// to the repository, which is the authority that actually executes it (locally
/// for the seed, or via `POST /transfers` for the REST implementation).
class TransferCommand {
  const TransferCommand({
    required this.recipient,
    required this.amount,
    required this.fee,
    required this.idempotencyKey,
    this.note,
  });

  final Recipient recipient;
  final Money amount;
  final Money fee;
  final String idempotencyKey;
  final String? note;

  Money get total => amount + fee;
}

/// The result of a transfer as the source of truth reports it. `ledgerEntry` is
/// populated only when the client posted the entry itself (seed/offline mode);
/// the REST implementation leaves it null because the server owns the ledger.
class TransferReceipt {
  const TransferReceipt({
    required this.transaction,
    this.ledgerEntry,
    this.newBalance,
  });

  final WalletTransaction transaction;
  final LedgerEntry? ledgerEntry;
  final Money? newBalance;
}

/// A domain-level failure the UI can present. Transport concerns (HTTP status,
/// timeouts) are translated into this by the REST repository.
class WalletException implements Exception {
  const WalletException(this.message, {this.code});
  final String message;
  final String? code;

  @override
  String toString() => 'WalletException: $message';
}

/// Data boundary for the wallet. The UI + controller depend on this interface;
/// the seed implementation is swapped for the REST-backed one with no
/// downstream changes.
abstract interface class WalletRepository {
  Future<WalletSnapshot> load();

  /// Executes a transfer. Throws [WalletException] on failure.
  Future<TransferReceipt> transfer(TransferCommand command);

  /// Initiates an M-Pesa (or other MM) STK-push top-up into the wallet.
  /// Seed settles immediately for Demo Complete; REST returns `processing`
  /// until the webhook credits the ledger.
  Future<TopUpReceipt> topUp(TopUpCommand command);

  /// Gated demo settle for a pending STK top-up (`POST …/demo-complete`).
  /// Seed is a no-op (already settled). REST synthesizes the webhook when the
  /// backend allows it.
  Future<TopUpReceipt> completeDemoTopUp(String transactionId);

  /// Polls Daraja STK query for a pending top-up (`POST …/poll-status`) and
  /// returns the updated transaction (settled when PIN completed).
  Future<TopUpReceipt> pollTopUpStatus(String transactionId);
}

/// Intent to fund the wallet from mobile money via STK push.
class TopUpCommand {
  const TopUpCommand({
    required this.amount,
    required this.msisdn,
    required this.operator,
    required this.idempotencyKey,
    this.note,
  });

  final Money amount;
  final String msisdn;
  final MobileMoneyOperator operator;
  final String idempotencyKey;
  final String? note;
}

class TopUpReceipt {
  const TopUpReceipt({
    required this.transaction,
    this.ledgerEntry,
    this.newBalance,
  });

  final WalletTransaction transaction;
  final LedgerEntry? ledgerEntry;

  /// Set when the rail settled synchronously (seed path). Null when still
  /// awaiting STK confirmation (REST / live Daraja).
  final Money? newBalance;

  bool get isSettled =>
      transaction.status == TransactionStatus.succeeded && newBalance != null;
}

/// Offline/demo implementation. It exercises the *client* payment router so the
/// provider-abstraction path stays live without a backend, and posts a balanced
/// double-entry ledger record locally. The REST implementation supersedes it
/// when the backend is enabled.
class SeedWalletRepository implements WalletRepository {
  SeedWalletRepository({PaymentRouter? router})
    : _router =
          router ??
          PaymentRouter(const [
            MpesaGateway(),
            AirtelMoneyGateway(),
            SelcomGateway(),
            CardGateway(),
          ]);

  final PaymentRouter _router;
  int _seq = 0;
  Money _balance = Money.major(2847500, Currency.tzs);
  final List<WalletTransaction> _txns = [];

  @override
  Future<WalletSnapshot> load() async {
    return WalletSnapshot.fromProfile(
      defaultWalletProfile,
      balance: _balance,
      transactions: [..._txns, ...seedTransactions()],
    );
  }

  @override
  Future<TransferReceipt> transfer(TransferCommand command) async {
    final amount = command.amount;
    final fee = command.fee;
    final txnId = 'txn-${DateTime.now().millisecondsSinceEpoch}-${_seq++}';

    final isInternal = command.recipient.method is TaifaWalletMethod;
    PaymentResult result;
    if (isInternal) {
      result = PaymentAccepted(
        provider: PaymentProvider.selcom,
        providerRef: 'INTERNAL-$txnId',
      );
    } else {
      final request = PaymentRequest(
        idempotencyKey: command.idempotencyKey,
        reference: txnId,
        amount: amount,
        method: command.recipient.method,
        operation: PaymentOperation.payout,
        narrative: command.note,
      );
      try {
        result = await _router.resolve(request).payout(request);
      } on PaymentContractException catch (e) {
        throw WalletException(e.message, code: 'ROUTING');
      }
    }

    switch (result) {
      case PaymentFailed(:final message, :final code):
        throw WalletException(message, code: code);
      case PaymentAccepted() || PaymentPending():
        final providerRef = switch (result) {
          PaymentAccepted(:final providerRef) => providerRef,
          PaymentPending(:final providerRef) => providerRef,
          _ => null,
        };
        final status = result is PaymentPending
            ? TransactionStatus.processing
            : TransactionStatus.succeeded;

        // Constructing the entry asserts money is conserved; a bug throws here
        // rather than silently corrupting balances.
        final entry = LedgerEntry(
          id: 'led-$txnId',
          transactionId: txnId,
          createdAt: DateTime.now(),
          description: 'Send to ${command.recipient.name}',
          postings: [
            Posting.debit(WalletLedgerAccounts.userWalletTzs, command.total),
            Posting.credit(WalletLedgerAccounts.providerSettlementTzs, amount),
            if (!fee.isZero)
              Posting.credit(WalletLedgerAccounts.feeIncomeTzs, fee),
          ],
        );

        final txn = WalletTransaction(
          id: txnId,
          type: TransactionType.sendMoney,
          status: status,
          direction: TransactionDirection.debit,
          amount: amount,
          fee: fee,
          counterparty: command.recipient.name,
          method: command.recipient.method,
          createdAt: DateTime.now(),
          idempotencyKey: command.idempotencyKey,
          note: command.note,
          providerRef: providerRef,
          ledgerEntryId: entry.id,
        );

        if (status == TransactionStatus.succeeded) {
          _balance = _balance - command.total;
          _txns.insert(0, txn);
        }

        return TransferReceipt(
          transaction: txn,
          ledgerEntry: entry,
          newBalance: status == TransactionStatus.succeeded ? _balance : null,
        );
    }
  }

  @override
  Future<TopUpReceipt> topUp(TopUpCommand command) async {
    final amount = command.amount;
    if (!amount.isPositive) {
      throw const WalletException(
        'Enter an amount greater than zero.',
        code: 'AMOUNT',
      );
    }
    final txnId =
        'txn-topup-${DateTime.now().millisecondsSinceEpoch}-${_seq++}';
    final method = MobileMoneyMethod(
      id: 'topup-${command.operator.name}',
      label: command.operator.displayName,
      operator: command.operator,
      msisdn: command.msisdn,
    );
    final request = PaymentRequest(
      idempotencyKey: command.idempotencyKey,
      reference: txnId,
      amount: amount,
      method: method,
      operation: PaymentOperation.charge,
      narrative: command.note ?? 'TAIFA top-up',
    );

    final PaymentResult result;
    try {
      result = await _router.resolve(request).charge(request);
    } on PaymentContractException catch (e) {
      throw WalletException(e.message, code: 'ROUTING');
    }

    switch (result) {
      case PaymentFailed(:final message, :final code):
        throw WalletException(message, code: code);
      case PaymentAccepted() || PaymentPending():
        // Demo Complete: STK push is simulated, then we auto-settle locally so
        // the UI can show a credit without a real Daraja webhook.
        await Future<void>.delayed(const Duration(milliseconds: 350));
        final providerRef = switch (result) {
          PaymentAccepted(:final providerRef) => providerRef,
          PaymentPending(:final providerRef) => providerRef,
          _ => null,
        };
        final entry = LedgerEntry(
          id: 'led-$txnId',
          transactionId: txnId,
          createdAt: DateTime.now(),
          description: 'Top-up via ${command.operator.displayName}',
          postings: [
            Posting.debit(WalletLedgerAccounts.providerSettlementTzs, amount),
            Posting.credit(WalletLedgerAccounts.userWalletTzs, amount),
          ],
        );
        final txn = WalletTransaction(
          id: txnId,
          type: TransactionType.topUp,
          status: TransactionStatus.succeeded,
          direction: TransactionDirection.credit,
          amount: amount,
          fee: Money.zero(amount.currency),
          counterparty: 'Top-up · ${command.operator.displayName}',
          method: method,
          createdAt: DateTime.now(),
          idempotencyKey: command.idempotencyKey,
          note: command.note,
          providerRef: providerRef,
          ledgerEntryId: entry.id,
        );
        _balance = _balance + amount;
        _txns.insert(0, txn);
        return TopUpReceipt(
          transaction: txn,
          ledgerEntry: entry,
          newBalance: _balance,
        );
    }
  }

  @override
  Future<TopUpReceipt> completeDemoTopUp(String transactionId) async {
    // Seed top-ups already settle in [topUp]; nothing to demo-complete.
    final match = _txns.where((t) => t.id == transactionId);
    if (match.isEmpty) {
      throw const WalletException('Top-up not found.', code: 'NOT_FOUND');
    }
    return TopUpReceipt(transaction: match.first, newBalance: _balance);
  }

  @override
  Future<TopUpReceipt> pollTopUpStatus(String transactionId) async {
    // Seed path has no async STK — same as demo-complete.
    return completeDemoTopUp(transactionId);
  }
}

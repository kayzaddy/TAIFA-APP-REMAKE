import '../../features/wallet/application/wallet_profile.dart';
import '../../features/wallet/application/wallet_repository.dart';
import '../../features/wallet/domain/payment_method.dart';
import '../../features/wallet/domain/transaction.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../dto/transaction_dto.dart';
import '../dto/wallet_dto.dart';
import 'payment_api_paths.dart';

/// The live [WalletRepository]: it fulfils the exact same interface the seed
/// implementation does, but reads the authoritative balance from
/// `GET /payments/wallet` and executes sends through `POST /payments/transfers`.
///
/// Because the UI and controller depend only on the interface, swapping this in
/// requires **zero** UI changes — this class is the whole of the wiring.
class RestWalletRepository implements WalletRepository {
  RestWalletRepository(this._client, {WalletProfile? profile})
    : _profile = profile ?? defaultWalletProfile;

  final TaifaApiClient _client;
  final WalletProfile _profile;

  @override
  Future<WalletSnapshot> load() async {
    try {
      final dto = WalletDto.fromJson(
        await _client.getJson(PaymentApiPaths.wallet),
      );
      return WalletSnapshot.fromProfile(
        _profile,
        balance: dto.balance,
        transactions: dto.transactions,
      );
    } on ApiException catch (e) {
      throw _toWalletException(e);
    }
  }

  @override
  Future<TransferReceipt> transfer(TransferCommand command) async {
    final method = command.recipient.method;
    final body = <String, dynamic>{
      'amount_minor': command.amount.minorUnits,
      'currency': command.amount.currency.code,
      'counterparty': command.recipient.name,
      'method_kind': _methodKind(method),
      'method_ref': _methodRef(method),
      'operator': _operator(method),
      if (command.note != null) 'note': command.note,
    };

    final Map<String, dynamic> json;
    try {
      json = await _client.postJson(
        PaymentApiPaths.transfers,
        body: body,
        idempotencyKey: command.idempotencyKey,
      );
    } on ApiException catch (e) {
      throw _toWalletException(e);
    }

    final txn = TransactionDto.toDomain(json);
    if (txn.status == TransactionStatus.failed) {
      throw const WalletException(
        'The transfer was declined.',
        code: 'DECLINED',
      );
    }
    return TransferReceipt(transaction: txn);
  }

  @override
  Future<TopUpReceipt> topUp(TopUpCommand command) async {
    final body = <String, dynamic>{
      'amount_minor': command.amount.minorUnits,
      'currency': command.amount.currency.code,
      'msisdn': command.msisdn.replaceAll(RegExp(r'[^0-9+]'), ''),
      'operator': operatorToApi(command.operator),
      if (command.note != null) 'note': command.note,
    };

    final Map<String, dynamic> json;
    try {
      json = await _client.postJson(
        PaymentApiPaths.topups,
        body: body,
        idempotencyKey: command.idempotencyKey,
      );
    } on ApiException catch (e) {
      throw _toWalletException(e);
    }

    final txn = TransactionDto.toDomain(json);
    if (txn.status == TransactionStatus.failed) {
      throw const WalletException('The top-up was declined.', code: 'DECLINED');
    }
    // Live STK stays processing until webhook; no client-side balance guess.
    return TopUpReceipt(transaction: txn);
  }

  @override
  Future<TopUpReceipt> completeDemoTopUp(String transactionId) async {
    final Map<String, dynamic> json;
    try {
      json = await _client.postJson(
        PaymentApiPaths.demoComplete(transactionId),
      );
    } on ApiException catch (e) {
      throw _toWalletException(e);
    }
    final txn = TransactionDto.toDomain(json);
    if (txn.status == TransactionStatus.failed) {
      throw const WalletException('The top-up was declined.', code: 'DECLINED');
    }
    return TopUpReceipt(transaction: txn);
  }

  @override
  Future<TopUpReceipt> pollTopUpStatus(String transactionId) async {
    final Map<String, dynamic> json;
    try {
      json = await _client.postJson(PaymentApiPaths.pollStatus(transactionId));
    } on ApiException catch (e) {
      throw _toWalletException(e);
    }
    final txn = TransactionDto.toDomain(json);
    if (txn.status == TransactionStatus.failed) {
      throw const WalletException('The top-up was declined.', code: 'DECLINED');
    }
    return TopUpReceipt(transaction: txn);
  }

  // --- domain → wire mapping -------------------------------------------------

  String _methodKind(PaymentMethod method) => switch (method) {
    TaifaWalletMethod() => 'wallet',
    MobileMoneyMethod() => 'mobile_money',
    CardMethod() => 'card',
    BankMethod() => 'bank',
  };

  String _methodRef(PaymentMethod method) => switch (method) {
    TaifaWalletMethod() => '',
    MobileMoneyMethod(:final msisdn) => _digits(msisdn),
    CardMethod(:final last4) => last4,
    BankMethod(:final accountMasked) => accountMasked,
  };

  String _operator(PaymentMethod method) => switch (method) {
    MobileMoneyMethod(:final operator) => operatorToApi(operator),
    _ => '',
  };

  String _digits(String value) => value.replaceAll(RegExp(r'[^0-9+]'), '');

  WalletException _toWalletException(ApiException e) => switch (e) {
    NetworkException() => WalletException(e.message, code: 'NETWORK'),
    ApiStatusException(:final message, :final statusCode) => WalletException(
      message,
      code: 'HTTP_$statusCode',
    ),
    ApiDecodeException() => WalletException(e.message, code: 'DECODE'),
  };
}

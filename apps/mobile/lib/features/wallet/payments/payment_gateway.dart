import '../domain/money.dart';
import '../domain/payment_method.dart';
import 'payment_provider.dart';

/// A provider-agnostic instruction to move money. Carries the mandatory
/// [idempotencyKey] and the internal [reference] (our transaction id) so
/// requests can be correlated and safely retried.
class PaymentRequest {
  const PaymentRequest({
    required this.idempotencyKey,
    required this.reference,
    required this.amount,
    required this.method,
    required this.operation,
    this.narrative,
    this.metadata = const {},
  });

  final String idempotencyKey;
  final String reference;
  final Money amount;
  final PaymentMethod method;
  final PaymentOperation operation;
  final String? narrative;
  final Map<String, String> metadata;
}

/// Outcome of a payment instruction. Sealed so callers must handle every case
/// exhaustively — no silent "unknown state" money bugs.
sealed class PaymentResult {
  const PaymentResult({required this.provider});
  final PaymentProvider provider;
}

/// Synchronously confirmed — money has moved on the rail.
class PaymentAccepted extends PaymentResult {
  const PaymentAccepted({
    required super.provider,
    required this.providerRef,
    this.rawStatus = 'ACCEPTED',
  });
  final String providerRef;
  final String rawStatus;
}

/// Accepted for processing; final state arrives asynchronously (e.g. STK-push
/// awaiting PIN, or a settlement webhook). Poll [PaymentGateway.status] or wait
/// for the webhook keyed by [providerRef].
class PaymentPending extends PaymentResult {
  const PaymentPending({
    required super.provider,
    required this.providerRef,
    this.rawStatus = 'PENDING',
  });
  final String providerRef;
  final String rawStatus;
}

/// The rail rejected or failed the instruction. [retryable] tells the retry
/// engine whether a new attempt (same idempotency key) may succeed.
class PaymentFailed extends PaymentResult {
  const PaymentFailed({
    required super.provider,
    required this.code,
    required this.message,
    this.retryable = false,
    this.providerRef,
  });
  final String code;
  final String message;
  final bool retryable;
  final String? providerRef;
}

/// Thrown for programming/contract errors (never for expected declines, which
/// are modelled as [PaymentFailed]).
class PaymentContractException implements Exception {
  PaymentContractException(this.message);
  final String message;
  @override
  String toString() => 'PaymentContractException: $message';
}

/// The single seam every payment rail implements. Adding M-Pesa, Airtel, a
/// bank or a card scheme means writing one class against this interface — the
/// transaction engine, ledger and UI stay untouched.
abstract interface class PaymentGateway {
  PaymentProvider get provider;
  Set<PaymentCapability> get capabilities;

  /// Whether this gateway can service [request] (capability, currency, limits).
  bool canHandle(PaymentRequest request);

  /// Pull funds in (collection).
  Future<PaymentResult> charge(PaymentRequest request);

  /// Push funds out (disbursement/payout).
  Future<PaymentResult> payout(PaymentRequest request);

  /// Reverse a settled payment, in full or part.
  Future<PaymentResult> refund(PaymentRequest request);

  /// Query the current state of a previously accepted instruction.
  Future<PaymentResult> status(String providerRef);
}

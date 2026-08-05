import '../../domain/currency.dart';
import '../../domain/money.dart';
import '../payment_gateway.dart';
import '../payment_provider.dart';

/// Shared behaviour for the seed/sandbox gateways used before live provider SDKs
/// are wired. Concrete adapters declare their identity, capabilities, supported
/// currencies and limits; this base enforces [canHandle] and simulates realistic
/// latency and outcomes. Swapping to a real SDK means replacing the `charge` /
/// `payout` bodies only.
abstract class SimulatedGatewayBase implements PaymentGateway {
  const SimulatedGatewayBase();

  Set<Currency> get supportedCurrencies;
  Money get minAmount;
  Money? get maxAmount;

  /// Simulated round-trip latency for the rail.
  Duration get latency => const Duration(milliseconds: 450);

  /// Whether the collection leg completes synchronously (card) or needs a
  /// customer action first (mobile-money STK push → pending).
  bool get chargeIsSynchronous => false;

  @override
  bool canHandle(PaymentRequest request) {
    if (!supportedCurrencies.contains(request.amount.currency)) return false;
    final capNeeded = switch (request.operation) {
      PaymentOperation.charge => PaymentCapability.charge,
      PaymentOperation.payout => PaymentCapability.payout,
      PaymentOperation.refund => PaymentCapability.refund,
    };
    if (!capabilities.contains(capNeeded)) return false;
    // Limits are only enforced when denominated in the same currency as the
    // request; cross-currency limits are handled by the currency engine later.
    final amount = request.amount;
    if (amount.currency == minAmount.currency && amount < minAmount) {
      return false;
    }
    final max = maxAmount;
    if (max != null && amount.currency == max.currency && amount > max) {
      return false;
    }
    return true;
  }

  String _ref() =>
      '${provider.name.toUpperCase()}-${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';

  @override
  Future<PaymentResult> charge(PaymentRequest request) async {
    await Future<void>.delayed(latency);
    if (!canHandle(request)) {
      return PaymentFailed(
        provider: provider,
        code: 'UNSUPPORTED',
        message: '${provider.displayName} cannot handle this request.',
      );
    }
    return chargeIsSynchronous
        ? PaymentAccepted(provider: provider, providerRef: _ref())
        : PaymentPending(
            provider: provider,
            providerRef: _ref(),
            rawStatus: 'AWAITING_CUSTOMER',
          );
  }

  @override
  Future<PaymentResult> payout(PaymentRequest request) async {
    await Future<void>.delayed(latency);
    if (!canHandle(request)) {
      return PaymentFailed(
        provider: provider,
        code: 'UNSUPPORTED',
        message: '${provider.displayName} cannot handle this request.',
      );
    }
    return PaymentAccepted(provider: provider, providerRef: _ref());
  }

  @override
  Future<PaymentResult> refund(PaymentRequest request) async {
    await Future<void>.delayed(latency);
    return PaymentAccepted(
      provider: provider,
      providerRef: _ref(),
      rawStatus: 'REFUNDED',
    );
  }

  @override
  Future<PaymentResult> status(String providerRef) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return PaymentAccepted(provider: provider, providerRef: providerRef);
  }
}

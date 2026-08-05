import '../../domain/currency.dart';
import '../../domain/money.dart';
import '../payment_provider.dart';
import 'simulated_gateway_base.dart';

/// Card scheme rail (Visa/Mastercard) via an acquirer. Card charges settle
/// synchronously in this simulation once authorised.
class CardGateway extends SimulatedGatewayBase {
  const CardGateway();

  @override
  PaymentProvider get provider => PaymentProvider.cardScheme;

  @override
  Set<PaymentCapability> get capabilities => const {
    PaymentCapability.charge,
    PaymentCapability.refund,
    PaymentCapability.statusQuery,
    PaymentCapability.card,
  };

  @override
  Set<Currency> get supportedCurrencies => const {
    Currency.tzs,
    Currency.usd,
    Currency.eur,
    Currency.kes,
  };

  @override
  bool get chargeIsSynchronous => true;

  @override
  Duration get latency => const Duration(milliseconds: 650);

  @override
  Money get minAmount => Money.major(1, Currency.usd);

  @override
  Money? get maxAmount => null;
}

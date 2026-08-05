import '../../domain/currency.dart';
import '../../domain/money.dart';
import '../payment_provider.dart';
import 'simulated_gateway_base.dart';

/// Selcom aggregator — spans multiple mobile-money operators, cards and bank
/// rails. Useful as a fallback when a direct operator rail is unavailable.
class SelcomGateway extends SimulatedGatewayBase {
  const SelcomGateway();

  @override
  PaymentProvider get provider => PaymentProvider.selcom;

  @override
  Set<PaymentCapability> get capabilities => const {
    PaymentCapability.charge,
    PaymentCapability.payout,
    PaymentCapability.refund,
    PaymentCapability.statusQuery,
    PaymentCapability.mobileMoney,
    PaymentCapability.card,
    PaymentCapability.bank,
  };

  @override
  Set<Currency> get supportedCurrencies => const {
    Currency.tzs,
    Currency.kes,
    Currency.usd,
  };

  @override
  Money get minAmount => Money.major(100, Currency.tzs);

  @override
  Money? get maxAmount => null;
}

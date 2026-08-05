import '../../domain/currency.dart';
import '../../domain/money.dart';
import '../payment_provider.dart';
import 'simulated_gateway_base.dart';

/// Airtel Money rail — mobile-money collection and disbursement in TZS.
class AirtelMoneyGateway extends SimulatedGatewayBase {
  const AirtelMoneyGateway();

  @override
  PaymentProvider get provider => PaymentProvider.airtelMoney;

  @override
  Set<PaymentCapability> get capabilities => const {
    PaymentCapability.charge,
    PaymentCapability.payout,
    PaymentCapability.statusQuery,
    PaymentCapability.mobileMoney,
  };

  @override
  Set<Currency> get supportedCurrencies => const {Currency.tzs};

  @override
  Money get minAmount => Money.major(500, Currency.tzs);

  @override
  Money? get maxAmount => Money.major(10000000, Currency.tzs);
}

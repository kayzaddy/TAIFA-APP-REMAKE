import '../../domain/currency.dart';
import '../../domain/money.dart';
import '../payment_provider.dart';
import 'simulated_gateway_base.dart';

/// M-Pesa (Vodacom) rail. Mobile-money collection via STK push (async) and
/// disbursement (B2C) payouts. Real integration will replace the simulated
/// bodies in [SimulatedGatewayBase] with the Daraja API client.
class MpesaGateway extends SimulatedGatewayBase {
  const MpesaGateway();

  @override
  PaymentProvider get provider => PaymentProvider.mpesa;

  @override
  Set<PaymentCapability> get capabilities => const {
    PaymentCapability.charge,
    PaymentCapability.payout,
    PaymentCapability.refund,
    PaymentCapability.statusQuery,
    PaymentCapability.mobileMoney,
  };

  @override
  Set<Currency> get supportedCurrencies => const {Currency.tzs, Currency.kes};

  @override
  Money get minAmount => Money.major(500, Currency.tzs);

  @override
  Money? get maxAmount => Money.major(20000000, Currency.tzs);
}

import 'package:flutter_test/flutter_test.dart';
import 'package:taifa/features/wallet/domain/currency.dart';
import 'package:taifa/features/wallet/domain/money.dart';
import 'package:taifa/features/wallet/domain/payment_method.dart';
import 'package:taifa/features/wallet/payments/gateways/airtel_money_gateway.dart';
import 'package:taifa/features/wallet/payments/gateways/card_gateway.dart';
import 'package:taifa/features/wallet/payments/gateways/mpesa_gateway.dart';
import 'package:taifa/features/wallet/payments/gateways/selcom_gateway.dart';
import 'package:taifa/features/wallet/payments/payment_gateway.dart';
import 'package:taifa/features/wallet/payments/payment_provider.dart';
import 'package:taifa/features/wallet/payments/payment_router.dart';

void main() {
  final router = PaymentRouter(const [
    MpesaGateway(),
    AirtelMoneyGateway(),
    SelcomGateway(),
    CardGateway(),
  ]);

  PaymentRequest request(PaymentMethod method, Money amount) => PaymentRequest(
    idempotencyKey: 'k',
    reference: 'r',
    amount: amount,
    method: method,
    operation: PaymentOperation.payout,
  );

  const mpesaMethod = MobileMoneyMethod(
    id: 'm',
    label: 'x',
    operator: MobileMoneyOperator.mpesa,
    msisdn: '+255700000000',
  );

  group('PaymentRouter', () {
    test('routes an M-Pesa payment to the M-Pesa rail', () {
      final gw = router.resolve(
        request(mpesaMethod, Money.major(50000, Currency.tzs)),
      );
      expect(gw.provider, PaymentProvider.mpesa);
    });

    test('falls back to Selcom when the direct rail exceeds its limit', () {
      // M-Pesa max is 20M TZS; 25M must fall back to the aggregator.
      final gw = router.resolve(
        request(mpesaMethod, Money.major(25000000, Currency.tzs)),
      );
      expect(gw.provider, PaymentProvider.selcom);
    });

    test('throws a contract error when no rail supports the currency', () {
      // No registered rail supports UGX.
      expect(
        () => router.resolve(
          request(mpesaMethod, Money.major(1000, Currency.ugx)),
        ),
        throwsA(isA<PaymentContractException>()),
      );
    });

    test('candidates lists every capable rail', () {
      final c = router.candidates(
        request(mpesaMethod, Money.major(50000, Currency.tzs)),
      );
      // M-Pesa, Airtel and Selcom all handle TZS mobile-money payouts.
      expect(
        c.map((g) => g.provider),
        containsAll([
          PaymentProvider.mpesa,
          PaymentProvider.airtelMoney,
          PaymentProvider.selcom,
        ]),
      );
    });
  });
}

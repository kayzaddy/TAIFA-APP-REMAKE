import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taifa/features/wallet/application/wallet_providers.dart';
import 'package:taifa/features/wallet/domain/currency.dart';
import 'package:taifa/features/wallet/domain/money.dart';
import 'package:taifa/features/wallet/domain/payment_method.dart';
import 'package:taifa/features/wallet/domain/transaction.dart';

void main() {
  group('WalletController.topUp', () {
    late ProviderContainer container;

    setUp(() async {
      container = ProviderContainer();
      await container.read(walletControllerProvider.future);
    });

    tearDown(() => container.dispose());

    test(
      'credits balance via simulated STK and appends a top-up txn',
      () async {
        final before = container.read(walletControllerProvider).value!;
        final start = before.snapshot!.balance;
        final source = before.snapshot!.sources
            .whereType<MobileMoneyMethod>()
            .first;
        final amount = Money.major(50000, Currency.tzs);

        final result = await container
            .read(walletControllerProvider.notifier)
            .topUp(amount: amount, source: source, note: 'test top-up');

        expect(result, isA<TopUpSuccess>());
        final success = result as TopUpSuccess;
        expect(success.settled, isTrue);
        expect(success.transaction.type, TransactionType.topUp);
        expect(success.transaction.direction, TransactionDirection.credit);

        final after = container.read(walletControllerProvider).value!;
        expect(after.snapshot!.balance, start + amount);
        expect(after.snapshot!.transactions.first.type, TransactionType.topUp);
        expect(after.ledger, isNotEmpty);
      },
    );

    test('rejects amounts below the M-Pesa minimum', () async {
      final before = container.read(walletControllerProvider).value!;
      final source = before.snapshot!.sources
          .whereType<MobileMoneyMethod>()
          .first;

      final result = await container
          .read(walletControllerProvider.notifier)
          .topUp(amount: Money.major(100, Currency.tzs), source: source);

      expect(result, isA<TopUpFailure>());
      expect(
        container.read(walletControllerProvider).value!.snapshot!.balance,
        before.snapshot!.balance,
      );
    });
  });
}

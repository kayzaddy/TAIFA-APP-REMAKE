import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taifa/features/wallet/application/wallet_providers.dart';
import 'package:taifa/features/wallet/domain/currency.dart';
import 'package:taifa/features/wallet/domain/money.dart';

void main() {
  group('WalletController.sendMoney', () {
    late ProviderContainer container;

    setUp(() async {
      container = ProviderContainer();
      // Wait for the initial async load to complete.
      await container.read(walletControllerProvider.future);
    });

    tearDown(() => container.dispose());

    test(
      'debits balance, appends a transaction and posts a balanced ledger entry',
      () async {
        final before = container.read(walletControllerProvider).value!;
        final startBalance = before.snapshot!.balance;
        final recipient = before.snapshot!.recipients.first; // Fatima (M-Pesa)
        final amount = Money.major(250000, Currency.tzs);

        final result = await container
            .read(walletControllerProvider.notifier)
            .sendMoney(recipient: recipient, amount: amount, note: 'test');

        expect(result, isA<SendSuccess>());

        final after = container.read(walletControllerProvider).value!;
        expect(after.snapshot!.balance, startBalance - amount);

        final txn = after.snapshot!.transactions.first;
        expect(txn.counterparty, recipient.name);
        expect(txn.amount, amount);
        expect(txn.ledgerEntryId, isNotNull);

        // A double-entry record was appended (its constructor already asserted
        // that money is conserved).
        expect(after.ledger.length, 1);
        expect(after.ledger.first.transactionId, txn.id);
      },
    );

    test('rejects a send that exceeds the available balance', () async {
      final before = container.read(walletControllerProvider).value!;
      final recipient = before.snapshot!.recipients.first;
      final tooMuch = before.snapshot!.balance + Money.major(1, Currency.tzs);

      final result = await container
          .read(walletControllerProvider.notifier)
          .sendMoney(recipient: recipient, amount: tooMuch);

      expect(result, isA<SendFailure>());
      // Balance unchanged.
      final after = container.read(walletControllerProvider).value!;
      expect(after.snapshot!.balance, before.snapshot!.balance);
    });
  });
}

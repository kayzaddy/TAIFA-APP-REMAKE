import 'package:flutter_test/flutter_test.dart';
import 'package:taifa/features/wallet/domain/currency.dart';
import 'package:taifa/features/wallet/domain/ledger.dart';
import 'package:taifa/features/wallet/domain/money.dart';

void main() {
  const wallet = LedgerAccount(
    id: 'user:wallet:TZS',
    type: LedgerAccountType.userWallet,
    currency: Currency.tzs,
  );
  const settlement = LedgerAccount(
    id: 'house:settlement:TZS',
    type: LedgerAccountType.providerSettlement,
    currency: Currency.tzs,
  );
  const fees = LedgerAccount(
    id: 'house:fees:TZS',
    type: LedgerAccountType.feeIncome,
    currency: Currency.tzs,
  );

  LedgerEntry build(List<Posting> postings) => LedgerEntry(
    id: 'e1',
    transactionId: 't1',
    createdAt: DateTime(2026),
    description: 'test',
    postings: postings,
  );

  group('LedgerEntry', () {
    test('accepts a balanced double-entry (debit = credit)', () {
      final amount = Money.major(250000, Currency.tzs);
      final entry = build([
        Posting.debit(wallet, amount),
        Posting.credit(settlement, amount),
      ]);
      expect(entry.postings.length, 2);
      // Convention: debit is positive, credit is negative; a balanced entry
      // nets to zero. The wallet is debited, the settlement float credited.
      expect(entry.effectOn(wallet), amount);
      expect(entry.effectOn(settlement), -amount);
    });

    test('balances a transfer with a fee split across accounts', () {
      final amount = Money.major(100000, Currency.tzs);
      final fee = Money.major(500, Currency.tzs);
      final entry = build([
        Posting.debit(wallet, amount + fee),
        Posting.credit(settlement, amount),
        Posting.credit(fees, fee),
      ]);
      expect(entry.effectOn(wallet), amount + fee);
    });

    test('rejects an unbalanced entry', () {
      expect(
        () => build([
          Posting.debit(wallet, Money.major(100, Currency.tzs)),
          Posting.credit(settlement, Money.major(90, Currency.tzs)),
        ]),
        throwsA(isA<UnbalancedLedgerEntry>()),
      );
    });

    test('postings are immutable', () {
      final entry = build([
        Posting.debit(wallet, Money.major(1, Currency.tzs)),
        Posting.credit(settlement, Money.major(1, Currency.tzs)),
      ]);
      expect(
        () => entry.postings.add(
          Posting.debit(wallet, Money.major(1, Currency.tzs)),
        ),
        throwsUnsupportedError,
      );
    });
  });
}

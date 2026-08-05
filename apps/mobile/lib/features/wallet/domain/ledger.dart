import 'money.dart';
import 'currency.dart';

/// The kind of account a ledger posting touches. Keeps money conserved across
/// the whole system: user balances, provider settlement floats, fee income and
/// external rails all have explicit accounts.
enum LedgerAccountType {
  userWallet,
  providerSettlement, // float held at a payment provider
  externalMobileMoney, // counterparty on M-Pesa/Airtel/etc.
  externalBank,
  feeIncome,
  taxPayable,
  cryptoVault,
  suspense, // in-flight / unreconciled
}

/// A ledger account. `id` is stable; `owner` is the user/merchant/provider it
/// belongs to (null for house accounts like fee income).
class LedgerAccount {
  const LedgerAccount({
    required this.id,
    required this.type,
    required this.currency,
    this.owner,
  });

  final String id;
  final LedgerAccountType type;
  final Currency currency;
  final String? owner;

  @override
  bool operator ==(Object other) => other is LedgerAccount && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

enum PostingDirection { debit, credit }

/// A single movement against one account. Amount is always positive; the
/// [direction] carries the sign. `signed` maps debit→+, credit→- so an entry
/// balances when its postings sum to zero.
class Posting {
  const Posting({
    required this.account,
    required this.direction,
    required this.amount,
  });

  final LedgerAccount account;
  final PostingDirection direction;
  final Money amount;

  factory Posting.debit(LedgerAccount account, Money amount) => Posting(
    account: account,
    direction: PostingDirection.debit,
    amount: amount.abs,
  );

  factory Posting.credit(LedgerAccount account, Money amount) => Posting(
    account: account,
    direction: PostingDirection.credit,
    amount: amount.abs,
  );

  Money get signed => direction == PostingDirection.debit ? amount : -amount;
}

/// Thrown when a [LedgerEntry] would violate the conservation invariant.
class UnbalancedLedgerEntry implements Exception {
  UnbalancedLedgerEntry(this.residuals);
  final Map<Currency, int> residuals;
  @override
  String toString() =>
      'UnbalancedLedgerEntry: postings do not net to zero per currency '
      '(residuals in minor units: $residuals)';
}

/// An immutable, append-only double-entry ledger record. Construction fails
/// fast if the postings do not balance to zero within each currency — the
/// single most important invariant in the whole payment system.
class LedgerEntry {
  LedgerEntry({
    required this.id,
    required this.transactionId,
    required this.createdAt,
    required this.description,
    required List<Posting> postings,
  }) : postings = List.unmodifiable(postings) {
    _assertBalanced();
  }

  final String id;
  final String transactionId;
  final DateTime createdAt;
  final String description;
  final List<Posting> postings;

  void _assertBalanced() {
    final residuals = <Currency, int>{};
    for (final p in postings) {
      residuals.update(
        p.amount.currency,
        (v) => v + p.signed.minorUnits,
        ifAbsent: () => p.signed.minorUnits,
      );
    }
    residuals.removeWhere((_, v) => v == 0);
    if (residuals.isNotEmpty) throw UnbalancedLedgerEntry(residuals);
  }

  /// Net effect of this entry on a given account, as signed [Money].
  Money effectOn(LedgerAccount account) {
    final matching = postings.where((p) => p.account == account);
    if (matching.isEmpty) return Money.zero(account.currency);
    return matching.map((p) => p.signed).reduce((a, b) => a + b);
  }
}

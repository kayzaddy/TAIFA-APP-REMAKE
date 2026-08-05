import 'money.dart';
import 'payment_method.dart';

enum TransactionType {
  sendMoney,
  receiveMoney,
  billPayment,
  topUp,
  withdrawal,
  merchantPayment,
  refund,
  rideFare,
}

extension TransactionTypeX on TransactionType {
  String get label => switch (this) {
    TransactionType.sendMoney => 'Send Money',
    TransactionType.receiveMoney => 'Received',
    TransactionType.billPayment => 'Bill',
    TransactionType.topUp => 'Top Up',
    TransactionType.withdrawal => 'Withdrawal',
    TransactionType.merchantPayment => 'Payment',
    TransactionType.refund => 'Refund',
    TransactionType.rideFare => 'Mobility',
  };
}

/// Lifecycle state. Terminal states are [succeeded], [failed] and [reversed].
enum TransactionStatus { pending, processing, succeeded, failed, reversed }

extension TransactionStatusX on TransactionStatus {
  bool get isTerminal =>
      this == TransactionStatus.succeeded ||
      this == TransactionStatus.failed ||
      this == TransactionStatus.reversed;
  bool get isSuccess => this == TransactionStatus.succeeded;
}

/// Whether money moved into (credit) or out of (debit) the user's wallet.
enum TransactionDirection { credit, debit }

/// A user-facing transaction record. It links to the immutable ledger entry
/// (`ledgerEntryId`) that actually moved the money, and carries the
/// `idempotencyKey` used to guarantee exactly-once processing.
class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.type,
    required this.status,
    required this.direction,
    required this.amount,
    required this.fee,
    required this.counterparty,
    required this.method,
    required this.createdAt,
    required this.idempotencyKey,
    this.note,
    this.providerRef,
    this.ledgerEntryId,
  });

  final String id;
  final TransactionType type;
  final TransactionStatus status;
  final TransactionDirection direction;
  final Money amount;
  final Money fee;
  final String counterparty;
  final PaymentMethod method;
  final DateTime createdAt;
  final String idempotencyKey;
  final String? note;
  final String? providerRef;
  final String? ledgerEntryId;

  bool get isCredit => direction == TransactionDirection.credit;

  /// Signed amount for display (positive for credits, negative for debits).
  Money get signedAmount => isCredit ? amount : -amount;

  WalletTransaction copyWith({
    TransactionStatus? status,
    String? providerRef,
    String? ledgerEntryId,
  }) {
    return WalletTransaction(
      id: id,
      type: type,
      status: status ?? this.status,
      direction: direction,
      amount: amount,
      fee: fee,
      counterparty: counterparty,
      method: method,
      createdAt: createdAt,
      idempotencyKey: idempotencyKey,
      note: note,
      providerRef: providerRef ?? this.providerRef,
      ledgerEntryId: ledgerEntryId ?? this.ledgerEntryId,
    );
  }
}

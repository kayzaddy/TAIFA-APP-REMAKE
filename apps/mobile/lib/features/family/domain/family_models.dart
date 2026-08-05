import '../../wallet/domain/money.dart';

class FamilyMember {
  const FamilyMember({
    required this.id,
    required this.name,
    required this.role,
    required this.phone,
    required this.allowance,
  });

  final String id;
  final String name;
  final String role;
  final String phone;
  final Money allowance;
}

enum FamilyTxKind { send, request }

enum FamilyTxStatus { drafting, pending, paid }

extension FamilyTxStatusX on FamilyTxStatus {
  String get label => switch (this) {
    FamilyTxStatus.drafting => 'Draft',
    FamilyTxStatus.pending => 'Pending',
    FamilyTxStatus.paid => 'Paid',
  };
}

class FamilyTransfer {
  const FamilyTransfer({
    required this.id,
    required this.member,
    required this.amount,
    required this.kind,
    required this.status,
    required this.createdAt,
    this.note,
    this.paymentRef,
  });

  final String id;
  final FamilyMember member;
  final Money amount;
  final FamilyTxKind kind;
  final FamilyTxStatus status;
  final DateTime createdAt;
  final String? note;
  final String? paymentRef;

  FamilyTransfer copyWith({FamilyTxStatus? status, String? paymentRef}) {
    return FamilyTransfer(
      id: id,
      member: member,
      amount: amount,
      kind: kind,
      status: status ?? this.status,
      createdAt: createdAt,
      note: note,
      paymentRef: paymentRef ?? this.paymentRef,
    );
  }
}

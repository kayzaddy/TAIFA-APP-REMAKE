import '../../wallet/domain/money.dart';

class School {
  const School({
    required this.id,
    required this.name,
    required this.level,
    required this.area,
    required this.termFee,
  });

  final String id;
  final String name;
  final String level;
  final String area;
  final Money termFee;
}

enum EduPaymentStatus { drafting, invoiced, paid, cancelled }

extension EduPaymentStatusX on EduPaymentStatus {
  String get label => switch (this) {
    EduPaymentStatus.drafting => 'Draft',
    EduPaymentStatus.invoiced => 'Invoiced',
    EduPaymentStatus.paid => 'Paid',
    EduPaymentStatus.cancelled => 'Cancelled',
  };
}

class EduPayment {
  const EduPayment({
    required this.id,
    required this.school,
    required this.studentName,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.invoiceNo,
    this.paymentRef,
  });

  final String id;
  final School school;
  final String studentName;
  final Money amount;
  final EduPaymentStatus status;
  final DateTime createdAt;
  final String? invoiceNo;
  final String? paymentRef;

  EduPayment copyWith({
    EduPaymentStatus? status,
    String? invoiceNo,
    String? paymentRef,
  }) {
    return EduPayment(
      id: id,
      school: school,
      studentName: studentName,
      amount: amount,
      status: status ?? this.status,
      createdAt: createdAt,
      invoiceNo: invoiceNo ?? this.invoiceNo,
      paymentRef: paymentRef ?? this.paymentRef,
    );
  }
}

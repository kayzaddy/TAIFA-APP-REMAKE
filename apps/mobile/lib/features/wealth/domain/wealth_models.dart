import '../../wallet/domain/money.dart';

class HarambeeCircle {
  const HarambeeCircle({
    required this.id,
    required this.name,
    required this.purpose,
    required this.target,
    required this.raised,
    required this.members,
  });

  final String id;
  final String name;
  final String purpose;
  final Money target;
  final Money raised;
  final int members;

  double get progress =>
      target.minorUnits == 0 ? 0 : raised.minorUnits / target.minorUnits;
}

enum ContributionStatus { drafting, confirmed, paid }

extension ContributionStatusX on ContributionStatus {
  String get label => switch (this) {
    ContributionStatus.drafting => 'Draft',
    ContributionStatus.confirmed => 'Confirmed',
    ContributionStatus.paid => 'Paid',
  };
}

class WealthContribution {
  const WealthContribution({
    required this.id,
    required this.circle,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.paymentRef,
  });

  final String id;
  final HarambeeCircle circle;
  final Money amount;
  final ContributionStatus status;
  final DateTime createdAt;
  final String? paymentRef;

  WealthContribution copyWith({
    ContributionStatus? status,
    String? paymentRef,
  }) {
    return WealthContribution(
      id: id,
      circle: circle,
      amount: amount,
      status: status ?? this.status,
      createdAt: createdAt,
      paymentRef: paymentRef ?? this.paymentRef,
    );
  }
}

import '../../wallet/domain/money.dart';

class InsurancePlan {
  const InsurancePlan({
    required this.id,
    required this.name,
    required this.provider,
    required this.category,
    required this.premium,
    required this.coverage,
    required this.highlights,
  });

  final String id;
  final String name;
  final String provider;
  final String category;
  final Money premium;
  final Money coverage;
  final List<String> highlights;
}

enum PolicyStatus { drafting, active }

extension PolicyStatusX on PolicyStatus {
  String get label => switch (this) {
    PolicyStatus.drafting => 'Draft',
    PolicyStatus.active => 'Active',
  };
}

class InsurancePolicy {
  const InsurancePolicy({
    required this.id,
    required this.plan,
    required this.status,
    required this.createdAt,
    this.policyRef,
  });

  final String id;
  final InsurancePlan plan;
  final PolicyStatus status;
  final DateTime createdAt;
  final String? policyRef;

  InsurancePolicy copyWith({PolicyStatus? status, String? policyRef}) {
    return InsurancePolicy(
      id: id,
      plan: plan,
      status: status ?? this.status,
      createdAt: createdAt,
      policyRef: policyRef ?? this.policyRef,
    );
  }
}

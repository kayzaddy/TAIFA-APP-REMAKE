import '../../features/insurance/data/insurance_catalog.dart';
import '../../features/insurance/domain/insurance_models.dart';
import '../../features/wallet/domain/currency.dart';
import '../../features/wallet/domain/money.dart';

/// Maps `/api/v1/commerce/insurance-policies` JSON ↔ domain [InsurancePolicy].
class InsurancePolicyDto {
  const InsurancePolicyDto._();

  static InsurancePolicy toDomain(
    Map<String, dynamic> json, {
    InsurancePlan? plan,
  }) {
    final currency = Currency.fromCode(json['currency'] as String? ?? 'TZS');
    final planId = json['plan_id'] as String? ?? '';
    final premium = Money(
      (json['premium_minor'] as num?)?.toInt() ?? 0,
      currency,
    );
    final coverage = Money(
      (json['coverage_minor'] as num?)?.toInt() ?? 0,
      currency,
    );
    final ref = (json['policy_ref'] as String?)?.trim();

    return InsurancePolicy(
      id: json['id'].toString(),
      plan:
          plan ??
          _resolvePlan(
            planId,
            json['plan_name'] as String? ?? 'Plan',
            json['provider'] as String? ?? '',
            json['category'] as String? ?? '',
            premium,
            coverage,
          ),
      status: statusFromApi(json['status'] as String? ?? 'active'),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      policyRef: (ref == null || ref.isEmpty) ? null : ref,
    );
  }

  static Map<String, dynamic> createBody(InsurancePolicy draft) => {
    'plan_id': draft.plan.id,
    'plan_name': draft.plan.name,
    'provider': draft.plan.provider,
    'category': draft.plan.category,
    'premium_minor': draft.plan.premium.minorUnits,
    'coverage_minor': draft.plan.coverage.minorUnits,
    'currency': draft.plan.premium.currency.code,
    if (draft.policyRef != null && draft.policyRef!.isNotEmpty)
      'policy_ref': draft.policyRef,
  };

  static PolicyStatus statusFromApi(String raw) =>
      raw == 'cancelled' ? PolicyStatus.drafting : PolicyStatus.active;

  static InsurancePlan _resolvePlan(
    String id,
    String name,
    String provider,
    String category,
    Money premium,
    Money coverage,
  ) {
    try {
      return InsuranceCatalog.plans().firstWhere((p) => p.id == id);
    } catch (_) {
      return InsurancePlan(
        id: id.isEmpty ? 'ins-unknown' : id,
        name: name,
        provider: provider,
        category: category,
        premium: premium,
        coverage: coverage,
        highlights: const [],
      );
    }
  }
}

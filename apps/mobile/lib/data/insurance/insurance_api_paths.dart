/// Path fragments for `/api/v1/commerce/insurance-policies*` (relative to API base).
abstract final class InsuranceApiPaths {
  static const insurancePolicies = 'commerce/insurance-policies';

  static String insurancePolicy(String id) => 'commerce/insurance-policies/$id';
}

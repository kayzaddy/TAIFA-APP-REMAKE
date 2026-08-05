/// Path fragments for `/api/v1/commerce/admin-cases*` (relative to API base).
abstract final class AdminApiPaths {
  static const adminCases = 'commerce/admin-cases';

  static String adminCase(String id) => 'commerce/admin-cases/$id';
}

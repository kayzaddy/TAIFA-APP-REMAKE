/// Path fragments for `/api/v1/commerce/wealth-contributions*` (relative to API base).
abstract final class WealthApiPaths {
  static const wealthContributions = 'commerce/wealth-contributions';

  static String wealthContribution(String id) =>
      'commerce/wealth-contributions/$id';
}

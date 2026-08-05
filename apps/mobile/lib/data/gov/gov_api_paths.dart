/// Path fragments for `/api/v1/commerce/gov-requests*` (relative to API base).
abstract final class GovApiPaths {
  static const govRequests = 'commerce/gov-requests';

  static String govRequest(String id) => 'commerce/gov-requests/$id';
  static String govRequestPay(String id) =>
      'commerce/gov-requests/$id/pay';
}

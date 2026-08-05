/// Path fragments for `/api/v1/commerce/merchant-orders*` (relative to API base).
abstract final class MerchantApiPaths {
  static const merchantOrders = 'commerce/merchant-orders';

  static String merchantOrder(String id) => 'commerce/merchant-orders/$id';
}

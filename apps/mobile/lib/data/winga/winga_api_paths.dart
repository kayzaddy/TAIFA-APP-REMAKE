/// Canonical REST path fragments for WINGA brokerage + legacy commerce APIs.
class WingaApiPaths {
  const WingaApiPaths._();

  // Legacy commerce checkout summaries (demo catalog orders)
  static const orders = 'commerce/winga-orders';
  static String order(String id) => 'commerce/winga-orders/$id';
  static String orderPay(String id) => 'commerce/winga-orders/$id/pay';

  static const serviceBookings = 'commerce/winga-service-bookings';
  static const shops = 'commerce/winga-shops';

  // Universal brokerage platform
  static const domains = 'winga/domains';
  static const categories = 'winga/categories';
  static const wingas = 'winga/wingas';
  static const providers = 'winga/providers';
  static const offerings = 'winga/offerings';
  static const leads = 'winga/leads';
  static const quotations = 'winga/quotations';
  static const deals = 'winga/deals';
  static String deal(String id) => 'winga/deals/$id';
  static String dealAdvance(String id) => 'winga/deals/$id/advance';
  static String dealPay(String id) => 'winga/deals/$id/pay';
  static String dealSettleCommission(String id) =>
      'winga/deals/$id/settle-commission';
  static const commissionRules = 'winga/commission-rules';
  static const commissionEvents = 'winga/commission-events';
  static const reviews = 'winga/reviews';
  static const favorites = 'winga/favorites';
  static const assist = 'winga/assist';
  static const analytics = 'winga/analytics/summary';
}

/// Canonical REST path fragments for the social-payments surface (payment
/// links, money requests, split bills, standing orders, contacts,
/// notifications, transaction search, spending analytics/cap). Mirrors
/// `PaymentApiPaths`.
class SocialApiPaths {
  const SocialApiPaths._();

  static const links = 'payments/links';
  static const requests = 'payments/requests';
  static const bills = 'payments/bills';
  static const recurring = 'payments/recurring';
  static const contacts = 'payments/contacts';
  static const notifications = 'payments/notifications';
  static const peopleLookup = 'payments/people/lookup';
  static const walletQr = 'payments/wallet/qr';
  static const analyticsSpending = 'payments/analytics/spending';
  static const spendingCap = 'payments/spending-cap';
  static const deviceProfile = 'auth/device/profile';
  static const deviceMerchant = 'auth/device/merchant';

  static String linkAction(String id, String action) => 'payments/links/$id/$action';
  static String payLinkInfo(String slug) => 'payments/pay/$slug';
  static String payLinkConfirm(String slug) => 'payments/pay/$slug/confirm';
  static String requestAction(String id, String action) => 'payments/requests/$id/$action';
  static String bill(String id) => 'payments/bills/$id';
  static String billCancel(String id) => 'payments/bills/$id/cancel';
  static String recurringAction(String id, String action) => 'payments/recurring/$id/$action';
  static String contact(String id) => 'payments/contacts/$id';
  static String contactAction(String id, String action) => 'payments/contacts/$id/$action';
  static String notificationRead(String id) => 'payments/notifications/$id/read';

  static String transactionsSearch(Map<String, String> query) {
    if (query.isEmpty) return 'payments/transactions';
    final qs = query.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&');
    return 'payments/transactions?$qs';
  }
}

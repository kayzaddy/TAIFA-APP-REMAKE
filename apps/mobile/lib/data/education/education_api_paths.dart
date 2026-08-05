/// Path fragments for `/api/v1/commerce/edu-payments*` (relative to API base).
abstract final class EducationApiPaths {
  static const eduPayments = 'commerce/edu-payments';

  static String eduPayment(String id) => 'commerce/edu-payments/$id';
  static String eduPaymentPay(String id) =>
      'commerce/edu-payments/$id/pay';
}

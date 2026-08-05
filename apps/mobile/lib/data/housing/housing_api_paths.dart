/// Path fragments for `/api/v1/commerce/housing-inquiries*` (relative to API base).
abstract final class HousingApiPaths {
  static const housingInquiries = 'commerce/housing-inquiries';

  static String housingInquiry(String id) => 'commerce/housing-inquiries/$id';
  static String housingInquiryPay(String id) =>
      'commerce/housing-inquiries/$id/pay';
}

/// Taifa Merchant BFF base path (see docs/taifa-merchant/06_API_SPECIFICATION.md).
class MerchantAppConfig {
  MerchantAppConfig._();

  static String baseUrl = const String.fromEnvironment(
    'TAIFA_MERCHANT_API_BASE',
    defaultValue: 'http://127.0.0.1:8000/api/v1/merchant-app',
  );
}

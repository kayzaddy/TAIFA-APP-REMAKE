import '../domain/map_models.dart';

abstract class MapRepository {
  Future<MapProfile> bootstrap({
    String code = 'map-mobile-retail',
    String legalName = 'MAP Mobile Retail Ltd',
  });

  Future<MapAnalytics> analytics();

  Future<({MapQr qr, MapIntent? intent})> issueQr({
    required int? amountMinor,
    String kind = 'dynamic',
    String description = '',
  });

  Future<List<MapQr>> qrLibrary();

  Future<MapPaymentLink> createLink({
    required int amountMinor,
    String purpose = 'general',
    String description = '',
  });

  Future<MapInvoice> createInvoice({
    required String invoiceNumber,
    required int amountMinor,
    String customerName = '',
  });

  Future<MapIntent> intent(String publicCode);

  Future<MapPayResult> payIntent(String publicCode, {String? idempotencyKey});

  Future<MapPayResult> payStatic({required int amountMinor, String? idempotencyKey});

  Future<({MapPaymentLink link, MapIntent intent, String merchantDisplay})> resolveLink(
    String pathToken,
  );
}

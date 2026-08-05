import '../domain/brokerage_models.dart';

/// Brokerage data boundary — all money settlement stays on the server.
abstract class BrokerageRepository {
  Future<List<BrokerageDomain>> domains();
  Future<List<WingaOffering>> offerings({String? domainCode, String? query, String? kind});
  Future<List<WingaBrokerProfile>> wingas({bool mine = false});
  Future<List<WingaProviderProfile>> providers({bool mine = false});
  Future<WingaBrokerProfile> registerWinga({required String displayName, String kind});
  Future<WingaProviderProfile> registerProvider({required String legalName, String tradingName});
  Future<WingaLead> createLead({
    required String wingaId,
    required String domainId,
    required String title,
    required String customerPrincipal,
    String notes,
  });
  Future<List<WingaLead>> leads({String? wingaId});
  Future<WingaDeal> openDeal({
    required String wingaId,
    required String providerId,
    required String domainId,
    required String customerPrincipal,
    required int amountMinor,
    String currency,
    String? offeringId,
    String? leadId,
    Map<String, dynamic>? booking,
  });
  Future<List<WingaDeal>> deals({String role = 'customer'});
  Future<WingaDeal> advanceDeal(String dealId, {required String stage, String note});
  Future<WingaDeal> payDeal(String dealId, {required String idempotencyKey});
  Future<List<WingaCommissionEvent>> settleCommission(String dealId);
  Future<List<WingaCommissionEvent>> commissionEvents({String? wingaId, String? dealId});
  Future<WingaAnalyticsSummary> analytics();
  Future<WingaAssistResult> assist({required String capability, Map<String, dynamic>? payload});
  Future<void> favoriteOffering(String offeringId);
  Future<List<String>> favoriteOfferingIds();
}

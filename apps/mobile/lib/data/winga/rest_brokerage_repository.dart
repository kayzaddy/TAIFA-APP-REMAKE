import '../../features/winga/application/brokerage_repository.dart';
import '../../features/winga/application/seed_brokerage_repository.dart';
import '../../features/winga/domain/brokerage_models.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import 'brokerage_dto.dart';
import 'winga_api_paths.dart';

/// Live brokerage client against `/api/v1/winga/*` with seed fallback on failure.
class RestBrokerageRepository implements BrokerageRepository {
  RestBrokerageRepository(this._client, {BrokerageRepository? fallback})
      : _fallback = fallback ?? SeedBrokerageRepository();

  final TaifaApiClient _client;
  final BrokerageRepository _fallback;

  Future<T> _guard<T>(Future<T> Function() live, Future<T> Function() soft) async {
    try {
      return await live();
    } on ApiException {
      return soft();
    } on StateError {
      rethrow;
    } catch (_) {
      return soft();
    }
  }

  List<Map<String, dynamic>> _asMaps(List<dynamic> raw) =>
      raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();

  @override
  Future<List<BrokerageDomain>> domains() => _guard(
        () async {
          final list = await _client.getJsonList(WingaApiPaths.domains);
          return _asMaps(list).map(BrokerageDto.domain).toList();
        },
        _fallback.domains,
      );

  @override
  Future<List<WingaOffering>> offerings({
    String? domainCode,
    String? query,
    String? kind,
  }) =>
      _guard(
        () async {
          final q = <String>[];
          if (domainCode != null) q.add('domain=$domainCode');
          if (query != null && query.isNotEmpty) q.add('q=${Uri.encodeQueryComponent(query)}');
          if (kind != null) q.add('kind=$kind');
          final path = q.isEmpty
              ? WingaApiPaths.offerings
              : '${WingaApiPaths.offerings}?${q.join('&')}';
          final list = await _client.getJsonList(path);
          return _asMaps(list).map(BrokerageDto.offering).toList();
        },
        () => _fallback.offerings(domainCode: domainCode, query: query, kind: kind),
      );

  @override
  Future<List<WingaBrokerProfile>> wingas({bool mine = false}) => _guard(
        () async {
          final path = mine ? '${WingaApiPaths.wingas}?mine=1' : WingaApiPaths.wingas;
          final list = await _client.getJsonList(path);
          return _asMaps(list).map(BrokerageDto.winga).toList();
        },
        () => _fallback.wingas(mine: mine),
      );

  @override
  Future<List<WingaProviderProfile>> providers({bool mine = false}) => _guard(
        () async {
          final path =
              mine ? '${WingaApiPaths.providers}?mine=1' : WingaApiPaths.providers;
          final list = await _client.getJsonList(path);
          return _asMaps(list).map(BrokerageDto.provider).toList();
        },
        () => _fallback.providers(mine: mine),
      );

  @override
  Future<WingaBrokerProfile> registerWinga({
    required String displayName,
    String kind = 'individual',
  }) =>
      _guard(
        () async {
          final json = await _client.postJson(
            WingaApiPaths.wingas,
            body: {'display_name': displayName, 'kind': kind},
          );
          return BrokerageDto.winga(json);
        },
        () => _fallback.registerWinga(displayName: displayName, kind: kind),
      );

  @override
  Future<WingaProviderProfile> registerProvider({
    required String legalName,
    String tradingName = '',
  }) =>
      _guard(
        () async {
          final json = await _client.postJson(
            WingaApiPaths.providers,
            body: {'legal_name': legalName, 'trading_name': tradingName},
          );
          return BrokerageDto.provider(json);
        },
        () => _fallback.registerProvider(legalName: legalName, tradingName: tradingName),
      );

  @override
  Future<WingaLead> createLead({
    required String wingaId,
    required String domainId,
    required String title,
    required String customerPrincipal,
    String notes = '',
  }) =>
      _guard(
        () async {
          final json = await _client.postJson(
            WingaApiPaths.leads,
            body: {
              'winga': wingaId,
              'domain': domainId,
              'title': title,
              'customer_principal': customerPrincipal,
              'notes': notes,
            },
          );
          return BrokerageDto.lead(json);
        },
        () => _fallback.createLead(
          wingaId: wingaId,
          domainId: domainId,
          title: title,
          customerPrincipal: customerPrincipal,
          notes: notes,
        ),
      );

  @override
  Future<List<WingaLead>> leads({String? wingaId}) => _guard(
        () async {
          final path = wingaId == null
              ? WingaApiPaths.leads
              : '${WingaApiPaths.leads}?winga=$wingaId';
          final list = await _client.getJsonList(path);
          return _asMaps(list).map(BrokerageDto.lead).toList();
        },
        () => _fallback.leads(wingaId: wingaId),
      );

  @override
  Future<WingaDeal> openDeal({
    required String wingaId,
    required String providerId,
    required String domainId,
    required String customerPrincipal,
    required int amountMinor,
    String currency = 'TZS',
    String? offeringId,
    String? leadId,
    Map<String, dynamic>? booking,
  }) =>
      _guard(
        () async {
          final body = <String, dynamic>{
            'winga': wingaId,
            'provider': providerId,
            'domain': domainId,
            'customer_principal': customerPrincipal,
            'amount_minor': amountMinor,
            'currency': currency,
            'offering': ?offeringId,
            'lead': ?leadId,
            'booking': ?booking,
          };
          final json = await _client.postJson(WingaApiPaths.deals, body: body);
          return BrokerageDto.deal(json);
        },
        () => _fallback.openDeal(
          wingaId: wingaId,
          providerId: providerId,
          domainId: domainId,
          customerPrincipal: customerPrincipal,
          amountMinor: amountMinor,
          currency: currency,
          offeringId: offeringId,
          leadId: leadId,
          booking: booking,
        ),
      );

  @override
  Future<List<WingaDeal>> deals({String role = 'customer'}) => _guard(
        () async {
          final list = await _client.getJsonList('${WingaApiPaths.deals}?role=$role');
          return _asMaps(list).map(BrokerageDto.deal).toList();
        },
        () => _fallback.deals(role: role),
      );

  @override
  Future<WingaDeal> advanceDeal(
    String dealId, {
    required String stage,
    String note = '',
  }) =>
      _guard(
        () async {
          final json = await _client.postJson(
            WingaApiPaths.dealAdvance(dealId),
            body: {'stage': stage, 'note': note},
          );
          return BrokerageDto.deal(json);
        },
        () => _fallback.advanceDeal(dealId, stage: stage, note: note),
      );

  @override
  Future<WingaDeal> payDeal(
    String dealId, {
    required String idempotencyKey,
  }) =>
      _guard(
        () async {
          final json = await _client.postJson(
            WingaApiPaths.dealPay(dealId),
            body: const {},
            idempotencyKey: idempotencyKey,
          );
          return BrokerageDto.deal(json);
        },
        () => _fallback.payDeal(dealId, idempotencyKey: idempotencyKey),
      );

  @override
  Future<List<WingaCommissionEvent>> settleCommission(String dealId) => _guard(
        () async {
          final json = await _client.postJson(
            WingaApiPaths.dealSettleCommission(dealId),
            body: const {},
          );
          final raw = json['commissions'];
          if (raw is! List) return const [];
          return _asMaps(raw).map(BrokerageDto.commission).toList();
        },
        () => _fallback.settleCommission(dealId),
      );

  @override
  Future<List<WingaCommissionEvent>> commissionEvents({
    String? wingaId,
    String? dealId,
  }) =>
      _guard(
        () async {
          final q = <String>[];
          if (wingaId != null) q.add('winga=$wingaId');
          if (dealId != null) q.add('deal=$dealId');
          final path = q.isEmpty
              ? WingaApiPaths.commissionEvents
              : '${WingaApiPaths.commissionEvents}?${q.join('&')}';
          final list = await _client.getJsonList(path);
          return _asMaps(list).map(BrokerageDto.commission).toList();
        },
        () => _fallback.commissionEvents(wingaId: wingaId, dealId: dealId),
      );

  @override
  Future<WingaAnalyticsSummary> analytics() => _guard(
        () async {
          final json = await _client.getJson(WingaApiPaths.analytics);
          return BrokerageDto.analytics(json);
        },
        _fallback.analytics,
      );

  @override
  Future<WingaAssistResult> assist({
    required String capability,
    Map<String, dynamic>? payload,
  }) async {
    try {
      final json = await _client.postJson(
        WingaApiPaths.assist,
        body: {'capability': capability, 'payload': payload ?? {}},
      );
      return WingaAssistResult(
        capability: '${json['capability'] ?? capability}',
        result: Map<String, dynamic>.from(json['result'] as Map? ?? json),
        paymentAuthorized: json['payment_authorized'] == true,
      );
    } on ApiStatusException catch (e) {
      if (e.statusCode == 400) rethrow;
      return _fallback.assist(capability: capability, payload: payload);
    } on ApiException {
      return _fallback.assist(capability: capability, payload: payload);
    }
  }

  @override
  Future<void> favoriteOffering(String offeringId) => _guard(
        () => _client.postJson(
          WingaApiPaths.favorites,
          body: {'offering': offeringId},
        ).then((_) {}),
        () => _fallback.favoriteOffering(offeringId),
      );

  @override
  Future<List<String>> favoriteOfferingIds() => _guard(
        () async {
          final list = await _client.getJsonList(WingaApiPaths.favorites);
          return _asMaps(list)
              .map((e) => '${e['offering'] ?? ''}')
              .where((id) => id.isNotEmpty)
              .toList();
        },
        _fallback.favoriteOfferingIds,
      );
}

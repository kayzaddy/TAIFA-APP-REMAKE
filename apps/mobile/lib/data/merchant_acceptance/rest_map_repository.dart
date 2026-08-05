import '../../features/merchant_acceptance/application/map_repository.dart';
import '../../features/merchant_acceptance/application/seed_map_repository.dart';
import '../../features/merchant_acceptance/domain/map_models.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';

/// Live MAP client against `/api/v1/map/*` with seed soft-fallback.
class RestMapRepository implements MapRepository {
  RestMapRepository(this._client, {MapRepository? fallback})
      : _fallback = fallback ?? SeedMapRepository();

  final TaifaApiClient _client;
  final MapRepository _fallback;
  String? _merchantId;

  Future<T> _guard<T>(Future<T> Function() live, Future<T> Function() soft) async {
    try {
      return await live();
    } on ApiException {
      return soft();
    } catch (_) {
      return soft();
    }
  }

  Future<String> _ensureMerchant() async {
    if (_merchantId != null) return _merchantId!;
    final json = await _client.postJson(
      '/api/v1/map/bootstrap',
      body: {
        'code': 'map-mobile-retail',
        'legal_name': 'MAP Mobile Retail Ltd',
      },
    );
    _merchantId = json['merchant_id']?.toString();
    if (_merchantId == null || _merchantId!.isEmpty) {
      throw StateError('MAP bootstrap missing merchant_id');
    }
    return _merchantId!;
  }

  MapIntent _intent(Map<String, dynamic> m) => MapIntent(
        publicCode: m['public_code']?.toString() ?? '',
        channel: m['channel']?.toString() ?? '',
        status: m['status']?.toString() ?? 'open',
        amountMinor: (m['amount_minor'] as num?)?.toInt() ?? 0,
        amountPaidMinor: (m['amount_paid_minor'] as num?)?.toInt() ?? 0,
        currency: m['currency']?.toString() ?? 'TZS',
        description: m['description']?.toString() ?? '',
        paymentRef: m['payment_ref']?.toString() ?? '',
        merchantCode: m['merchant_code']?.toString() ?? '',
      );

  MapQr _qr(Map<String, dynamic> m) => MapQr(
        publicCode: m['public_code']?.toString() ?? '',
        kind: m['kind']?.toString() ?? '',
        payload: m['payload']?.toString() ?? '',
        intentCode: m['intent_code']?.toString() ?? '',
      );

  MapReceipt _receipt(Map<String, dynamic> m) => MapReceipt(
        publicCode: m['public_code']?.toString() ?? '',
        paymentRef: m['payment_ref']?.toString() ?? '',
        amountMinor: (m['amount_minor'] as num?)?.toInt() ?? 0,
        merchantDisplay: m['merchant_display']?.toString() ?? '',
        currency: m['currency']?.toString() ?? 'TZS',
        channel: m['channel']?.toString() ?? '',
        verificationQr: m['verification_qr']?.toString() ?? '',
      );

  @override
  Future<MapProfile> bootstrap({
    String code = 'map-mobile-retail',
    String legalName = 'MAP Mobile Retail Ltd',
  }) =>
      _guard(() async {
        final json = await _client.postJson(
          '/api/v1/map/bootstrap',
          body: {'code': code, 'legal_name': legalName},
        );
        _merchantId = json['merchant_id']?.toString();
        final p = json['profile'] as Map<String, dynamic>? ?? {};
        return MapProfile(
          merchantId: _merchantId ?? '',
          merchantCode: json['merchant_code']?.toString() ?? code,
          displayName: p['display_name']?.toString() ?? legalName,
          qrIdentity: p['qr_identity']?.toString() ?? '',
          acceptedMethods: (p['accepted_methods'] as List? ?? [])
              .map((e) => e.toString())
              .toList(),
          defaultCurrency: p['default_currency']?.toString() ?? 'TZS',
        );
      }, () => _fallback.bootstrap(code: code, legalName: legalName));

  @override
  Future<MapAnalytics> analytics() => _guard(() async {
        final mid = await _ensureMerchant();
        final json = await _client.getJson('/api/v1/map/merchants/$mid/analytics');
        final mix = <String, int>{};
        final raw = json['channel_mix'];
        if (raw is Map) {
          raw.forEach((k, v) => mix[k.toString()] = (v as num?)?.toInt() ?? 0);
        }
        return MapAnalytics(
          intentsTotal: (json['intents_total'] as num?)?.toInt() ?? 0,
          intentsPaid: (json['intents_paid'] as num?)?.toInt() ?? 0,
          gmvMinor: (json['gmv_minor'] as num?)?.toInt() ?? 0,
          qrCount: (json['qr_count'] as num?)?.toInt() ?? 0,
          linksCount: (json['links_count'] as num?)?.toInt() ?? 0,
          invoicesOpen: (json['invoices_open'] as num?)?.toInt() ?? 0,
          terminals: (json['terminals'] as num?)?.toInt() ?? 0,
          channelMix: mix,
        );
      }, _fallback.analytics);

  @override
  Future<({MapQr qr, MapIntent? intent})> issueQr({
    required int? amountMinor,
    String kind = 'dynamic',
    String description = '',
  }) =>
      _guard(() async {
        final mid = await _ensureMerchant();
        final body = <String, dynamic>{
          'kind': kind,
          'description': description,
        };
        if (amountMinor != null) body['amount_minor'] = amountMinor;
        final json = await _client.postJson(
          '/api/v1/map/merchants/$mid/qr',
          body: body,
        );
        final intentJson = json['intent'] as Map<String, dynamic>?;
        return (
          qr: _qr(json['qr'] as Map<String, dynamic>? ?? {}),
          intent: intentJson == null ? null : _intent(intentJson),
        );
      }, () => _fallback.issueQr(amountMinor: amountMinor, kind: kind, description: description));

  @override
  Future<List<MapQr>> qrLibrary() => _guard(() async {
        final mid = await _ensureMerchant();
        final list = await _client.getJsonList('/api/v1/map/merchants/$mid/qr/library');
        return list.whereType<Map>().map((e) => _qr(Map<String, dynamic>.from(e))).toList();
      }, _fallback.qrLibrary);

  @override
  Future<MapPaymentLink> createLink({
    required int amountMinor,
    String purpose = 'general',
    String description = '',
  }) =>
      _guard(() async {
        final mid = await _ensureMerchant();
        final json = await _client.postJson(
          '/api/v1/map/merchants/$mid/links',
          body: {
            'amount_minor': amountMinor,
            'purpose': purpose,
            'description': description,
          },
        );
        return MapPaymentLink(
          publicCode: json['public_code']?.toString() ?? '',
          pathToken: json['path_token']?.toString() ?? '',
          payPath: json['pay_path']?.toString() ?? '',
          intentCode: json['intent_code']?.toString() ?? '',
          purpose: json['purpose']?.toString() ?? purpose,
        );
      }, () => _fallback.createLink(amountMinor: amountMinor, purpose: purpose, description: description));

  @override
  Future<MapInvoice> createInvoice({
    required String invoiceNumber,
    required int amountMinor,
    String customerName = '',
  }) =>
      _guard(() async {
        final mid = await _ensureMerchant();
        final json = await _client.postJson(
          '/api/v1/map/merchants/$mid/invoices',
          body: {
            'invoice_number': invoiceNumber,
            'amount_minor': amountMinor,
            'customer_name': customerName,
          },
        );
        final inv = json['invoice'] as Map<String, dynamic>? ?? {};
        return MapInvoice(
          publicCode: inv['public_code']?.toString() ?? '',
          invoiceNumber: inv['invoice_number']?.toString() ?? invoiceNumber,
          amountMinor: (inv['amount_minor'] as num?)?.toInt() ?? amountMinor,
          amountPaidMinor: (inv['amount_paid_minor'] as num?)?.toInt() ?? 0,
          status: inv['status']?.toString() ?? 'open',
          currency: inv['currency']?.toString() ?? 'TZS',
        );
      }, () => _fallback.createInvoice(invoiceNumber: invoiceNumber, amountMinor: amountMinor, customerName: customerName));

  @override
  Future<MapIntent> intent(String publicCode) => _guard(() async {
        final json = await _client.getJson('/api/v1/map/intents/$publicCode');
        return _intent(json);
      }, () => _fallback.intent(publicCode));

  @override
  Future<MapPayResult> payIntent(String publicCode, {String? idempotencyKey}) =>
      _guard(() async {
        final key = idempotencyKey ?? 'map-${DateTime.now().millisecondsSinceEpoch}';
        final json = await _client.postJson(
          '/api/v1/map/intents/$publicCode/pay',
          body: {},
          idempotencyKey: key,
        );
        return MapPayResult(
          intent: _intent(json['intent'] as Map<String, dynamic>? ?? {}),
          receipt: _receipt(json['receipt'] as Map<String, dynamic>? ?? {}),
        );
      }, () => _fallback.payIntent(publicCode, idempotencyKey: idempotencyKey));

  @override
  Future<MapPayResult> payStatic({required int amountMinor, String? idempotencyKey}) =>
      _guard(() async {
        final mid = await _ensureMerchant();
        final key = idempotencyKey ?? 'map-static-${DateTime.now().millisecondsSinceEpoch}';
        final json = await _client.postJson(
          '/api/v1/map/merchants/$mid/qr/static/pay',
          body: {'amount_minor': amountMinor},
          idempotencyKey: key,
        );
        return MapPayResult(
          intent: _intent(json['intent'] as Map<String, dynamic>? ?? {}),
          receipt: _receipt(json['receipt'] as Map<String, dynamic>? ?? {}),
        );
      }, () => _fallback.payStatic(amountMinor: amountMinor, idempotencyKey: idempotencyKey));

  @override
  Future<({MapPaymentLink link, MapIntent intent, String merchantDisplay})> resolveLink(
    String pathToken,
  ) =>
      _guard(() async {
        final json = await _client.getJson('/api/v1/map/links/$pathToken');
        final linkJson = json['link'] as Map<String, dynamic>? ?? {};
        return (
          link: MapPaymentLink(
            publicCode: linkJson['public_code']?.toString() ?? '',
            pathToken: linkJson['path_token']?.toString() ?? pathToken,
            payPath: linkJson['pay_path']?.toString() ?? '',
            intentCode: linkJson['intent_code']?.toString() ?? '',
            purpose: linkJson['purpose']?.toString() ?? 'general',
          ),
          intent: _intent(json['intent'] as Map<String, dynamic>? ?? {}),
          merchantDisplay: json['merchant_display']?.toString() ?? '',
        );
      }, () => _fallback.resolveLink(pathToken));
}

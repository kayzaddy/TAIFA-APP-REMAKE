import '../domain/map_models.dart';
import 'map_repository.dart';

/// Offline soft-fallback — no ledger; local demo only.
class SeedMapRepository implements MapRepository {
  MapProfile? _profile;
  final _intents = <String, MapIntent>{};
  final _links = <String, MapPaymentLink>{};
  var _seq = 0;

  String _code(String p) => '${p}_${++_seq}';

  @override
  Future<MapProfile> bootstrap({
    String code = 'map-mobile-retail',
    String legalName = 'MAP Mobile Retail Ltd',
  }) async {
    _profile ??= MapProfile(
      merchantId: 'seed-merchant',
      merchantCode: code,
      displayName: legalName,
      qrIdentity: 'mqr_seed',
      acceptedMethods: const [
        'static_qr',
        'dynamic_qr',
        'payment_link',
        'invoice',
        'remote_checkout',
        'pos',
        'wallet',
      ],
    );
    return _profile!;
  }

  @override
  Future<MapAnalytics> analytics() async {
    await bootstrap();
    final paid = _intents.values.where((e) => e.isPaid).length;
    final gmv = _intents.values
        .where((e) => e.isPaid)
        .fold<int>(0, (a, b) => a + b.amountMinor);
    return MapAnalytics(
      intentsTotal: _intents.length,
      intentsPaid: paid,
      gmvMinor: gmv,
      qrCount: _intents.length,
      linksCount: _links.length,
    );
  }

  @override
  Future<({MapQr qr, MapIntent? intent})> issueQr({
    required int? amountMinor,
    String kind = 'dynamic',
    String description = '',
  }) async {
    final p = await bootstrap();
    if (kind == 'static' || amountMinor == null) {
      return (
        qr: MapQr(
          publicCode: p.qrIdentity,
          kind: 'static',
          payload: 'taifa://pay/${p.merchantCode}?q=${p.qrIdentity}',
        ),
        intent: null,
      );
    }
    final code = _code('pi');
    final intent = MapIntent(
      publicCode: code,
      channel: 'dynamic_qr',
      status: 'open',
      amountMinor: amountMinor,
      description: description,
      merchantCode: p.merchantCode,
    );
    _intents[code] = intent;
    return (
      qr: MapQr(
        publicCode: code,
        kind: kind,
        payload: 'taifa://pay/${p.merchantCode}?q=$code&a=$amountMinor',
        intentCode: code,
      ),
      intent: intent,
    );
  }

  @override
  Future<List<MapQr>> qrLibrary() async {
    final issued = await issueQr(amountMinor: null, kind: 'static');
    return [issued.qr];
  }

  @override
  Future<MapPaymentLink> createLink({
    required int amountMinor,
    String purpose = 'general',
    String description = '',
  }) async {
    final p = await bootstrap();
    final code = _code('pi');
    final token = _code('tok');
    _intents[code] = MapIntent(
      publicCode: code,
      channel: 'payment_link',
      status: 'open',
      amountMinor: amountMinor,
      description: description,
      merchantCode: p.merchantCode,
    );
    final link = MapPaymentLink(
      publicCode: _code('pl'),
      pathToken: token,
      payPath: '/map/pay/$token',
      intentCode: code,
      purpose: purpose,
    );
    _links[token] = link;
    return link;
  }

  @override
  Future<MapInvoice> createInvoice({
    required String invoiceNumber,
    required int amountMinor,
    String customerName = '',
  }) async {
    await bootstrap();
    final code = _code('pi');
    _intents[code] = MapIntent(
      publicCode: code,
      channel: 'invoice',
      status: 'open',
      amountMinor: amountMinor,
      description: 'Invoice $invoiceNumber',
    );
    return MapInvoice(
      publicCode: _code('inv'),
      invoiceNumber: invoiceNumber,
      amountMinor: amountMinor,
    );
  }

  @override
  Future<MapIntent> intent(String publicCode) async {
    final i = _intents[publicCode];
    if (i == null) throw StateError('intent not found');
    return i;
  }

  @override
  Future<MapPayResult> payIntent(String publicCode, {String? idempotencyKey}) async {
    final i = await intent(publicCode);
    if (i.isPaid) {
      return MapPayResult(
        intent: i,
        receipt: MapReceipt(
          publicCode: 'rcpt_seed',
          paymentRef: i.paymentRef,
          amountMinor: i.amountMinor,
          merchantDisplay: (await bootstrap()).displayName,
        ),
      );
    }
    final paid = MapIntent(
      publicCode: i.publicCode,
      channel: i.channel,
      status: 'paid',
      amountMinor: i.amountMinor,
      amountPaidMinor: i.amountMinor,
      currency: i.currency,
      description: i.description,
      paymentRef: 'seed-txn-${idempotencyKey ?? publicCode}',
      merchantCode: i.merchantCode,
    );
    _intents[publicCode] = paid;
    return MapPayResult(
      intent: paid,
      receipt: MapReceipt(
        publicCode: _code('rcpt'),
        paymentRef: paid.paymentRef,
        amountMinor: paid.amountMinor,
        merchantDisplay: (await bootstrap()).displayName,
        channel: paid.channel,
        verificationQr: 'taifa://receipt/${paid.paymentRef}',
      ),
    );
  }

  @override
  Future<MapPayResult> payStatic({required int amountMinor, String? idempotencyKey}) async {
    final issued = await issueQr(amountMinor: amountMinor, kind: 'dynamic');
    return payIntent(issued.intent!.publicCode, idempotencyKey: idempotencyKey);
  }

  @override
  Future<({MapPaymentLink link, MapIntent intent, String merchantDisplay})> resolveLink(
    String pathToken,
  ) async {
    final link = _links[pathToken];
    if (link == null) throw StateError('link not found');
    final i = await intent(link.intentCode);
    return (link: link, intent: i, merchantDisplay: (await bootstrap()).displayName);
  }
}

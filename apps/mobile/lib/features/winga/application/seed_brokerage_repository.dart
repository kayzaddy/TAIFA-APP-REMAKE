import 'brokerage_repository.dart';
import '../domain/brokerage_models.dart';

/// Offline-first brokerage demo data for low-bandwidth / no-network use.
class SeedBrokerageRepository implements BrokerageRepository {
  final _domains = <BrokerageDomain>[
    const BrokerageDomain(
      id: 'dom-hotels',
      code: 'hotels',
      name: 'Hotels',
      description: 'Hotel rooms & stays',
      defaultCommissionBps: 1000,
    ),
    const BrokerageDomain(
      id: 'dom-insurance',
      code: 'insurance',
      name: 'Insurance',
      description: 'Insurance referrals',
      defaultCommissionBps: 1500,
    ),
    const BrokerageDomain(
      id: 'dom-property',
      code: 'property',
      name: 'Property',
      description: 'Property listings',
      defaultCommissionBps: 1500,
    ),
    const BrokerageDomain(
      id: 'dom-professional',
      code: 'professional',
      name: 'Professional',
      description: 'Professional services',
      defaultCommissionBps: 1000,
    ),
    const BrokerageDomain(
      id: 'dom-retail',
      code: 'retail',
      name: 'Retail',
      description: 'Retail products',
      defaultCommissionBps: 500,
    ),
    const BrokerageDomain(
      id: 'dom-logistics',
      code: 'logistics',
      name: 'Logistics',
      description: 'Freight & courier',
      defaultCommissionBps: 600,
    ),
  ];

  final _wingas = <WingaBrokerProfile>[
    const WingaBrokerProfile(
      id: 'wg-asha',
      principal: 'winga:asha',
      displayName: 'Asha Brokerage',
      verificationStatus: 'verified',
      reputationScoreE4: 4600,
      bio: 'Hospitality & insurance specialist · Dar es Salaam',
    ),
    const WingaBrokerProfile(
      id: 'wg-juma',
      principal: 'winga:juma',
      displayName: 'Juma Connect',
      verificationStatus: 'verified',
      reputationScoreE4: 4200,
      bio: 'Property & logistics · Arusha',
    ),
  ];

  final _providers = <WingaProviderProfile>[
    const WingaProviderProfile(
      id: 'pv-hyatt',
      principal: 'provider:hyatt',
      legalName: 'Harbour View Hotels Ltd',
      tradingName: 'Harbour View',
      verificationStatus: 'verified',
      reputationScoreE4: 4800,
      locations: ['Dar es Salaam'],
    ),
    const WingaProviderProfile(
      id: 'pv-insure',
      principal: 'provider:insure',
      legalName: 'Umoja Insurance Co',
      tradingName: 'Umoja Cover',
      verificationStatus: 'verified',
      reputationScoreE4: 4500,
      locations: ['National'],
    ),
  ];

  late final _offerings = <WingaOffering>[
    WingaOffering(
      id: 'of-room',
      providerId: _providers[0].id,
      domainId: _domains[0].id,
      title: 'King Harbour View · 2 nights',
      kind: 'booking',
      priceMinor: 70400000,
      description: 'Sea-view king room with breakfast',
      attributes: {'city': 'Dar', 'guests': 2},
    ),
    WingaOffering(
      id: 'of-motor',
      providerId: _providers[1].id,
      domainId: _domains[1].id,
      title: 'Comprehensive motor cover',
      kind: 'referral',
      priceMinor: 45000000,
      description: 'Annual comprehensive policy',
      attributes: {'region': 'TZ'},
    ),
    WingaOffering(
      id: 'of-office',
      providerId: _providers[0].id,
      domainId: _domains[2].id,
      title: 'Masaki office suite · monthly',
      kind: 'rental',
      priceMinor: 250000000,
      description: 'Furnished suite near ICC',
    ),
  ];

  final _leads = <WingaLead>[];
  final _deals = <WingaDeal>[];
  final _commissions = <WingaCommissionEvent>[];
  final _favorites = <String>{};
  var _seq = 0;

  String _id(String prefix) => '$prefix-${++_seq}';

  @override
  Future<List<BrokerageDomain>> domains() async => List.unmodifiable(_domains);

  @override
  Future<List<WingaOffering>> offerings({
    String? domainCode,
    String? query,
    String? kind,
  }) async {
    var list = List<WingaOffering>.from(_offerings);
    if (domainCode != null) {
      final dom = _domains.where((d) => d.code == domainCode).firstOrNull;
      if (dom != null) list = list.where((o) => o.domainId == dom.id).toList();
    }
    if (kind != null) list = list.where((o) => o.kind == kind).toList();
    if (query != null && query.trim().isNotEmpty) {
      final q = query.toLowerCase();
      list = list
          .where(
            (o) =>
                o.title.toLowerCase().contains(q) ||
                o.description.toLowerCase().contains(q),
          )
          .toList();
    }
    return list;
  }

  @override
  Future<List<WingaBrokerProfile>> wingas({bool mine = false}) async =>
      List.unmodifiable(_wingas);

  @override
  Future<List<WingaProviderProfile>> providers({bool mine = false}) async =>
      List.unmodifiable(_providers);

  @override
  Future<WingaBrokerProfile> registerWinga({
    required String displayName,
    String kind = 'individual',
  }) async {
    final p = WingaBrokerProfile(
      id: _id('wg'),
      principal: 'winga:local',
      displayName: displayName,
      kind: kind,
      verificationStatus: 'verified',
    );
    _wingas.add(p);
    return p;
  }

  @override
  Future<WingaProviderProfile> registerProvider({
    required String legalName,
    String tradingName = '',
  }) async {
    final p = WingaProviderProfile(
      id: _id('pv'),
      principal: 'provider:local',
      legalName: legalName,
      tradingName: tradingName,
      verificationStatus: 'verified',
    );
    _providers.add(p);
    return p;
  }

  @override
  Future<WingaLead> createLead({
    required String wingaId,
    required String domainId,
    required String title,
    required String customerPrincipal,
    String notes = '',
  }) async {
    final lead = WingaLead(
      id: _id('ld'),
      wingaId: wingaId,
      customerPrincipal: customerPrincipal,
      domainId: domainId,
      title: title,
      notes: notes,
      pipelineStage: 'new',
    );
    _leads.insert(0, lead);
    return lead;
  }

  @override
  Future<List<WingaLead>> leads({String? wingaId}) async {
    if (wingaId == null) return List.unmodifiable(_leads);
    return _leads.where((l) => l.wingaId == wingaId).toList();
  }

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
  }) async {
    final deal = WingaDeal(
      id: _id('dl'),
      reference: 'WG-SEED-$_seq',
      domainId: domainId,
      wingaId: wingaId,
      providerId: providerId,
      customerPrincipal: customerPrincipal,
      stage: DealStageUi.accepted,
      amountMinor: amountMinor,
      currency: currency,
      offeringId: offeringId,
      booking: booking ?? const {},
    );
    _deals.insert(0, deal);
    return deal;
  }

  @override
  Future<List<WingaDeal>> deals({String role = 'customer'}) async =>
      List.unmodifiable(_deals);

  @override
  Future<WingaDeal> advanceDeal(
    String dealId, {
    required String stage,
    String note = '',
  }) async {
    final i = _deals.indexWhere((d) => d.id == dealId);
    if (i < 0) throw StateError('deal not found');
    final next = dealStageFromApi(stage);
    final updated = WingaDeal(
      id: _deals[i].id,
      reference: _deals[i].reference,
      domainId: _deals[i].domainId,
      wingaId: _deals[i].wingaId,
      providerId: _deals[i].providerId,
      customerPrincipal: _deals[i].customerPrincipal,
      stage: next,
      amountMinor: _deals[i].amountMinor,
      currency: _deals[i].currency,
      paymentRef: _deals[i].paymentRef,
      offeringId: _deals[i].offeringId,
      booking: _deals[i].booking,
    );
    _deals[i] = updated;
    return updated;
  }

  @override
  Future<WingaDeal> payDeal(
    String dealId, {
    required String idempotencyKey,
  }) async {
    final i = _deals.indexWhere((d) => d.id == dealId);
    if (i < 0) throw StateError('deal not found');
    final paid = WingaDeal(
      id: _deals[i].id,
      reference: _deals[i].reference,
      domainId: _deals[i].domainId,
      wingaId: _deals[i].wingaId,
      providerId: _deals[i].providerId,
      customerPrincipal: _deals[i].customerPrincipal,
      stage: DealStageUi.payment,
      amountMinor: _deals[i].amountMinor,
      currency: _deals[i].currency,
      paymentRef: 'seed-pay-$idempotencyKey',
      offeringId: _deals[i].offeringId,
      booking: _deals[i].booking,
    );
    _deals[i] = paid;
    final bps = 1000;
    _commissions.insert(
      0,
      WingaCommissionEvent(
        id: _id('cm'),
        dealId: paid.id,
        wingaId: paid.wingaId,
        commissionMinor: paid.amountMinor * bps ~/ 10000,
        status: 'calculated',
        bpsApplied: bps,
      ),
    );
    return paid;
  }

  @override
  Future<List<WingaCommissionEvent>> settleCommission(String dealId) async {
    final out = <WingaCommissionEvent>[];
    for (var i = 0; i < _commissions.length; i++) {
      if (_commissions[i].dealId != dealId) continue;
      final settled = WingaCommissionEvent(
        id: _commissions[i].id,
        dealId: _commissions[i].dealId,
        wingaId: _commissions[i].wingaId,
        commissionMinor: _commissions[i].commissionMinor,
        status: 'settled',
        currency: _commissions[i].currency,
        bpsApplied: _commissions[i].bpsApplied,
        level: _commissions[i].level,
      );
      _commissions[i] = settled;
      out.add(settled);
    }
    return out;
  }

  @override
  Future<List<WingaCommissionEvent>> commissionEvents({
    String? wingaId,
    String? dealId,
  }) async {
    var list = List<WingaCommissionEvent>.from(_commissions);
    if (wingaId != null) list = list.where((c) => c.wingaId == wingaId).toList();
    if (dealId != null) list = list.where((c) => c.dealId == dealId).toList();
    return list;
  }

  @override
  Future<WingaAnalyticsSummary> analytics() async => WingaAnalyticsSummary(
        dealsTotal: _deals.length,
        leadsTotal: _leads.length,
        offeringsTotal: _offerings.length,
        wingasVerified: _wingas.where((w) => w.isVerified).length,
        providersVerified: _providers.where((p) => p.isVerified).length,
        commissionSettledMinor: _commissions
            .where((c) => c.isSettled)
            .fold<int>(0, (a, c) => a + c.commissionMinor),
      );

  @override
  Future<WingaAssistResult> assist({
    required String capability,
    Map<String, dynamic>? payload,
  }) async {
    const blocked = {
      'authorize_payment',
      'capture_payment',
      'settle_commission',
      'transfer_funds',
      'approve_payout',
    };
    if (blocked.contains(capability)) {
      throw StateError('AI must never authorize payments or settlements');
    }
    return WingaAssistResult(
      capability: capability,
      result: {
        'suggestions': [
          'Match Harbour View for hospitality leads',
          'Follow up insurance quotes within 24h',
          'Promote Masaki suites this weekend',
        ],
        'note': 'seed assist',
      },
    );
  }

  @override
  Future<void> favoriteOffering(String offeringId) async {
    _favorites.add(offeringId);
  }

  @override
  Future<List<String>> favoriteOfferingIds() async =>
      List.unmodifiable(_favorites.toList());
}

import '../../features/winga/domain/brokerage_models.dart';

class BrokerageDto {
  const BrokerageDto._();

  static BrokerageDomain domain(Map<String, dynamic> j) => BrokerageDomain(
        id: '${j['id']}',
        code: '${j['code'] ?? ''}',
        name: '${j['name'] ?? ''}',
        description: '${j['description'] ?? ''}',
        defaultCommissionBps: (j['default_commission_bps'] as num?)?.toInt() ?? 500,
      );

  static WingaBrokerProfile winga(Map<String, dynamic> j) => WingaBrokerProfile(
        id: '${j['id']}',
        principal: '${j['principal'] ?? ''}',
        displayName: '${j['display_name'] ?? ''}',
        kind: '${j['kind'] ?? 'individual'}',
        verificationStatus: '${j['verification_status'] ?? 'unverified'}',
        reputationScoreE4: (j['reputation_score_e4'] as num?)?.toInt() ?? 5000,
        bio: '${j['bio'] ?? ''}',
      );

  static WingaProviderProfile provider(Map<String, dynamic> j) => WingaProviderProfile(
        id: '${j['id']}',
        principal: '${j['principal'] ?? ''}',
        legalName: '${j['legal_name'] ?? ''}',
        tradingName: '${j['trading_name'] ?? ''}',
        verificationStatus: '${j['verification_status'] ?? 'unverified'}',
        reputationScoreE4: (j['reputation_score_e4'] as num?)?.toInt() ?? 5000,
        locations: (j['locations'] as List?)?.map((e) => '$e').toList() ?? const [],
      );

  static WingaOffering offering(Map<String, dynamic> j) => WingaOffering(
        id: '${j['id']}',
        providerId: '${j['provider'] ?? ''}',
        domainId: '${j['domain'] ?? ''}',
        title: '${j['title'] ?? ''}',
        kind: '${j['kind'] ?? 'service'}',
        priceMinor: (j['price_minor'] as num?)?.toInt() ?? 0,
        currency: '${j['currency'] ?? 'TZS'}',
        description: '${j['description'] ?? ''}',
        attributes: Map<String, dynamic>.from(j['attributes'] as Map? ?? const {}),
      );

  static WingaLead lead(Map<String, dynamic> j) => WingaLead(
        id: '${j['id']}',
        wingaId: '${j['winga'] ?? ''}',
        customerPrincipal: '${j['customer_principal'] ?? ''}',
        domainId: '${j['domain'] ?? ''}',
        title: '${j['title'] ?? ''}',
        pipelineStage: '${j['pipeline_stage'] ?? 'new'}',
        notes: '${j['notes'] ?? ''}',
        priorityE4: (j['priority_e4'] as num?)?.toInt() ?? 5000,
      );

  static WingaDeal deal(Map<String, dynamic> j) => WingaDeal(
        id: '${j['id']}',
        reference: '${j['reference'] ?? ''}',
        domainId: '${j['domain'] ?? ''}',
        wingaId: '${j['winga'] ?? ''}',
        providerId: '${j['provider'] ?? ''}',
        customerPrincipal: '${j['customer_principal'] ?? ''}',
        stage: dealStageFromApi('${j['stage'] ?? 'lead'}'),
        amountMinor: (j['amount_minor'] as num?)?.toInt() ?? 0,
        currency: '${j['currency'] ?? 'TZS'}',
        paymentRef: '${j['payment_ref'] ?? ''}',
        offeringId: j['offering']?.toString(),
        booking: Map<String, dynamic>.from(j['booking'] as Map? ?? const {}),
      );

  static WingaCommissionEvent commission(Map<String, dynamic> j) =>
      WingaCommissionEvent(
        id: '${j['id']}',
        dealId: '${j['deal'] ?? ''}',
        wingaId: '${j['winga'] ?? ''}',
        commissionMinor: (j['commission_minor'] as num?)?.toInt() ?? 0,
        status: '${j['status'] ?? 'calculated'}',
        currency: '${j['currency'] ?? 'TZS'}',
        bpsApplied: (j['bps_applied'] as num?)?.toInt() ?? 0,
        level: (j['level'] as num?)?.toInt() ?? 1,
      );

  static WingaAnalyticsSummary analytics(Map<String, dynamic> j) =>
      WingaAnalyticsSummary(
        dealsTotal: (j['deals_total'] as num?)?.toInt() ?? 0,
        leadsTotal: (j['leads_total'] as num?)?.toInt() ?? 0,
        offeringsTotal: (j['offerings_total'] as num?)?.toInt() ?? 0,
        wingasVerified: (j['wingas_verified'] as num?)?.toInt() ?? 0,
        providersVerified: (j['providers_verified'] as num?)?.toInt() ?? 0,
        commissionSettledMinor:
            (j['commission_settled_minor'] as num?)?.toInt() ?? 0,
      );
}

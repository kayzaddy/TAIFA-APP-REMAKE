/// Brokerage domain models — maps to `/api/v1/winga/*` without owning money logic.
library;

enum WingaActorRole { customer, broker, provider }

enum DealStageUi {
  lead,
  inquiry,
  quotation,
  negotiation,
  offer,
  accepted,
  payment,
  fulfillment,
  settlement,
  commissionPayout,
  review,
  closed,
  cancelled,
  disputed,
}

DealStageUi dealStageFromApi(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'lead':
      return DealStageUi.lead;
    case 'inquiry':
      return DealStageUi.inquiry;
    case 'quotation':
      return DealStageUi.quotation;
    case 'negotiation':
      return DealStageUi.negotiation;
    case 'offer':
      return DealStageUi.offer;
    case 'accepted':
      return DealStageUi.accepted;
    case 'payment':
      return DealStageUi.payment;
    case 'fulfillment':
      return DealStageUi.fulfillment;
    case 'settlement':
      return DealStageUi.settlement;
    case 'commission_payout':
      return DealStageUi.commissionPayout;
    case 'review':
      return DealStageUi.review;
    case 'closed':
      return DealStageUi.closed;
    case 'cancelled':
      return DealStageUi.cancelled;
    case 'disputed':
      return DealStageUi.disputed;
    default:
      return DealStageUi.lead;
  }
}

String dealStageToApi(DealStageUi stage) {
  switch (stage) {
    case DealStageUi.commissionPayout:
      return 'commission_payout';
    default:
      return stage.name;
  }
}

class BrokerageDomain {
  const BrokerageDomain({
    required this.id,
    required this.code,
    required this.name,
    this.description = '',
    this.defaultCommissionBps = 500,
  });

  final String id;
  final String code;
  final String name;
  final String description;
  final int defaultCommissionBps;
}

class WingaBrokerProfile {
  const WingaBrokerProfile({
    required this.id,
    required this.principal,
    required this.displayName,
    this.kind = 'individual',
    this.verificationStatus = 'unverified',
    this.reputationScoreE4 = 5000,
    this.bio = '',
  });

  final String id;
  final String principal;
  final String displayName;
  final String kind;
  final String verificationStatus;
  final int reputationScoreE4;
  final String bio;

  bool get isVerified => verificationStatus == 'verified';
}

class WingaProviderProfile {
  const WingaProviderProfile({
    required this.id,
    required this.principal,
    required this.legalName,
    this.tradingName = '',
    this.verificationStatus = 'unverified',
    this.reputationScoreE4 = 5000,
    this.locations = const [],
  });

  final String id;
  final String principal;
  final String legalName;
  final String tradingName;
  final String verificationStatus;
  final int reputationScoreE4;
  final List<String> locations;

  bool get isVerified => verificationStatus == 'verified';
  String get displayName => tradingName.isNotEmpty ? tradingName : legalName;
}

class WingaOffering {
  const WingaOffering({
    required this.id,
    required this.providerId,
    required this.domainId,
    required this.title,
    required this.kind,
    required this.priceMinor,
    this.currency = 'TZS',
    this.description = '',
    this.attributes = const {},
  });

  final String id;
  final String providerId;
  final String domainId;
  final String title;
  final String kind;
  final int priceMinor;
  final String currency;
  final String description;
  final Map<String, dynamic> attributes;
}

class WingaLead {
  const WingaLead({
    required this.id,
    required this.wingaId,
    required this.customerPrincipal,
    required this.domainId,
    required this.title,
    this.pipelineStage = 'new',
    this.notes = '',
    this.priorityE4 = 5000,
  });

  final String id;
  final String wingaId;
  final String customerPrincipal;
  final String domainId;
  final String title;
  final String pipelineStage;
  final String notes;
  final int priorityE4;
}

class WingaDeal {
  const WingaDeal({
    required this.id,
    required this.reference,
    required this.domainId,
    required this.wingaId,
    required this.providerId,
    required this.customerPrincipal,
    required this.stage,
    required this.amountMinor,
    this.currency = 'TZS',
    this.paymentRef = '',
    this.offeringId,
    this.booking = const {},
  });

  final String id;
  final String reference;
  final String domainId;
  final String wingaId;
  final String providerId;
  final String customerPrincipal;
  final DealStageUi stage;
  final int amountMinor;
  final String currency;
  final String paymentRef;
  final String? offeringId;
  final Map<String, dynamic> booking;

  bool get isPaid => paymentRef.isNotEmpty;
}

class WingaCommissionEvent {
  const WingaCommissionEvent({
    required this.id,
    required this.dealId,
    required this.wingaId,
    required this.commissionMinor,
    required this.status,
    this.currency = 'TZS',
    this.bpsApplied = 0,
    this.level = 1,
  });

  final String id;
  final String dealId;
  final String wingaId;
  final int commissionMinor;
  final String status;
  final String currency;
  final int bpsApplied;
  final int level;

  bool get isSettled => status == 'settled';
  bool get isPending => status == 'calculated' || status == 'held';
}

class WingaAnalyticsSummary {
  const WingaAnalyticsSummary({
    this.dealsTotal = 0,
    this.leadsTotal = 0,
    this.offeringsTotal = 0,
    this.wingasVerified = 0,
    this.providersVerified = 0,
    this.commissionSettledMinor = 0,
  });

  final int dealsTotal;
  final int leadsTotal;
  final int offeringsTotal;
  final int wingasVerified;
  final int providersVerified;
  final int commissionSettledMinor;
}

class WingaAssistResult {
  const WingaAssistResult({
    required this.capability,
    required this.result,
    this.paymentAuthorized = false,
  });

  final String capability;
  final Map<String, dynamic> result;
  final bool paymentAuthorized;
}

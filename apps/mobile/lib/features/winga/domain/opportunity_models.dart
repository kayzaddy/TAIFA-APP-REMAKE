/// Client-side opportunity marketplace models (experience layer — no API redesign).
class WingaOpportunity {
  const WingaOpportunity({
    required this.id,
    required this.title,
    required this.industry,
    required this.location,
    required this.commissionBps,
    required this.providerName,
    this.urgency = 'Open',
    this.trending = false,
    this.objective = '',
    this.budgetLabel = '',
  });

  final String id;
  final String title;
  final String industry;
  final String location;
  final int commissionBps;
  final String providerName;
  final String urgency;
  final bool trending;
  final String objective;
  final String budgetLabel;

  String get commissionLabel =>
      '${(commissionBps / 100).toStringAsFixed(0)}% commission · $providerName';
}

/// Seed opportunity feed for Wingas — maps to real campaign concepts.
class WingaOpportunityCatalog {
  const WingaOpportunityCatalog._();

  static List<WingaOpportunity> all() => const [
        WingaOpportunity(
          id: 'opp-hotel-50',
          title: 'Book 50 harbour-view rooms this month',
          industry: 'Hotels',
          location: 'Dar es Salaam',
          commissionBps: 1200,
          providerName: 'Harbour View',
          urgency: 'High demand',
          trending: true,
          objective: '50 confirmed stays',
          budgetLabel: 'TZS 40M pool',
        ),
        WingaOpportunity(
          id: 'opp-insure',
          title: 'Motor insurance referrals — Q3 push',
          industry: 'Insurance',
          location: 'National',
          commissionBps: 1500,
          providerName: 'Umoja Cover',
          urgency: 'Open',
          trending: true,
          objective: '200 policies',
          budgetLabel: 'Performance bonus',
        ),
        WingaOpportunity(
          id: 'opp-tenants',
          title: 'Find 20 Masaki office tenants',
          industry: 'Property',
          location: 'Masaki',
          commissionBps: 2000,
          providerName: 'Harbour View Estates',
          urgency: 'Closing soon',
          objective: '20 leases',
          budgetLabel: 'Per lease payout',
        ),
        WingaOpportunity(
          id: 'opp-students',
          title: 'University admissions referrals',
          industry: 'Education',
          location: 'Arusha',
          commissionBps: 800,
          providerName: 'Northern College',
          urgency: 'Open',
          objective: '100 applicants',
        ),
        WingaOpportunity(
          id: 'opp-build',
          title: 'Residential construction leads',
          industry: 'Construction',
          location: 'Dodoma',
          commissionBps: 500,
          providerName: 'Ujenzi Partners',
          urgency: 'Open',
          objective: '15 qualified projects',
        ),
        WingaOpportunity(
          id: 'opp-recruit',
          title: 'Hospitality staff recruitment',
          industry: 'Employment',
          location: 'Zanzibar',
          commissionBps: 1000,
          providerName: 'Island Hotels Group',
          urgency: 'High demand',
          trending: true,
          objective: '40 hires',
        ),
      ];

  static List<WingaOpportunity> filtered({
    String? industry,
    String? query,
    bool trendingOnly = false,
  }) {
    var list = all();
    if (trendingOnly) list = list.where((o) => o.trending).toList();
    if (industry != null && industry.isNotEmpty) {
      list = list
          .where((o) => o.industry.toLowerCase() == industry.toLowerCase())
          .toList();
    }
    if (query != null && query.trim().isNotEmpty) {
      final q = query.toLowerCase();
      list = list
          .where(
            (o) =>
                o.title.toLowerCase().contains(q) ||
                o.industry.toLowerCase().contains(q) ||
                o.location.toLowerCase().contains(q),
          )
          .toList();
    }
    return list;
  }
}

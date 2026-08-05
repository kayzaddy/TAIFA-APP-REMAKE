import '../../wallet/domain/currency.dart';
import '../../wallet/domain/money.dart';
import '../domain/property_models.dart';
import 'property_repository.dart';

/// Offline fallback when remote backend is disabled.
class SeedPropertyRepository implements PropertyRepository {
  @override
  bool get serverAuthoritative => false;

  final _listings = [
    PropertyListing(
      id: 'seed-1',
      title: 'Masaki Sea View Apartment',
      description: 'Bright 2-bed near the coast.',
      transactionType: 'rent',
      categoryCode: 'residential',
      propertyTypeCode: 'apartment',
      price: Money(2_500_000, Currency.tzs),
      deposit: Money(5_000_000, Currency.tzs),
      beds: 2,
      baths: 2,
      areaSqm: 95,
      region: 'Dar es Salaam',
      district: 'Kinondoni',
      ward: 'Masaki',
      addressLine: 'Masaki',
      latitude: -6.7505,
      longitude: 39.2795,
      verificationStatus: 'verified',
      primaryPhotoUrl:
          'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800',
      media: const [],
      ownerName: 'Salma Properties',
    ),
  ];

  static const _intel = PropertyNeighborhoodIntel(
    lifestyle: 'upmarket_coastal',
    walkabilityE4: 7200,
    safetyScoreE4: 7800,
    waterReliabilityE4: 8200,
    powerReliabilityE4: 8500,
    nearby: {
      'schools': 5,
      'hospitals': 2,
      'markets': 4,
      'express_merchants': 2,
      'mobility_stations': 1,
      'restaurants': 8,
      'parks': 2,
    },
    nearestStation: 'Masaki Stage',
    stationDistanceMeters: 450,
  );

  @override
  Future<List<PropertyCategory>> categories() async => const [
    PropertyCategory(code: 'residential', name: 'Residential'),
    PropertyCategory(code: 'commercial', name: 'Commercial'),
    PropertyCategory(code: 'land', name: 'Land'),
  ];

  @override
  Future<List<PropertyListing>> search({
    String query = '',
    String region = '',
    String category = '',
    bool verifiedOnly = true,
  }) async => _filter(query: query, category: category);

  @override
  Future<List<PropertyListing>> advancedSearch({
    String query = '',
    String region = '',
    String category = '',
    String lifestyle = '',
    int? minBeds,
    int? minSafetyE4,
    int? minWalkabilityE4,
    bool verifiedOnly = true,
  }) async => _filter(query: query, category: category, minBeds: minBeds);

  @override
  Future<List<PropertyListing>> aiSearch({
    required String query,
    String lifestyle = '',
    String neighborhood = '',
  }) async => _filter(query: query);

  @override
  Future<List<PropertyListing>> recommendations({int limit = 6}) async =>
      _listings.take(limit).toList();

  @override
  Future<List<PropertyListing>> recentlyViewed({int limit = 8}) async =>
      _listings.take(limit).toList();

  @override
  Future<List<PropertyCompareRow>> compare(List<String> listingIds) async {
    return _listings
        .where((l) => listingIds.contains(l.id))
        .map(
          (l) => PropertyCompareRow(
            id: l.id,
            title: l.title,
            price: l.price,
            beds: l.beds,
            baths: l.baths,
            areaSqm: l.areaSqm,
            location: l.locationLabel,
            visitStars: 4,
            visitLabel: 'Good match',
            safetyE4: _intel.safetyScoreE4,
            walkabilityE4: _intel.walkabilityE4,
            isVerified: l.isVerified,
          ),
        )
        .toList();
  }

  List<PropertyListing> _filter({
    String query = '',
    String category = '',
    int? minBeds,
  }) {
    return _listings.where((l) {
      if (category.isNotEmpty && l.categoryCode != category) return false;
      if (minBeds != null && l.beds < minBeds) return false;
      if (query.isNotEmpty && !l.title.toLowerCase().contains(query.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<PropertyListing> getById(String id) async =>
      _listings.firstWhere((l) => l.id == id);

  @override
  Future<PropertyNeighborhoodIntel> getIntelligence(String listingId) async => _intel;

  @override
  Future<PropertyVisitScore> getVisitScore(
    String listingId, {
    double? destLat,
    double? destLng,
  }) async =>
      const PropertyVisitScore(stars: 4, label: 'Good match', scoreE4: 7600);

  @override
  Future<PropertyCommuteEstimate> getCommute(
    String listingId, {
    required double destLat,
    required double destLng,
    String mode = 'driving',
  }) async =>
      const PropertyCommuteEstimate(
        durationSeconds: 1200,
        durationLabel: '20 min',
        distanceMeters: 8500,
        mode: 'driving',
      );

  @override
  Future<List<PropertyMapPin>> mapPins({String region = ''}) async => [
    PropertyMapPin(
      id: 'seed-1',
      title: 'Masaki Sea View Apartment',
      lat: -6.7505,
      lng: 39.2795,
      price: Money(2_500_000, Currency.tzs),
      beds: 2,
      transactionType: 'rent',
    ),
  ];

  @override
  Future<List<PropertyMapCluster>> mapClusters({String region = ''}) async {
    final pins = await mapPins(region: region);
    if (pins.isEmpty) return [];
    return [
      PropertyMapCluster(
        clusterId: '0:0',
        lat: pins.first.lat,
        lng: pins.first.lng,
        count: pins.length,
        pins: pins,
      ),
    ];
  }

  @override
  Future<PropertyExperience> getExperience(String listingId) async {
    return PropertyExperience(
      gallery: _listings.first.media,
      walkthrough: const [
        PropertyWalkthroughRoom(
          roomCode: 'living',
          label: 'Living room',
          media: [],
        ),
      ],
      videoTours: const [],
      floorPlans: const [],
      panoramas360: const [],
      vrReady: false,
    );
  }

  @override
  Future<List<ViewingPassPlan>> viewingPassPlans() async => const [
    ViewingPassPlan(
      code: 'single',
      name: 'Single Viewing Pass',
      description: 'Unlock one property',
      amountMinor: 25000,
      currency: 'TZS',
      listingQuota: 1,
      durationDays: 7,
    ),
  ];

  @override
  Future<PropertyViewingPass> createViewingPass({
    required String planCode,
    String? listingId,
  }) async =>
      PropertyViewingPass(
        id: 'seed-pass',
        planCode: planCode,
        status: 'pending_payment',
        amountMinor: 25000,
        currency: 'TZS',
        qrToken: 'seed-qr',
        isUnlocked: false,
        listingId: listingId,
      );

  @override
  Future<PropertyViewingPass> payViewingPass(
    String passId, {
    required String idempotencyKey,
  }) async =>
      PropertyViewingPass(
        id: passId,
        planCode: 'single',
        status: 'active',
        amountMinor: 25000,
        currency: 'TZS',
        qrToken: 'seed-qr-active',
        isUnlocked: true,
        listingId: 'seed-1',
        paymentRef: 'demo-txn',
      );

  @override
  Future<List<PropertyViewingPass>> myViewingPasses() async => [];

  @override
  Future<PropertyLiveSession> requestLiveSession(String listingId, {String notes = ''}) async =>
      PropertyLiveSession(
        id: 'seed-live',
        listingId: listingId,
        listingTitle: 'Masaki Sea View Apartment',
        status: 'requested',
        joinCode: 'ABCD1234',
      );

  @override
  Future<PropertyLiveSession> joinLiveSession(String sessionId) async =>
      PropertyLiveSession(
        id: sessionId,
        listingId: 'seed-1',
        listingTitle: 'Masaki Sea View Apartment',
        status: 'live',
        joinCode: 'ABCD1234',
        streamUrl: 'https://live.taifa.local/demo',
      );

  @override
  Future<PropertyLiveSession> endLiveSession(String sessionId) async =>
      PropertyLiveSession(
        id: sessionId,
        listingId: 'seed-1',
        listingTitle: 'Masaki Sea View Apartment',
        status: 'ended',
        joinCode: 'ABCD1234',
        aiTranscriptSummary: 'Demo live tour completed.',
      );

  @override
  Future<void> postLiveMessage(String sessionId, String body) async {}

  @override
  Future<String> copilotChat({required String query, String? listingId}) async =>
      'Based on your question "$query", this property looks like a solid match for family living near the coast.';

  @override
  Future<PropertyWingaAssignment> assignWinga(String listingId, {String notes = ''}) async =>
      PropertyWingaAssignment(
        id: 'seed-assignment',
        listingId: listingId,
        listingTitle: 'Masaki Sea View Apartment',
        status: 'active',
        winga: const PropertyWingaProfile(
          id: 'seed-winga',
          displayName: 'Asha Mwangi',
          certification: 'Taifa Certified Property Advisor',
          reputationScoreE4: 8200,
          trustStars: 4,
        ),
        chatMessages: const [
          PropertySecureChatMessage(
            id: '1',
            text: "Hi! I'm Asha, your Taifa property Winga. How can I help?",
            isMe: false,
          ),
        ],
      );

  @override
  Future<PropertyWingaAssignment> loadAssignment(String assignmentId) async =>
      assignWinga('seed-1');

  @override
  Future<List<PropertySecureChatMessage>> loadAssignmentChat(String assignmentId) async =>
      const [
        PropertySecureChatMessage(id: '1', text: 'Hi! How can I help?', isMe: false),
      ];

  @override
  Future<PropertySecureChatMessage> sendAssignmentChat(
    String assignmentId,
    String text,
  ) async =>
      PropertySecureChatMessage(id: '2', text: text, isMe: true);

  static final _seedLease = PropertyLease(
    id: 'seed-lease',
    applicationId: 'seed-app',
    status: 'pending_signatures',
    rent: Money(2_500_000, Currency.tzs),
    deposit: Money(5_000_000, Currency.tzs),
    startDate: '2026-08-01',
    endDate: '2027-07-31',
    contractText: 'Sample residential lease agreement for Masaki apartment.',
    payments: const [
      PropertyLeasePayment(
        id: 'seed-deposit',
        kind: 'deposit',
        status: 'pending_payment',
        amount: Money(5_000_000, Currency.tzs),
      ),
    ],
    moveWorkflows: const [],
  );

  @override
  Future<PropertyApplication> createApplication(String listingId, Map<String, dynamic> body) async =>
      PropertyApplication(
        id: 'seed-app',
        listingId: listingId,
        listingTitle: 'Masaki Sea View Apartment',
        status: 'draft',
        monthlyIncomeMinor: (body['monthly_income_minor'] as int?) ?? 0,
        nationalIdMasked: '19***12',
        verifications: const {},
        documents: const [],
        readyForApproval: false,
        employmentStatus: body['employment_status']?.toString() ?? '',
        notes: body['notes']?.toString() ?? '',
      );

  @override
  Future<PropertyApplication> loadApplication(String applicationId) async =>
      createApplication('seed-1', {});

  @override
  Future<PropertyApplication> submitApplication(String applicationId) async =>
      PropertyApplication(
        id: applicationId,
        listingId: 'seed-1',
        listingTitle: 'Masaki Sea View Apartment',
        status: 'under_review',
        monthlyIncomeMinor: 10_000_000,
        nationalIdMasked: '19***12',
        verifications: const {
          'identity': PropertyVerificationCheck(status: 'pending'),
          'income': PropertyVerificationCheck(status: 'pending'),
        },
        documents: const [],
        readyForApproval: false,
      );

  @override
  Future<PropertyApplication> verifyApplicationIdentity(String applicationId) async =>
      PropertyApplication(
        id: applicationId,
        listingId: 'seed-1',
        listingTitle: 'Masaki Sea View Apartment',
        status: 'under_review',
        monthlyIncomeMinor: 10_000_000,
        nationalIdMasked: '19***12',
        verifications: const {
          'identity': PropertyVerificationCheck(status: 'verified', providerRef: 'STUB'),
          'income': PropertyVerificationCheck(status: 'pending'),
        },
        documents: const [],
        readyForApproval: false,
      );

  @override
  Future<PropertyApplication> verifyApplicationIncome(String applicationId) async =>
      PropertyApplication(
        id: applicationId,
        listingId: 'seed-1',
        listingTitle: 'Masaki Sea View Apartment',
        status: 'under_review',
        monthlyIncomeMinor: 10_000_000,
        nationalIdMasked: '19***12',
        verifications: const {
          'identity': PropertyVerificationCheck(status: 'verified'),
          'income': PropertyVerificationCheck(status: 'verified'),
        },
        documents: const [],
        readyForApproval: true,
      );

  @override
  Future<PropertyApplication> approveApplication(String applicationId) async =>
      PropertyApplication(
        id: applicationId,
        listingId: 'seed-1',
        listingTitle: 'Masaki Sea View Apartment',
        status: 'approved',
        monthlyIncomeMinor: 10_000_000,
        nationalIdMasked: '19***12',
        verifications: const {
          'identity': PropertyVerificationCheck(status: 'verified'),
          'income': PropertyVerificationCheck(status: 'verified'),
        },
        documents: const [],
        readyForApproval: true,
      );

  @override
  Future<PropertyLease> generateLease(String applicationId) async => _seedLease;

  @override
  Future<PropertyLease> loadLease(String leaseId) async => signLease(leaseId);

  @override
  Future<PropertyLease> signLease(String leaseId) async => PropertyLease(
        id: leaseId,
        applicationId: 'seed-app',
        status: 'active',
        rent: _seedLease.rent,
        deposit: _seedLease.deposit,
        startDate: _seedLease.startDate,
        endDate: _seedLease.endDate,
        contractText: _seedLease.contractText,
        payments: _seedLease.payments,
        moveWorkflows: const [
          PropertyMoveWorkflow(
            id: 'seed-move',
            phase: 'move_in',
            status: 'scheduled',
            scheduledAt: '2026-08-01T09:00:00',
            checklist: [
              {'code': 'keys', 'label': 'Collect keys', 'done': false},
            ],
          ),
        ],
        tenantSigned: true,
        ownerSigned: true,
      );

  @override
  Future<PropertyLeasePayment> payLeasePayment(
    String paymentId, {
    required String idempotencyKey,
  }) async =>
      PropertyLeasePayment(
        id: paymentId,
        kind: 'deposit',
        status: 'paid',
        amount: Money(5_000_000, Currency.tzs),
      );

  @override
  Future<PropertyLease> renewLease(String leaseId) async => signLease(leaseId);

  @override
  Future<PropertyMoveWorkflow> completeMoveWorkflow(String workflowId) async =>
      const PropertyMoveWorkflow(
        id: 'seed-move',
        phase: 'move_in',
        status: 'completed',
        scheduledAt: '2026-08-01T09:00:00',
        checklist: [
          {'code': 'keys', 'label': 'Collect keys', 'done': true},
        ],
      );

  @override
  Future<PropertyOpsConsole> loadOpsConsole({String region = ''}) async {
    final dash = await opsDashboard(region: region);
    final reports = await moderationQueue();
    final disputes = await listDisputes();
    return PropertyOpsConsole(
      dashboard: dash,
      moderationReports: reports,
      disputes: disputes,
      recentAudit: const [],
    );
  }

  @override
  Future<void> resolveModerationReport(
    String reportId, {
    required String action,
    String notes = '',
  }) async {}

  @override
  Future<PropertyOpsDashboard> opsDashboard({String region = ''}) async => const PropertyOpsDashboard(
        listingsTotal: 4,
        listingsVerified: 4,
        applicationsTotal: 2,
        leasesActive: 1,
        gmvMinor: 7_500_000,
        disputesOpen: 0,
        moderationPending: 1,
      );

  @override
  Future<PropertyFraudSignals> listingFraudSignals(String listingId) async =>
      const PropertyFraudSignals(
        signals: [],
        riskScoreE4: 1400,
        advisoryOnly: true,
        mlRiskBand: 'low',
        mlReasoning: 'Stub ML assessment',
      );

  @override
  Future<void> reportListing(String listingId, {required String reason, String notes = ''}) async {}

  @override
  Future<List<PropertyModerationReport>> moderationQueue() async => const [
        PropertyModerationReport(
          id: 'seed-report',
          listingId: 'seed-1',
          listingTitle: 'Masaki Sea View Apartment',
          reason: 'misleading',
          status: 'pending',
          notes: 'Sample report',
        ),
      ];

  @override
  Future<List<PropertyDispute>> listDisputes({String status = ''}) async => const [];

  @override
  Future<bool> toggleFavorite(String listingId) async => true;

  @override
  Future<List<PropertyListing>> favorites() async => [];

  @override
  Future<PropertyListing> createListing(Map<String, dynamic> body) async =>
      _listings.first;

  @override
  Future<PropertyListing> addMedia(String listingId, Map<String, dynamic> body) async =>
      getById(listingId);
}

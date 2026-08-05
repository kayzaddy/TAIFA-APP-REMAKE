import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/winga_property/rest_property_repository.dart';
import '../../wallet/application/wallet_providers.dart'
    show apiClientProvider, apiConfigProvider;
import '../domain/property_models.dart';
import 'property_repository.dart';
import 'seed_property_repository.dart';

final propertyRepositoryProvider = Provider<PropertyRepository>((ref) {
  if (ref.watch(apiConfigProvider).useRemoteBackend) {
    return RestPropertyRepository(ref.watch(apiClientProvider));
  }
  return SeedPropertyRepository();
});

/// Default commute destination — Dar CBD (foundation).
const kPropertyWorkLat = -6.8160;
const kPropertyWorkLng = 39.2803;

const _unset = Object();

class PropertyUiState {
  const PropertyUiState({
    this.listings = const [],
    this.pins = const [],
    this.clusters = const [],
    this.favorites = const [],
    this.recentlyViewed = const [],
    this.recommendations = const [],
    this.categories = const [],
    this.compareIds = const [],
    this.compareRows = const [],
    this.selectedCategory = '',
    this.query = '',
    this.lifestyle = '',
    this.minBeds,
    this.minSafetyE4,
    this.showMap = false,
    this.showAdvancedFilters = false,
    this.showCompare = false,
    this.useAiSearch = false,
    this.isBusy = false,
    this.error,
    this.selected,
    this.intelligence,
    this.visitScore,
    this.commute,
    this.experience,
    this.viewingPassPlans = const [],
    this.viewingPasses = const [],
    this.activePass,
    this.liveSession,
    this.showExperience = false,
    this.showViewingPass = false,
    this.showLiveSession = false,
    this.showCopilot = false,
    this.showHumanWinga = false,
    this.showApply = false,
    this.showOps = false,
    this.showReport = false,
    this.copilotMessages = const [],
    this.assignment,
    this.assignmentChat = const [],
    this.application,
    this.lease,
    this.opsDashboard,
    this.moderationReports = const [],
    this.disputes = const [],
  });

  final List<PropertyListing> listings;
  final List<PropertyMapPin> pins;
  final List<PropertyMapCluster> clusters;
  final List<PropertyListing> favorites;
  final List<PropertyListing> recentlyViewed;
  final List<PropertyListing> recommendations;
  final List<PropertyCategory> categories;
  final List<String> compareIds;
  final List<PropertyCompareRow> compareRows;
  final String selectedCategory;
  final String query;
  final String lifestyle;
  final int? minBeds;
  final int? minSafetyE4;
  final bool showMap;
  final bool showAdvancedFilters;
  final bool showCompare;
  final bool useAiSearch;
  final bool isBusy;
  final String? error;
  final PropertyListing? selected;
  final PropertyNeighborhoodIntel? intelligence;
  final PropertyVisitScore? visitScore;
  final PropertyCommuteEstimate? commute;
  final PropertyExperience? experience;
  final List<ViewingPassPlan> viewingPassPlans;
  final List<PropertyViewingPass> viewingPasses;
  final PropertyViewingPass? activePass;
  final PropertyLiveSession? liveSession;
  final bool showExperience;
  final bool showViewingPass;
  final bool showLiveSession;
  final bool showCopilot;
  final bool showHumanWinga;
  final bool showApply;
  final bool showOps;
  final bool showReport;
  final List<String> copilotMessages;
  final PropertyWingaAssignment? assignment;
  final List<PropertySecureChatMessage> assignmentChat;
  final PropertyApplication? application;
  final PropertyLease? lease;
  final PropertyOpsDashboard? opsDashboard;
  final List<PropertyModerationReport> moderationReports;
  final List<PropertyDispute> disputes;

  PropertyUiState copyWith({
    List<PropertyListing>? listings,
    List<PropertyMapPin>? pins,
    List<PropertyMapCluster>? clusters,
    List<PropertyListing>? favorites,
    List<PropertyListing>? recentlyViewed,
    List<PropertyListing>? recommendations,
    List<PropertyCategory>? categories,
    List<String>? compareIds,
    List<PropertyCompareRow>? compareRows,
    String? selectedCategory,
    String? query,
    String? lifestyle,
    Object? minBeds = _unset,
    Object? minSafetyE4 = _unset,
    bool? showMap,
    bool? showAdvancedFilters,
    bool? showCompare,
    bool? useAiSearch,
    bool? isBusy,
    String? error,
    PropertyListing? selected,
    PropertyNeighborhoodIntel? intelligence,
    PropertyVisitScore? visitScore,
    PropertyCommuteEstimate? commute,
    PropertyExperience? experience,
    List<ViewingPassPlan>? viewingPassPlans,
    List<PropertyViewingPass>? viewingPasses,
    PropertyViewingPass? activePass,
    PropertyLiveSession? liveSession,
    bool? showExperience,
    bool? showViewingPass,
    bool? showLiveSession,
    bool? showCopilot,
    bool? showHumanWinga,
    bool? showApply,
    bool? showOps,
    bool? showReport,
    List<String>? copilotMessages,
    PropertyWingaAssignment? assignment,
    List<PropertySecureChatMessage>? assignmentChat,
    PropertyApplication? application,
    PropertyLease? lease,
    PropertyOpsDashboard? opsDashboard,
    List<PropertyModerationReport>? moderationReports,
    List<PropertyDispute>? disputes,
    bool clearError = false,
    bool clearSelected = false,
    bool clearIntelligence = false,
    bool clearApplication = false,
    bool clearLease = false,
  }) {
    return PropertyUiState(
      listings: listings ?? this.listings,
      pins: pins ?? this.pins,
      clusters: clusters ?? this.clusters,
      favorites: favorites ?? this.favorites,
      recentlyViewed: recentlyViewed ?? this.recentlyViewed,
      recommendations: recommendations ?? this.recommendations,
      categories: categories ?? this.categories,
      compareIds: compareIds ?? this.compareIds,
      compareRows: compareRows ?? this.compareRows,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      query: query ?? this.query,
      lifestyle: lifestyle ?? this.lifestyle,
      minBeds: minBeds == _unset ? this.minBeds : minBeds as int?,
      minSafetyE4: minSafetyE4 == _unset ? this.minSafetyE4 : minSafetyE4 as int?,
      showMap: showMap ?? this.showMap,
      showAdvancedFilters: showAdvancedFilters ?? this.showAdvancedFilters,
      showCompare: showCompare ?? this.showCompare,
      useAiSearch: useAiSearch ?? this.useAiSearch,
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : (error ?? this.error),
      selected: clearSelected ? null : (selected ?? this.selected),
      intelligence: clearIntelligence ? null : (intelligence ?? this.intelligence),
      visitScore: clearIntelligence ? null : (visitScore ?? this.visitScore),
      commute: clearIntelligence ? null : (commute ?? this.commute),
      experience: experience ?? this.experience,
      viewingPassPlans: viewingPassPlans ?? this.viewingPassPlans,
      viewingPasses: viewingPasses ?? this.viewingPasses,
      activePass: activePass ?? this.activePass,
      liveSession: liveSession ?? this.liveSession,
      showExperience: showExperience ?? this.showExperience,
      showViewingPass: showViewingPass ?? this.showViewingPass,
      showLiveSession: showLiveSession ?? this.showLiveSession,
      showCopilot: showCopilot ?? this.showCopilot,
      showHumanWinga: showHumanWinga ?? this.showHumanWinga,
      showApply: showApply ?? this.showApply,
      showOps: showOps ?? this.showOps,
      showReport: showReport ?? this.showReport,
      copilotMessages: copilotMessages ?? this.copilotMessages,
      assignment: assignment ?? this.assignment,
      assignmentChat: assignmentChat ?? this.assignmentChat,
      application: clearApplication ? null : (application ?? this.application),
      lease: clearLease ? null : (lease ?? this.lease),
      opsDashboard: opsDashboard ?? this.opsDashboard,
      moderationReports: moderationReports ?? this.moderationReports,
      disputes: disputes ?? this.disputes,
    );
  }
}

class PropertyController extends Notifier<PropertyUiState> {
  PropertyRepository get _repo => ref.read(propertyRepositoryProvider);

  @override
  PropertyUiState build() => const PropertyUiState();

  Future<void> bootstrap() async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final results = await Future.wait([
        _repo.categories(),
        _repo.advancedSearch(region: 'Dar es Salaam'),
        _repo.mapPins(region: 'Dar es Salaam'),
        _repo.mapClusters(region: 'Dar es Salaam'),
        _repo.favorites(),
        _repo.recentlyViewed(),
        _repo.recommendations(),
      ]);
      state = state.copyWith(
        categories: results[0] as List<PropertyCategory>,
        listings: results[1] as List<PropertyListing>,
        pins: results[2] as List<PropertyMapPin>,
        clusters: results[3] as List<PropertyMapCluster>,
        favorites: results[4] as List<PropertyListing>,
        recentlyViewed: results[5] as List<PropertyListing>,
        recommendations: results[6] as List<PropertyListing>,
        isBusy: false,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> search(String query) async {
    state = state.copyWith(query: query, isBusy: true, clearError: true);
    try {
      final listings = state.useAiSearch
          ? await _repo.aiSearch(query: query, lifestyle: state.lifestyle)
          : await _repo.advancedSearch(
              query: query,
              region: 'Dar es Salaam',
              category: state.selectedCategory,
              lifestyle: state.lifestyle,
              minBeds: state.minBeds,
              minSafetyE4: state.minSafetyE4,
            );
      state = state.copyWith(listings: listings, isBusy: false);
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  void setCategory(String code) {
    state = state.copyWith(selectedCategory: code);
    search(state.query);
  }

  void setLifestyle(String lifestyle) {
    state = state.copyWith(lifestyle: lifestyle);
    search(state.query);
  }

  void setMinBeds(int? beds) {
    state = state.copyWith(minBeds: beds);
    search(state.query);
  }

  void setMinSafety(int? safetyE4) {
    state = state.copyWith(minSafetyE4: safetyE4);
    search(state.query);
  }

  void toggleAiSearch() {
    state = state.copyWith(useAiSearch: !state.useAiSearch);
    if (state.query.isNotEmpty) search(state.query);
  }

  void toggleAdvancedFilters() {
    state = state.copyWith(showAdvancedFilters: !state.showAdvancedFilters);
  }

  void toggleMap() {
    state = state.copyWith(showMap: !state.showMap);
  }

  Future<void> openListing(String id) async {
    state = state.copyWith(isBusy: true, clearError: true, clearIntelligence: true);
    try {
      final listing = await _repo.getById(id);
      final intel = await _repo.getIntelligence(id);
      final visit = await _repo.getVisitScore(
        id,
        destLat: kPropertyWorkLat,
        destLng: kPropertyWorkLng,
      );
      final commute = await _repo.getCommute(
        id,
        destLat: kPropertyWorkLat,
        destLng: kPropertyWorkLng,
      );
      final recent = await _repo.recentlyViewed();
      final passes = await _repo.myViewingPasses();
      final active = passes.where((p) => p.isActive).firstOrNull;
      state = state.copyWith(
        selected: listing,
        intelligence: intel,
        visitScore: visit,
        commute: commute,
        recentlyViewed: recent,
        viewingPasses: passes,
        activePass: active,
        isBusy: false,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  void closeDetail() {
    state = state.copyWith(clearSelected: true, clearIntelligence: true);
  }

  Future<void> toggleFavorite(PropertyListing listing) async {
    try {
      await _repo.toggleFavorite(listing.id);
      final favorites = await _repo.favorites();
      state = state.copyWith(favorites: favorites);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  bool isFavorite(String id) => state.favorites.any((f) => f.id == id);

  void toggleCompare(String id) {
    final ids = List<String>.from(state.compareIds);
    if (ids.contains(id)) {
      ids.remove(id);
    } else if (ids.length < 4) {
      ids.add(id);
    }
    state = state.copyWith(compareIds: ids);
  }

  bool isInCompare(String id) => state.compareIds.contains(id);

  Future<void> runCompare() async {
    if (state.compareIds.length < 2) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final rows = await _repo.compare(state.compareIds);
      state = state.copyWith(compareRows: rows, showCompare: true, isBusy: false);
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  void closeCompare() {
    state = state.copyWith(showCompare: false);
  }

  void clearCompare() {
    state = state.copyWith(compareIds: const [], compareRows: const [], showCompare: false);
  }

  Future<void> openExperience() async {
    final listing = state.selected;
    if (listing == null) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final experience = await _repo.getExperience(listing.id);
      state = state.copyWith(experience: experience, showExperience: true, isBusy: false);
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  void closeExperience() {
    state = state.copyWith(showExperience: false);
  }

  Future<void> openViewingPass() async {
    final listing = state.selected;
    if (listing == null) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final plans = await _repo.viewingPassPlans();
      state = state.copyWith(viewingPassPlans: plans, showViewingPass: true, isBusy: false);
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  void closeViewingPass() {
    state = state.copyWith(showViewingPass: false);
  }

  Future<void> purchaseViewingPass(String planCode) async {
    final listing = state.selected;
    if (listing == null) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final pass = await _repo.createViewingPass(
        planCode: planCode,
        listingId: planCode == 'single' ? listing.id : null,
      );
      final paid = await _repo.payViewingPass(
        pass.id,
        idempotencyKey: 'wp-${pass.id}-${DateTime.now().millisecondsSinceEpoch}',
      );
      final refreshed = await _repo.getById(listing.id);
      state = state.copyWith(
        activePass: paid,
        selected: refreshed,
        showViewingPass: false,
        isBusy: false,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> requestLiveTour({String notes = ''}) async {
    final listing = state.selected;
    if (listing == null) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final session = await _repo.requestLiveSession(listing.id, notes: notes);
      final joined = await _repo.joinLiveSession(session.id);
      state = state.copyWith(liveSession: joined, showLiveSession: true, isBusy: false);
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  void closeLiveSession() {
    state = state.copyWith(showLiveSession: false);
  }

  Future<void> endLiveTour() async {
    final session = state.liveSession;
    if (session == null) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final ended = await _repo.endLiveSession(session.id);
      state = state.copyWith(liveSession: ended, isBusy: false);
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  void openCopilot() {
    state = state.copyWith(showCopilot: true, copilotMessages: const []);
  }

  void closeCopilot() {
    state = state.copyWith(showCopilot: false);
  }

  Future<void> askCopilot(String query) async {
    final listing = state.selected;
    if (query.trim().isEmpty) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final answer = await _repo.copilotChat(
        query: query,
        listingId: listing?.id,
      );
      state = state.copyWith(
        copilotMessages: [...state.copilotMessages, 'You: $query', 'Winga AI: $answer'],
        isBusy: false,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> assignHumanWinga() async {
    final listing = state.selected;
    if (listing == null) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final assignment = await _repo.assignWinga(listing.id);
      final chat = await _repo.loadAssignmentChat(assignment.id);
      state = state.copyWith(
        assignment: assignment,
        assignmentChat: chat,
        showHumanWinga: true,
        isBusy: false,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  void closeHumanWinga() {
    state = state.copyWith(showHumanWinga: false);
  }

  Future<void> sendWingaChat(String text) async {
    final assignment = state.assignment;
    if (assignment == null || text.trim().isEmpty) return;
    try {
      final msg = await _repo.sendAssignmentChat(assignment.id, text);
      state = state.copyWith(assignmentChat: [...state.assignmentChat, msg]);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void openApply() {
    state = state.copyWith(showApply: true, clearApplication: true, clearLease: true);
  }

  void closeApply() {
    state = state.copyWith(showApply: false);
  }

  Future<void> startApplication({
    required String employmentStatus,
    required int monthlyIncomeMinor,
    required String nationalId,
  }) async {
    final listing = state.selected;
    if (listing == null) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final app = await _repo.createApplication(listing.id, {
        'employment_status': employmentStatus,
        'monthly_income_minor': monthlyIncomeMinor,
        'national_id': nationalId,
      });
      state = state.copyWith(application: app, isBusy: false);
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> submitApplication() async {
    final app = state.application;
    if (app == null) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final submitted = await _repo.submitApplication(app.id);
      state = state.copyWith(application: submitted, isBusy: false);
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> verifyApplicationIdentity() async {
    final app = state.application;
    if (app == null) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final updated = await _repo.verifyApplicationIdentity(app.id);
      state = state.copyWith(application: updated, isBusy: false);
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> verifyApplicationIncome() async {
    final app = state.application;
    if (app == null) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final updated = await _repo.verifyApplicationIncome(app.id);
      state = state.copyWith(application: updated, isBusy: false);
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> approveApplication() async {
    final app = state.application;
    if (app == null) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final approved = await _repo.approveApplication(app.id);
      state = state.copyWith(application: approved, isBusy: false);
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> generateLease() async {
    final app = state.application;
    if (app == null) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final lease = await _repo.generateLease(app.id);
      state = state.copyWith(lease: lease, isBusy: false);
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> signLease() async {
    final lease = state.lease;
    if (lease == null) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final signed = await _repo.signLease(lease.id);
      state = state.copyWith(lease: signed, isBusy: false);
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> payDeposit() async {
    final lease = state.lease;
    if (lease == null) return;
    final deposit = lease.payments.where((p) => p.kind == 'deposit' && p.isPending).firstOrNull;
    if (deposit == null) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      await _repo.payLeasePayment(
        deposit.id,
        idempotencyKey: 'lease-${deposit.id}-${DateTime.now().millisecondsSinceEpoch}',
      );
      final refreshed = await _repo.loadLease(lease.id);
      state = state.copyWith(lease: refreshed, isBusy: false);
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> completeMoveIn() async {
    final lease = state.lease;
    if (lease == null) return;
    final workflow = lease.moveWorkflows.where((w) => w.status != 'completed').firstOrNull;
    if (workflow == null) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      await _repo.completeMoveWorkflow(workflow.id);
      final refreshed = await _repo.loadLease(lease.id);
      state = state.copyWith(lease: refreshed, isBusy: false);
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> renewLease() async {
    final lease = state.lease;
    if (lease == null) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final renewed = await _repo.renewLease(lease.id);
      state = state.copyWith(lease: renewed, isBusy: false);
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> openOpsPortal() async {
    state = state.copyWith(isBusy: true, clearError: true, showOps: true);
    try {
      final results = await Future.wait([
        _repo.opsDashboard(),
        _repo.moderationQueue(),
        _repo.listDisputes(),
      ]);
      state = state.copyWith(
        opsDashboard: results[0] as PropertyOpsDashboard,
        moderationReports: results[1] as List<PropertyModerationReport>,
        disputes: results[2] as List<PropertyDispute>,
        isBusy: false,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  void closeOpsPortal() {
    state = state.copyWith(showOps: false);
  }

  Future<void> refreshOpsPortal() async {
    await openOpsPortal();
  }

  void openReportListing() {
    state = state.copyWith(showReport: true);
  }

  void closeReportListing() {
    state = state.copyWith(showReport: false);
  }

  Future<void> submitListingReport(String reason, String notes) async {
    final listing = state.selected;
    if (listing == null) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      await _repo.reportListing(listing.id, reason: reason, notes: notes);
      state = state.copyWith(showReport: false, isBusy: false);
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }
}

final propertyControllerProvider =
    NotifierProvider<PropertyController, PropertyUiState>(PropertyController.new);

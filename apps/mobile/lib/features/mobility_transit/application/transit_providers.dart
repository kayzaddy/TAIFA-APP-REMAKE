import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/trips/rest_transit_repository.dart';
import '../../wallet/application/wallet_providers.dart'
    show apiClientProvider, apiConfigProvider, walletControllerProvider;
import '../domain/transit_models.dart';
import 'noop_nfc_boarding_port.dart';
import 'seed_transit_repository.dart';
import 'transit_repository.dart';
import '../domain/nfc_boarding_port.dart';

/// Default map center — Ubungo BRT interchange.
const kTransitDefaultLat = -6.7912;
const kTransitDefaultLng = 39.2089;

final transitRepositoryProvider = Provider<TransitRepository>((ref) {
  if (ref.watch(apiConfigProvider).useRemoteBackend) {
    return RestTransitRepository(ref.watch(apiClientProvider));
  }
  return SeedTransitRepository();
});

final nfcBoardingPortProvider = Provider<NfcBoardingPort>((ref) {
  return const NoOpNfcBoardingPort();
});

class TransitUiState {
  const TransitUiState({
    this.home,
    this.modes = const [],
    this.selectedMode = '',
    this.routes = const [],
    this.searchResults = const [],
    this.myTickets = const [],
    this.products = const [],
    this.planOptions = const [],
    this.stationDetail,
    this.selectedRoute,
    this.activeTicket,
    this.query = '',
    this.planOrigin = 'kimara',
    this.planDestination = 'kivukoni',
    this.selectedProductCode = 'brt_single',
    this.isBusy = false,
    this.error,
  });

  final TransitHome? home;
  final List<TransitMode> modes;
  final String selectedMode;
  final List<TransitRoute> routes;
  final List<TransitRoute> searchResults;
  final List<TransitTicket> myTickets;
  final List<TransitProduct> products;
  final List<TransitPlanOption> planOptions;
  final TransitStationDetail? stationDetail;
  final TransitRoute? selectedRoute;
  final TransitTicket? activeTicket;
  final String query;
  final String planOrigin;
  final String planDestination;
  final String selectedProductCode;
  final bool isBusy;
  final String? error;

  TransitUiState copyWith({
    TransitHome? home,
    List<TransitMode>? modes,
    String? selectedMode,
    List<TransitRoute>? routes,
    List<TransitRoute>? searchResults,
    List<TransitTicket>? myTickets,
    List<TransitProduct>? products,
    List<TransitPlanOption>? planOptions,
    TransitStationDetail? stationDetail,
    TransitRoute? selectedRoute,
    TransitTicket? activeTicket,
    String? query,
    String? planOrigin,
    String? planDestination,
    String? selectedProductCode,
    bool? isBusy,
    String? error,
    bool clearError = false,
    bool clearSelected = false,
    bool clearActiveTicket = false,
    bool clearStation = false,
  }) {
    return TransitUiState(
      home: home ?? this.home,
      modes: modes ?? this.modes,
      selectedMode: selectedMode ?? this.selectedMode,
      routes: routes ?? this.routes,
      searchResults: searchResults ?? this.searchResults,
      myTickets: myTickets ?? this.myTickets,
      products: products ?? this.products,
      planOptions: planOptions ?? this.planOptions,
      stationDetail: clearStation ? null : (stationDetail ?? this.stationDetail),
      selectedRoute: clearSelected ? null : (selectedRoute ?? this.selectedRoute),
      activeTicket: clearActiveTicket ? null : (activeTicket ?? this.activeTicket),
      query: query ?? this.query,
      planOrigin: planOrigin ?? this.planOrigin,
      planDestination: planDestination ?? this.planDestination,
      selectedProductCode: selectedProductCode ?? this.selectedProductCode,
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class TransitController extends Notifier<TransitUiState> {
  TransitRepository get _repo => ref.read(transitRepositoryProvider);

  @override
  TransitUiState build() => const TransitUiState();

  Future<void> bootstrap() async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      ref.read(walletControllerProvider.notifier).refresh();
      final modes = await _repo.loadModes();
      final home = await _repo.loadHome(
        lat: kTransitDefaultLat,
        lng: kTransitDefaultLng,
        mode: state.selectedMode,
      );
      final tickets = await _repo.myTickets();
      state = state.copyWith(
        modes: modes,
        home: home,
        routes: home.featuredRoutes,
        products: home.products,
        myTickets: tickets,
        isBusy: false,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> switchMode(String mode) async {
    if (mode == state.selectedMode) return;
    state = state.copyWith(
      isBusy: true,
      clearError: true,
      selectedMode: mode,
      clearSelected: true,
    );
    try {
      final home = await _repo.loadHome(
        lat: kTransitDefaultLat,
        lng: kTransitDefaultLng,
        mode: mode,
      );
      final defaultProduct = home.products.isNotEmpty
          ? home.products.first.code
          : (mode == 'daladala' ? 'dala_single' : 'brt_single');
      state = state.copyWith(
        home: home,
        routes: home.featuredRoutes,
        products: home.products,
        selectedProductCode: defaultProduct,
        isBusy: false,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> search(String query) async {
    state = state.copyWith(query: query, isBusy: true, clearError: true);
    try {
      if (query.trim().isEmpty) {
        state = state.copyWith(searchResults: const [], isBusy: false);
        return;
      }
      final results = await _repo.search(query, region: 'Dar es Salaam');
      state = state.copyWith(searchResults: results, isBusy: false);
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> loadStation(String stopCode) async {
    state = state.copyWith(isBusy: true, clearError: true, clearStation: true);
    try {
      final detail = await _repo.getStation(stopCode);
      state = state.copyWith(stationDetail: detail, isBusy: false);
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  void setPlanStops({String? origin, String? destination}) {
    state = state.copyWith(
      planOrigin: origin ?? state.planOrigin,
      planDestination: destination ?? state.planDestination,
    );
  }

  Future<void> runPlanner() async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final plans = await _repo.planJourney(
        originStop: state.planOrigin,
        destinationStop: state.planDestination,
        region: 'Dar es Salaam',
      );
      state = state.copyWith(planOptions: plans, isBusy: false);
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  void selectProduct(String code) {
    state = state.copyWith(selectedProductCode: code);
  }

  Future<void> openRoute(String id) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final route = await _repo.getRoute(id);
      final products = await _repo.listProducts(mode: route.mode);
      final defaultProduct = products.isNotEmpty
          ? products.first.code
          : (route.mode == 'daladala' ? 'dala_single' : 'brt_single');
      state = state.copyWith(
        selectedRoute: route,
        products: products,
        selectedProductCode: defaultProduct,
        isBusy: false,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  void closeRoute() {
    state = state.copyWith(clearSelected: true);
  }

  Future<TransitTicket?> purchaseTicket({
    String? productCode,
    String originStop = '',
    String destinationStop = '',
  }) async {
    final route = state.selectedRoute;
    if (route == null) return null;
    final code = productCode ?? state.selectedProductCode;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final ticket = await _repo.purchaseTicket(
        routeId: route.id,
        productCode: code,
        originStop: originStop.isNotEmpty ? originStop : state.planOrigin,
        destinationStop:
            destinationStop.isNotEmpty ? destinationStop : state.planDestination,
        idempotencyKey:
            'brt-${route.id}-$code-${DateTime.now().millisecondsSinceEpoch}',
      );
      final tickets = await _repo.myTickets();
      ref.read(walletControllerProvider.notifier).refresh();
      state = state.copyWith(
        activeTicket: ticket,
        myTickets: tickets,
        isBusy: false,
      );
      return ticket;
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
      return null;
    }
  }

  void setActiveTicket(TransitTicket ticket) {
    state = state.copyWith(activeTicket: ticket);
  }

  Future<void> refreshTickets() async {
    try {
      final tickets = await _repo.myTickets();
      state = state.copyWith(myTickets: tickets);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final transitControllerProvider =
    NotifierProvider<TransitController, TransitUiState>(TransitController.new);

class TransitDriverState {
  const TransitDriverState({
    this.runs = const [],
    this.isBusy = false,
    this.error,
  });

  final List<TransitScheduledRun> runs;
  final bool isBusy;
  final String? error;

  TransitDriverState copyWith({
    List<TransitScheduledRun>? runs,
    bool? isBusy,
    String? error,
    bool clearError = false,
  }) {
    return TransitDriverState(
      runs: runs ?? this.runs,
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class TransitDriverController extends Notifier<TransitDriverState> {
  TransitRepository get _repo => ref.read(transitRepositoryProvider);

  @override
  TransitDriverState build() => const TransitDriverState();

  Future<void> loadRuns() async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final runs = await _repo.driverRuns();
      state = state.copyWith(runs: runs, isBusy: false);
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> advanceRun(String runId, String status) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      await _repo.advanceDriverRun(runId, status);
      await loadRuns();
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }
}

final transitDriverControllerProvider =
    NotifierProvider<TransitDriverController, TransitDriverState>(
      TransitDriverController.new,
    );

class TransitLiveMapState {
  const TransitLiveMapState({this.liveMap, this.isBusy = false, this.error});

  final TransitLiveMap? liveMap;
  final bool isBusy;
  final String? error;

  TransitLiveMapState copyWith({
    TransitLiveMap? liveMap,
    bool? isBusy,
    String? error,
    bool clearError = false,
  }) {
    return TransitLiveMapState(
      liveMap: liveMap ?? this.liveMap,
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class TransitLiveMapController extends Notifier<TransitLiveMapState> {
  TransitRepository get _repo => ref.read(transitRepositoryProvider);

  @override
  TransitLiveMapState build() => const TransitLiveMapState();

  Future<void> load({bool silent = false}) async {
    if (!silent) state = state.copyWith(isBusy: true, clearError: true);
    try {
      final map = await _repo.loadLiveMap(region: 'Dar es Salaam');
      state = state.copyWith(liveMap: map, isBusy: false);
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }
}

final transitLiveMapControllerProvider =
    NotifierProvider<TransitLiveMapController, TransitLiveMapState>(
      TransitLiveMapController.new,
    );

class TransitEngagementState {
  const TransitEngagementState({
    this.profileBundle,
    this.notifications = const [],
    this.isBusy = false,
    this.error,
    this.sosSent = false,
  });

  final TransitProfileBundle? profileBundle;
  final List<TransitNotification> notifications;
  final bool isBusy;
  final String? error;
  final bool sosSent;

  int get unreadCount => notifications.where((n) => !n.read).length;

  TransitEngagementState copyWith({
    TransitProfileBundle? profileBundle,
    List<TransitNotification>? notifications,
    bool? isBusy,
    String? error,
    bool? sosSent,
    bool clearError = false,
  }) {
    return TransitEngagementState(
      profileBundle: profileBundle ?? this.profileBundle,
      notifications: notifications ?? this.notifications,
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : (error ?? this.error),
      sosSent: sosSent ?? this.sosSent,
    );
  }
}

class TransitEngagementController extends Notifier<TransitEngagementState> {
  TransitRepository get _repo => ref.read(transitRepositoryProvider);

  @override
  TransitEngagementState build() => const TransitEngagementState();

  Future<void> loadProfile() async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final bundle = await _repo.loadProfile();
      state = state.copyWith(profileBundle: bundle, isBusy: false);
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> updateProfile({
    String? homeStop,
    String? workStop,
    String? preferredLanguage,
    Map<String, dynamic>? accessibility,
  }) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final bundle = await _repo.updateProfile(
        homeStop: homeStop,
        workStop: workStop,
        preferredLanguage: preferredLanguage,
        accessibility: accessibility,
      );
      state = state.copyWith(profileBundle: bundle, isBusy: false);
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> addFavorite({
    required String subjectType,
    required String subjectCode,
    String label = '',
  }) async {
    try {
      await _repo.addFavorite(
        subjectType: subjectType,
        subjectCode: subjectCode,
        label: label,
      );
      await loadProfile();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> removeFavorite(String id) async {
    try {
      await _repo.removeFavorite(id);
      await loadProfile();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> loadNotifications() async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final rows = await _repo.listNotifications();
      state = state.copyWith(notifications: rows, isBusy: false);
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> markAllRead() async {
    try {
      await _repo.markNotificationsRead();
      await loadNotifications();
      ref.read(transitControllerProvider.notifier).bootstrap();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<bool> submitFeedback({
    required int rating,
    String comment = '',
    List<String> tags = const [],
    String? routeId,
    String? ticketId,
  }) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      await _repo.submitFeedback(
        rating: rating,
        comment: comment,
        tags: tags,
        routeId: routeId,
        ticketId: ticketId,
      );
      state = state.copyWith(isBusy: false);
      return true;
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
      return false;
    }
  }

  Future<bool> sendSos({
    String stopCode = '',
    String? routeId,
    String notes = '',
  }) async {
    state = state.copyWith(isBusy: true, clearError: true, sosSent: false);
    try {
      await _repo.reportSos(
        latitude: kTransitDefaultLat,
        longitude: kTransitDefaultLng,
        stopCode: stopCode,
        routeId: routeId,
        notes: notes,
      );
      state = state.copyWith(isBusy: false, sosSent: true);
      await loadNotifications();
      ref.read(transitControllerProvider.notifier).bootstrap();
      return true;
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
      return false;
    }
  }
}

final transitEngagementControllerProvider =
    NotifierProvider<TransitEngagementController, TransitEngagementState>(
      TransitEngagementController.new,
    );

class TransitAdminState {
  const TransitAdminState({
    this.routes = const [],
    this.products = const [],
    this.analytics,
    this.lostFoundItems = const [],
    this.isBusy = false,
    this.error,
    this.message,
  });

  final List<TransitRoute> routes;
  final List<TransitProduct> products;
  final TransitAnalytics? analytics;
  final List<TransitLostFoundItem> lostFoundItems;
  final bool isBusy;
  final String? error;
  final String? message;

  TransitAdminState copyWith({
    List<TransitRoute>? routes,
    List<TransitProduct>? products,
    TransitAnalytics? analytics,
    List<TransitLostFoundItem>? lostFoundItems,
    bool? isBusy,
    String? error,
    String? message,
    bool clearError = false,
    bool clearMessage = false,
  }) {
    return TransitAdminState(
      routes: routes ?? this.routes,
      products: products ?? this.products,
      analytics: analytics ?? this.analytics,
      lostFoundItems: lostFoundItems ?? this.lostFoundItems,
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : (error ?? this.error),
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}

class TransitAdminController extends Notifier<TransitAdminState> {
  TransitRepository get _repo => ref.read(transitRepositoryProvider);

  @override
  TransitAdminState build() => const TransitAdminState();

  Future<void> bootstrap() async {
    state = state.copyWith(isBusy: true, clearError: true, clearMessage: true);
    try {
      final routes = await _repo.listRoutes(region: 'Dar es Salaam', mode: 'brt');
      final products = await _repo.listProducts(mode: 'brt');
      TransitAnalytics? analytics;
      List<TransitLostFoundItem> lostFound = const [];
      try {
        analytics = await _repo.loadAnalytics();
        lostFound = await _repo.loadAdminLostFound(status: 'open');
      } catch (_) {
        analytics = null;
      }
      state = state.copyWith(
        routes: routes,
        products: products,
        analytics: analytics,
        lostFoundItems: lostFound,
        isBusy: false,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> toggleRouteActive(TransitRoute route, bool active) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      await _repo.adminUpdateRoute(route.id, {'active': active, 'name': route.name});
      await bootstrap();
      state = state.copyWith(message: 'Route updated');
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> createWeeklyPass() async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      await _repo.adminCreateProduct({
        'code': 'brt_weekly_${DateTime.now().millisecondsSinceEpoch}',
        'name': 'BRT Weekly Pass',
        'fare_minor': 12_000_00,
        'ticket_type': 'weekly',
        'validity_hours': 168,
        'max_validations': 20,
      });
      await bootstrap();
      state = state.copyWith(message: 'Weekly pass product created');
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> opsCloseLostFound(String itemId) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      await _repo.opsResolveLostFound(itemId: itemId);
      await bootstrap();
      state = state.copyWith(message: 'Lost & found item closed');
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }
}

final transitAdminControllerProvider =
    NotifierProvider<TransitAdminController, TransitAdminState>(
      TransitAdminController.new,
    );

class TransitAssistantMessage {
  const TransitAssistantMessage({
    required this.text,
    required this.isUser,
    this.reply,
  });

  final String text;
  final bool isUser;
  final TransitAssistantReply? reply;
}

class TransitAssistantState {
  const TransitAssistantState({
    this.messages = const [],
    this.locale = 'sw',
    this.isBusy = false,
    this.error,
  });

  final List<TransitAssistantMessage> messages;
  final String locale;
  final bool isBusy;
  final String? error;

  TransitAssistantState copyWith({
    List<TransitAssistantMessage>? messages,
    String? locale,
    bool? isBusy,
    String? error,
    bool clearError = false,
  }) {
    return TransitAssistantState(
      messages: messages ?? this.messages,
      locale: locale ?? this.locale,
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class TransitAssistantController extends Notifier<TransitAssistantState> {
  TransitRepository get _repo => ref.read(transitRepositoryProvider);

  @override
  TransitAssistantState build() => const TransitAssistantState(
        messages: [
          TransitAssistantMessage(
            text: 'Habari! Mimi ni msaidizi wa Mwendokasi. Uliza kuhusu safari, stesheni, au bei.',
            isUser: false,
          ),
        ],
      );

  void setLocale(String locale) {
    state = state.copyWith(locale: locale);
  }

  Future<void> ask(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty || state.isBusy) return;
    state = state.copyWith(
      isBusy: true,
      clearError: true,
      messages: [
        ...state.messages,
        TransitAssistantMessage(text: trimmed, isUser: true),
      ],
    );
    try {
      final reply = await _repo.askAssistant(
        query: trimmed,
        locale: state.locale,
      );
      state = state.copyWith(
        isBusy: false,
        messages: [
          ...state.messages,
          TransitAssistantMessage(text: reply.reply, isUser: false, reply: reply),
        ],
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }
}

final transitAssistantControllerProvider =
    NotifierProvider<TransitAssistantController, TransitAssistantState>(
      TransitAssistantController.new,
    );

class TransitFamilyState {
  const TransitFamilyState({
    this.bundle,
    this.products = const [],
    this.defaultRouteId = '',
    this.isBusy = false,
    this.error,
    this.message,
  });

  final TransitFamilyBundle? bundle;
  final List<TransitProduct> products;
  final String defaultRouteId;
  final bool isBusy;
  final String? error;
  final String? message;

  TransitFamilyState copyWith({
    TransitFamilyBundle? bundle,
    List<TransitProduct>? products,
    String? defaultRouteId,
    bool? isBusy,
    String? error,
    String? message,
    bool clearError = false,
    bool clearMessage = false,
  }) {
    return TransitFamilyState(
      bundle: bundle ?? this.bundle,
      products: products ?? this.products,
      defaultRouteId: defaultRouteId ?? this.defaultRouteId,
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : (error ?? this.error),
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}

class TransitFamilyController extends Notifier<TransitFamilyState> {
  TransitRepository get _repo => ref.read(transitRepositoryProvider);

  @override
  TransitFamilyState build() => const TransitFamilyState();

  Future<void> load() async {
    state = state.copyWith(isBusy: true, clearError: true, clearMessage: true);
    try {
      final bundle = await _repo.loadFamilyBundle();
      final products = await _repo.listProducts(mode: 'brt');
      final routes = await _repo.listRoutes(mode: 'brt');
      state = state.copyWith(
        bundle: bundle,
        products: products,
        defaultRouteId: routes.isNotEmpty ? routes.first.id : '',
        isBusy: false,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<bool> addMember({
    required String memberOwner,
    required String displayName,
    String relationship = 'child',
    int monthlyLimitMinor = 0,
  }) async {
    state = state.copyWith(isBusy: true, clearError: true, clearMessage: true);
    try {
      await _repo.addFamilyMember(
        memberOwner: memberOwner,
        displayName: displayName,
        relationship: relationship,
        monthlyLimitMinor: monthlyLimitMinor,
      );
      await load();
      state = state.copyWith(
        isBusy: false,
        message: 'Family member linked',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
      return false;
    }
  }

  Future<bool> removeMember(String memberId) async {
    state = state.copyWith(isBusy: true, clearError: true, clearMessage: true);
    try {
      await _repo.removeFamilyMember(memberId);
      await load();
      state = state.copyWith(
        isBusy: false,
        message: 'Member removed',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
      return false;
    }
  }

  Future<TransitTicket?> purchaseForMember({
    required TransitFamilyMember member,
    required String routeId,
    required String productCode,
    String originStop = '',
    String destinationStop = '',
  }) async {
    state = state.copyWith(isBusy: true, clearError: true, clearMessage: true);
    try {
      final ticket = await _repo.purchaseTicketForMember(
        routeId: routeId,
        productCode: productCode,
        beneficiaryOwner: member.memberOwner,
        originStop: originStop,
        destinationStop: destinationStop,
        idempotencyKey:
            'brt-family-${member.id}-$productCode-${DateTime.now().millisecondsSinceEpoch}',
      );
      ref.read(walletControllerProvider.notifier).refresh();
      await load();
      state = state.copyWith(
        isBusy: false,
        message: 'Ticket purchased for ${member.displayName}',
      );
      return ticket;
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
      return null;
    }
  }
}

final transitFamilyControllerProvider =
    NotifierProvider<TransitFamilyController, TransitFamilyState>(
      TransitFamilyController.new,
    );

class TransitLostFoundState {
  const TransitLostFoundState({
    this.bundle,
    this.filterKind = '',
    this.filterStop = '',
    this.isBusy = false,
    this.error,
    this.message,
  });

  final TransitLostFoundBundle? bundle;
  final String filterKind;
  final String filterStop;
  final bool isBusy;
  final String? error;
  final String? message;

  TransitLostFoundState copyWith({
    TransitLostFoundBundle? bundle,
    String? filterKind,
    String? filterStop,
    bool? isBusy,
    String? error,
    String? message,
    bool clearError = false,
    bool clearMessage = false,
  }) {
    return TransitLostFoundState(
      bundle: bundle ?? this.bundle,
      filterKind: filterKind ?? this.filterKind,
      filterStop: filterStop ?? this.filterStop,
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : (error ?? this.error),
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}

class TransitLostFoundController extends Notifier<TransitLostFoundState> {
  TransitRepository get _repo => ref.read(transitRepositoryProvider);

  @override
  TransitLostFoundState build() => const TransitLostFoundState();

  Future<void> load({String? kind, String? stopCode}) async {
    final nextKind = kind ?? state.filterKind;
    final nextStop = stopCode ?? state.filterStop;
    state = state.copyWith(
      isBusy: true,
      clearError: true,
      clearMessage: true,
      filterKind: nextKind,
      filterStop: nextStop,
    );
    try {
      final bundle = await _repo.loadLostFoundBundle(
        kind: nextKind,
        stopCode: nextStop,
      );
      state = state.copyWith(bundle: bundle, isBusy: false);
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<String> uploadPhoto(List<int> bytes, {String contentType = 'image/jpeg'}) async {
    try {
      return await _repo.uploadLostFoundPhoto(bytes: bytes, contentType: contentType);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return '';
    }
  }

  Future<bool> report({
    required String kind,
    required String title,
    String description = '',
    String category = 'other',
    String stopCode = '',
    String contactHint = '',
    String photoUrl = '',
  }) async {
    state = state.copyWith(isBusy: true, clearError: true, clearMessage: true);
    try {
      await _repo.reportLostFound(
        kind: kind,
        title: title,
        description: description,
        category: category,
        stopCode: stopCode,
        contactHint: contactHint,
        photoUrl: photoUrl,
      );
      await load();
      state = state.copyWith(
        isBusy: false,
        message: kind == 'lost' ? 'Lost report submitted' : 'Found item reported',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
      return false;
    }
  }

  Future<bool> claim(String itemId, {String message = ''}) async {
    state = state.copyWith(isBusy: true, clearError: true, clearMessage: true);
    try {
      await _repo.claimLostFound(itemId: itemId, message: message);
      await load();
      state = state.copyWith(isBusy: false, message: 'Claim submitted');
      return true;
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
      return false;
    }
  }

  Future<bool> resolve(String itemId, {String status = 'matched'}) async {
    state = state.copyWith(isBusy: true, clearError: true, clearMessage: true);
    try {
      await _repo.resolveLostFound(itemId: itemId, status: status);
      await load();
      state = state.copyWith(isBusy: false, message: 'Item marked as $status');
      return true;
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
      return false;
    }
  }
}

final transitLostFoundControllerProvider =
    NotifierProvider<TransitLostFoundController, TransitLostFoundState>(
      TransitLostFoundController.new,
    );

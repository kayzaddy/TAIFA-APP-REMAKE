import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/winga/rest_brokerage_repository.dart';
import '../../wallet/application/wallet_providers.dart'
    show apiClientProvider, apiConfigProvider;
import '../domain/brokerage_models.dart';
import 'brokerage_repository.dart';
import 'seed_brokerage_repository.dart';

final brokerageRepositoryProvider = Provider<BrokerageRepository>((ref) {
  final config = ref.watch(apiConfigProvider);
  if (config.useRemoteBackend) {
    return RestBrokerageRepository(ref.watch(apiClientProvider));
  }
  return SeedBrokerageRepository();
});

class WingaActorRoleNotifier extends Notifier<WingaActorRole?> {
  @override
  WingaActorRole? build() => null;

  void setRole(WingaActorRole? role) => state = role;
}

final wingaActorRoleProvider =
    NotifierProvider<WingaActorRoleNotifier, WingaActorRole?>(
  WingaActorRoleNotifier.new,
);

class BrokerageHomeState {
  const BrokerageHomeState({
    this.domains = const [],
    this.offerings = const [],
    this.wingas = const [],
    this.providers = const [],
    this.deals = const [],
    this.leads = const [],
    this.commissions = const [],
    this.favorites = const {},
    this.analytics,
    this.query = '',
    this.selectedDomainCode,
    this.assistTips = const [],
    this.isBusy = false,
    this.error,
  });

  final List<BrokerageDomain> domains;
  final List<WingaOffering> offerings;
  final List<WingaBrokerProfile> wingas;
  final List<WingaProviderProfile> providers;
  final List<WingaDeal> deals;
  final List<WingaLead> leads;
  final List<WingaCommissionEvent> commissions;
  final Set<String> favorites;
  final WingaAnalyticsSummary? analytics;
  final String query;
  final String? selectedDomainCode;
  final List<String> assistTips;
  final bool isBusy;
  final String? error;

  int get pendingCommissionMinor => commissions
      .where((c) => c.isPending)
      .fold<int>(0, (a, c) => a + c.commissionMinor);

  int get settledCommissionMinor => commissions
      .where((c) => c.isSettled)
      .fold<int>(0, (a, c) => a + c.commissionMinor);

  BrokerageHomeState copyWith({
    List<BrokerageDomain>? domains,
    List<WingaOffering>? offerings,
    List<WingaBrokerProfile>? wingas,
    List<WingaProviderProfile>? providers,
    List<WingaDeal>? deals,
    List<WingaLead>? leads,
    List<WingaCommissionEvent>? commissions,
    Set<String>? favorites,
    WingaAnalyticsSummary? analytics,
    String? query,
    String? selectedDomainCode,
    List<String>? assistTips,
    bool? isBusy,
    String? error,
    bool clearError = false,
  }) {
    return BrokerageHomeState(
      domains: domains ?? this.domains,
      offerings: offerings ?? this.offerings,
      wingas: wingas ?? this.wingas,
      providers: providers ?? this.providers,
      deals: deals ?? this.deals,
      leads: leads ?? this.leads,
      commissions: commissions ?? this.commissions,
      favorites: favorites ?? this.favorites,
      analytics: analytics ?? this.analytics,
      query: query ?? this.query,
      selectedDomainCode: selectedDomainCode ?? this.selectedDomainCode,
      assistTips: assistTips ?? this.assistTips,
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class BrokerageController extends Notifier<BrokerageHomeState> {
  @override
  BrokerageHomeState build() => const BrokerageHomeState();

  BrokerageRepository get _repo => ref.read(brokerageRepositoryProvider);

  Future<void> bootstrap({String dealsRole = 'customer'}) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final domains = await _repo.domains();
      final offerings = await _repo.offerings(domainCode: state.selectedDomainCode);
      final wingas = await _repo.wingas();
      final providers = await _repo.providers();
      final deals = await _repo.deals(role: dealsRole);
      final leads = await _repo.leads();
      final commissions = await _repo.commissionEvents();
      final favs = await _repo.favoriteOfferingIds();
      final analytics = await _repo.analytics();
      state = state.copyWith(
        domains: domains,
        offerings: offerings,
        wingas: wingas,
        providers: providers,
        deals: deals,
        leads: leads,
        commissions: commissions,
        favorites: favs.toSet(),
        analytics: analytics,
        isBusy: false,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: '$e');
    }
  }

  Future<void> search(String query) async {
    state = state.copyWith(query: query, isBusy: true, clearError: true);
    try {
      final offerings = await _repo.offerings(
        domainCode: state.selectedDomainCode,
        query: query,
      );
      state = state.copyWith(offerings: offerings, isBusy: false);
    } catch (e) {
      state = state.copyWith(isBusy: false, error: '$e');
    }
  }

  Future<void> filterDomain(String? code) async {
    state = state.copyWith(selectedDomainCode: code, isBusy: true);
    try {
      final offerings = await _repo.offerings(
        domainCode: code,
        query: state.query,
      );
      state = state.copyWith(offerings: offerings, isBusy: false);
    } catch (e) {
      state = state.copyWith(isBusy: false, error: '$e');
    }
  }

  Future<void> toggleFavorite(String offeringId) async {
    await _repo.favoriteOffering(offeringId);
    final next = {...state.favorites, offeringId};
    state = state.copyWith(favorites: next);
  }

  Future<WingaDeal?> requestDeal({
    required WingaOffering offering,
    required String customerPrincipal,
  }) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final winga = state.wingas.isNotEmpty
          ? state.wingas.first
          : await _repo.registerWinga(displayName: 'Taifa Winga');
      final deal = await _repo.openDeal(
        wingaId: winga.id,
        providerId: offering.providerId,
        domainId: offering.domainId,
        customerPrincipal: customerPrincipal,
        amountMinor: offering.priceMinor,
        currency: offering.currency,
        offeringId: offering.id,
        booking: {'source': 'customer_app'},
      );
      state = state.copyWith(
        deals: [deal, ...state.deals],
        wingas: state.wingas.contains(winga) ? state.wingas : [winga, ...state.wingas],
        isBusy: false,
      );
      return deal;
    } catch (e) {
      state = state.copyWith(isBusy: false, error: '$e');
      return null;
    }
  }

  Future<WingaDeal?> payDeal(String dealId) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final paid = await _repo.payDeal(
        dealId,
        idempotencyKey: 'winga-pay-$dealId-${DateTime.now().millisecondsSinceEpoch}',
      );
      final deals = state.deals.map((d) => d.id == dealId ? paid : d).toList();
      final commissions = await _repo.commissionEvents();
      state = state.copyWith(deals: deals, commissions: commissions, isBusy: false);
      return paid;
    } catch (e) {
      state = state.copyWith(isBusy: false, error: '$e');
      return null;
    }
  }

  Future<void> createLead({
    required String title,
    required String domainId,
    required String customerPrincipal,
    String notes = '',
  }) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final winga = state.wingas.isNotEmpty
          ? state.wingas.first
          : await _repo.registerWinga(displayName: 'My Winga Desk');
      final lead = await _repo.createLead(
        wingaId: winga.id,
        domainId: domainId,
        title: title,
        customerPrincipal: customerPrincipal,
        notes: notes,
      );
      state = state.copyWith(
        leads: [lead, ...state.leads],
        wingas: state.wingas.contains(winga) ? state.wingas : [winga, ...state.wingas],
        isBusy: false,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: '$e');
    }
  }

  Future<void> settleDealCommission(String dealId) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      await _repo.settleCommission(dealId);
      final commissions = await _repo.commissionEvents();
      state = state.copyWith(commissions: commissions, isBusy: false);
    } catch (e) {
      state = state.copyWith(isBusy: false, error: '$e');
    }
  }

  Future<void> runAssist(String capability) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final result = await _repo.assist(capability: capability);
      if (result.paymentAuthorized) {
        throw StateError('Refusing payment-authorized AI response');
      }
      final tips = (result.result['suggestions'] as List?)
              ?.map((e) => '$e')
              .toList() ??
          ['No tips right now'];
      state = state.copyWith(assistTips: tips, isBusy: false);
    } catch (e) {
      state = state.copyWith(isBusy: false, error: '$e');
    }
  }
}

final brokerageControllerProvider =
    NotifierProvider<BrokerageController, BrokerageHomeState>(
  BrokerageController.new,
);

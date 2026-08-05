import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/housing/rest_housing_repository.dart';
import '../../wallet/application/wallet_providers.dart'
    show apiClientProvider, apiConfigProvider;
import '../domain/housing_models.dart';
import 'housing_repository.dart';

/// Seed offline, or live inquiries when `TAIFA_USE_REMOTE=true`.
final housingRepositoryProvider = Provider<HousingRepository>((ref) {
  final config = ref.watch(apiConfigProvider);
  if (config.useRemoteBackend) {
    return RestHousingRepository(ref.watch(apiClientProvider));
  }
  return SeedHousingRepository();
});

enum HousingPhase { home, detail, scheduled, receipt, history }

class HousingUiState {
  const HousingUiState({
    this.phase = HousingPhase.home,
    this.listings = const [],
    this.query = '',
    this.selected,
    this.inquiry,
    this.history = const [],
    this.isBusy = false,
    this.error,
  });

  final HousingPhase phase;
  final List<HousingListing> listings;
  final String query;
  final HousingListing? selected;
  final HousingInquiry? inquiry;
  final List<HousingInquiry> history;
  final bool isBusy;
  final String? error;

  HousingUiState copyWith({
    HousingPhase? phase,
    List<HousingListing>? listings,
    String? query,
    HousingListing? selected,
    HousingInquiry? inquiry,
    List<HousingInquiry>? history,
    bool? isBusy,
    String? error,
    bool clearSelected = false,
    bool clearInquiry = false,
    bool clearError = false,
  }) {
    return HousingUiState(
      phase: phase ?? this.phase,
      listings: listings ?? this.listings,
      query: query ?? this.query,
      selected: clearSelected ? null : (selected ?? this.selected),
      inquiry: clearInquiry ? null : (inquiry ?? this.inquiry),
      history: history ?? this.history,
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class HousingController extends Notifier<HousingUiState> {
  HousingRepository get _repo => ref.read(housingRepositoryProvider);

  @override
  HousingUiState build() => const HousingUiState();

  Future<void> bootstrap() async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final list = await _repo.list();
      final history = await _repo.history();
      state = state.copyWith(
        listings: list,
        history: history,
        isBusy: false,
        phase: HousingPhase.home,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> search(String q) async {
    state = state.copyWith(query: q, isBusy: true, clearError: true);
    state = state.copyWith(listings: await _repo.list(query: q), isBusy: false);
  }

  void open(HousingListing l) => state = state.copyWith(
    selected: l,
    phase: HousingPhase.detail,
    clearInquiry: true,
    clearError: true,
  );

  void backHome() => state = state.copyWith(
    phase: HousingPhase.home,
    clearSelected: true,
    clearInquiry: true,
    clearError: true,
  );

  Future<void> requestViewing() async {
    final l = state.selected;
    if (l == null) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final draft = HousingInquiry(
        id: 'draft',
        listing: l,
        status: HousingInquiryStatus.drafting,
        createdAt: DateTime.now(),
      );
      final inquiry = await _repo.inquire(draft);
      state = state.copyWith(
        inquiry: inquiry,
        isBusy: false,
        phase: HousingPhase.scheduled,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> payDeposit() async {
    final inquiry = state.inquiry;
    if (inquiry == null) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final paid = await _repo.payDeposit(inquiry.id);
      state = state.copyWith(
        inquiry: paid,
        history: await _repo.history(),
        isBusy: false,
        phase: HousingPhase.receipt,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  void openHistory() => state = state.copyWith(phase: HousingPhase.history);
}

final housingControllerProvider =
    NotifierProvider<HousingController, HousingUiState>(HousingController.new);

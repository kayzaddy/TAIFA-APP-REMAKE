import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/gov/rest_gov_request_repository.dart';
import '../../wallet/application/wallet_providers.dart'
    show apiClientProvider, apiConfigProvider;
import '../domain/gov_models.dart';
import 'gov_repository.dart';

final govServiceRepositoryProvider = Provider<GovServiceRepository>(
  (ref) => SeedGovServiceRepository(),
);

/// Seed offline, or live commerce API when `TAIFA_USE_REMOTE=true`.
final govRequestRepositoryProvider = Provider<GovRequestRepository>((ref) {
  final config = ref.watch(apiConfigProvider);
  if (config.useRemoteBackend) {
    return RestGovRequestRepository(ref.watch(apiClientProvider));
  }
  return SeedGovRequestRepository();
});

enum GovPhase { home, detail, confirm, tracking, receipt, history }

class GovUiState {
  const GovUiState({
    this.phase = GovPhase.home,
    this.services = const [],
    this.query = '',
    this.selected,
    this.applicantName = 'Amani Juma',
    this.request,
    this.history = const [],
    this.isBusy = false,
    this.error,
  });

  final GovPhase phase;
  final List<GovService> services;
  final String query;
  final GovService? selected;
  final String applicantName;
  final GovRequest? request;
  final List<GovRequest> history;
  final bool isBusy;
  final String? error;

  GovUiState copyWith({
    GovPhase? phase,
    List<GovService>? services,
    String? query,
    GovService? selected,
    String? applicantName,
    GovRequest? request,
    List<GovRequest>? history,
    bool? isBusy,
    String? error,
    bool clearSelected = false,
    bool clearRequest = false,
    bool clearError = false,
  }) {
    return GovUiState(
      phase: phase ?? this.phase,
      services: services ?? this.services,
      query: query ?? this.query,
      selected: clearSelected ? null : (selected ?? this.selected),
      applicantName: applicantName ?? this.applicantName,
      request: clearRequest ? null : (request ?? this.request),
      history: history ?? this.history,
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class GovController extends Notifier<GovUiState> {
  GovServiceRepository get _services => ref.read(govServiceRepositoryProvider);
  GovRequestRepository get _requests => ref.read(govRequestRepositoryProvider);

  @override
  GovUiState build() => const GovUiState();

  Future<void> bootstrap() async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final list = await _services.list();
      final history = await _requests.history();
      state = state.copyWith(
        services: list,
        history: history,
        isBusy: false,
        phase: GovPhase.home,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> search(String q) async {
    state = state.copyWith(query: q, isBusy: true, clearError: true);
    state = state.copyWith(
      services: await _services.list(query: q),
      isBusy: false,
    );
  }

  void open(GovService s) => state = state.copyWith(
    selected: s,
    phase: GovPhase.detail,
    clearRequest: true,
    clearError: true,
  );

  void backHome() => state = state.copyWith(
    phase: GovPhase.home,
    clearSelected: true,
    clearRequest: true,
    clearError: true,
  );

  void goConfirm() {
    if (state.selected == null) return;
    state = state.copyWith(phase: GovPhase.confirm, clearError: true);
  }

  void setApplicant(String name) => state = state.copyWith(applicantName: name);

  Future<void> submit() async {
    final s = state.selected;
    if (s == null) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final draft = GovRequest(
        id: 'draft',
        service: s,
        status: GovRequestStatus.drafting,
        createdAt: DateTime.now(),
        applicantName: state.applicantName.trim().isEmpty
            ? 'Amani Juma'
            : state.applicantName.trim(),
      );
      final req = await _requests.submit(draft);
      state = state.copyWith(
        request: req,
        isBusy: false,
        phase: GovPhase.tracking,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> pay() async {
    final req = state.request;
    if (req == null) return;
    if (req.service.fee.minorUnits <= 0) {
      state = state.copyWith(
        request: req.copyWith(status: GovRequestStatus.approved),
        phase: GovPhase.receipt,
        history: await _requests.history(),
      );
      return;
    }
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final paid = await _requests.pay(req.id);
      state = state.copyWith(
        request: paid,
        history: await _requests.history(),
        isBusy: false,
        phase: GovPhase.receipt,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  void openHistory() => state = state.copyWith(phase: GovPhase.history);
}

final govControllerProvider = NotifierProvider<GovController, GovUiState>(
  GovController.new,
);

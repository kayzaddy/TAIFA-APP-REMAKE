import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../wallet/application/wallet_providers.dart'
    show apiClientProvider, apiConfigProvider;
import '../domain/ops_models.dart';
import 'ops_repository.dart';
import 'rest_ops_repository.dart';

final opsRepositoryProvider = Provider<OpsRepository>((ref) {
  final config = ref.watch(apiConfigProvider);
  if (config.useRemoteBackend) {
    return RestOpsRepository(ref.watch(apiClientProvider));
  }
  return SeedOpsRepository();
});

enum OpsPhase { dashboard, detail }

class OpsUiState {
  const OpsUiState({
    this.phase = OpsPhase.dashboard,
    this.incidents = const [],
    this.stats,
    this.selected,
    this.isBusy = false,
    this.error,
  });

  final OpsPhase phase;
  final List<OpsIncident> incidents;
  final OpsStats? stats;
  final OpsIncident? selected;
  final bool isBusy;
  final String? error;

  OpsUiState copyWith({
    OpsPhase? phase,
    List<OpsIncident>? incidents,
    OpsStats? stats,
    OpsIncident? selected,
    bool? isBusy,
    String? error,
    bool clearSelected = false,
    bool clearError = false,
  }) {
    return OpsUiState(
      phase: phase ?? this.phase,
      incidents: incidents ?? this.incidents,
      stats: stats ?? this.stats,
      selected: clearSelected ? null : (selected ?? this.selected),
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class OpsController extends Notifier<OpsUiState> {
  OpsRepository get _repo => ref.read(opsRepositoryProvider);

  @override
  OpsUiState build() => const OpsUiState(isBusy: true);

  Future<void> bootstrap() async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final incidents = await _repo.listIncidents();
      final stats = await _repo.stats();
      state = state.copyWith(
        incidents: incidents,
        stats: stats,
        isBusy: false,
        phase: OpsPhase.dashboard,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  void open(OpsIncident i) => state = state.copyWith(
    selected: i,
    phase: OpsPhase.detail,
    clearError: true,
  );

  void back() =>
      state = state.copyWith(phase: OpsPhase.dashboard, clearSelected: true);

  Future<void> advanceSelected() async {
    final i = state.selected;
    if (i == null) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final updated = await _repo.advance(i.id);
      final incidents = await _repo.listIncidents();
      final stats = await _repo.stats();
      state = state.copyWith(
        selected: updated,
        incidents: incidents,
        stats: stats,
        isBusy: false,
        phase: updated.status == OpsIncidentStatus.resolved
            ? OpsPhase.dashboard
            : OpsPhase.detail,
        clearSelected: updated.status == OpsIncidentStatus.resolved,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }
}

final opsControllerProvider = NotifierProvider<OpsController, OpsUiState>(
  OpsController.new,
);

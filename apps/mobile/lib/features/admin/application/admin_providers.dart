import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/admin/rest_admin_repository.dart';
import '../../wallet/application/wallet_providers.dart'
    show apiClientProvider, apiConfigProvider;
import '../domain/admin_models.dart';
import 'admin_repository.dart';

/// Seed offline, or live ops queue when `TAIFA_USE_REMOTE=true`.
final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final config = ref.watch(apiConfigProvider);
  if (config.useRemoteBackend) {
    return RestAdminRepository(ref.watch(apiClientProvider));
  }
  return SeedAdminRepository();
});

enum AdminPhase { dashboard, detail }

class AdminUiState {
  const AdminUiState({
    this.phase = AdminPhase.dashboard,
    this.cases = const [],
    this.stats,
    this.selected,
    this.isBusy = false,
    this.error,
  });

  final AdminPhase phase;
  final List<AdminCase> cases;
  final AdminStats? stats;
  final AdminCase? selected;
  final bool isBusy;
  final String? error;

  AdminUiState copyWith({
    AdminPhase? phase,
    List<AdminCase>? cases,
    AdminStats? stats,
    AdminCase? selected,
    bool? isBusy,
    String? error,
    bool clearSelected = false,
    bool clearError = false,
  }) {
    return AdminUiState(
      phase: phase ?? this.phase,
      cases: cases ?? this.cases,
      stats: stats ?? this.stats,
      selected: clearSelected ? null : (selected ?? this.selected),
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AdminController extends Notifier<AdminUiState> {
  AdminRepository get _repo => ref.read(adminRepositoryProvider);

  @override
  AdminUiState build() => const AdminUiState(isBusy: true);

  Future<void> bootstrap() async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final cases = await _repo.listCases();
      final stats = await _repo.stats();
      state = state.copyWith(
        cases: cases,
        stats: stats,
        isBusy: false,
        phase: AdminPhase.dashboard,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  void open(AdminCase c) => state = state.copyWith(
    selected: c,
    phase: AdminPhase.detail,
    clearError: true,
  );

  void back() =>
      state = state.copyWith(phase: AdminPhase.dashboard, clearSelected: true);

  Future<void> advanceSelected() async {
    final c = state.selected;
    if (c == null) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final updated = await _repo.advance(c.id);
      final cases = await _repo.listCases();
      final stats = await _repo.stats();
      state = state.copyWith(
        selected: updated,
        cases: cases,
        stats: stats,
        isBusy: false,
        phase: updated.status == AdminCaseStatus.resolved
            ? AdminPhase.dashboard
            : AdminPhase.detail,
        clearSelected: updated.status == AdminCaseStatus.resolved,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }
}

final adminControllerProvider = NotifierProvider<AdminController, AdminUiState>(
  AdminController.new,
);

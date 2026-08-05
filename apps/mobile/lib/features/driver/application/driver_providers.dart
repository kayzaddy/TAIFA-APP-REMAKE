import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/driver/rest_driver_repository.dart';
import '../../wallet/application/wallet_providers.dart'
    show apiClientProvider, apiConfigProvider;
import '../../wallet/domain/money.dart';
import '../domain/driver_models.dart';
import 'driver_repository.dart';

/// Seed offline, or live offers when `TAIFA_USE_REMOTE=true`.
final driverRepositoryProvider = Provider<DriverRepository>((ref) {
  final config = ref.watch(apiConfigProvider);
  if (config.useRemoteBackend) {
    return RestDriverRepository(ref.watch(apiClientProvider));
  }
  return SeedDriverRepository();
});

enum DriverPhase { home, job }

class DriverUiState {
  const DriverUiState({
    this.phase = DriverPhase.home,
    this.online = true,
    this.jobs = const [],
    this.active,
    this.earnings,
    this.isBusy = false,
    this.error,
  });

  final DriverPhase phase;
  final bool online;
  final List<DriverJob> jobs;
  final DriverJob? active;
  final Money? earnings;
  final bool isBusy;
  final String? error;

  DriverUiState copyWith({
    DriverPhase? phase,
    bool? online,
    List<DriverJob>? jobs,
    DriverJob? active,
    Money? earnings,
    bool? isBusy,
    String? error,
    bool clearActive = false,
    bool clearError = false,
  }) {
    return DriverUiState(
      phase: phase ?? this.phase,
      online: online ?? this.online,
      jobs: jobs ?? this.jobs,
      active: clearActive ? null : (active ?? this.active),
      earnings: earnings ?? this.earnings,
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class DriverController extends Notifier<DriverUiState> {
  DriverRepository get _repo => ref.read(driverRepositoryProvider);

  @override
  DriverUiState build() => const DriverUiState(isBusy: true);

  Future<void> bootstrap() async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final jobs = await _repo.offers();
      final earnings = await _repo.todayEarnings();
      state = state.copyWith(
        jobs: jobs,
        earnings: earnings,
        isBusy: false,
        phase: DriverPhase.home,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  void setOnline(bool v) => state = state.copyWith(online: v);

  void open(DriverJob job) => state = state.copyWith(
    active: job,
    phase: DriverPhase.job,
    clearError: true,
  );

  void backHome() =>
      state = state.copyWith(phase: DriverPhase.home, clearActive: true);

  Future<void> accept() async {
    final job = state.active;
    if (job == null) return;
    await _setStatus(job.copyWith(status: DriverJobStatus.accepted));
  }

  Future<void> decline() async {
    final job = state.active;
    if (job == null) return;
    state = state.copyWith(isBusy: true);
    await _repo.update(job.copyWith(status: DriverJobStatus.declined));
    final jobs = await _repo.offers();
    state = state.copyWith(
      jobs: jobs,
      isBusy: false,
      phase: DriverPhase.home,
      clearActive: true,
    );
  }

  Future<void> advance() async {
    final job = state.active;
    if (job == null) return;
    final next = switch (job.status) {
      DriverJobStatus.accepted => DriverJobStatus.enRoute,
      DriverJobStatus.enRoute => DriverJobStatus.arrived,
      DriverJobStatus.arrived => DriverJobStatus.inTrip,
      DriverJobStatus.inTrip => DriverJobStatus.completed,
      _ => job.status,
    };
    await _setStatus(job.copyWith(status: next));
    if (next == DriverJobStatus.completed) {
      final jobs = await _repo.offers();
      final earnings = await _repo.todayEarnings();
      state = state.copyWith(
        jobs: jobs,
        earnings: earnings,
        phase: DriverPhase.home,
        clearActive: true,
      );
    }
  }

  Future<void> _setStatus(DriverJob job) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final updated = await _repo.update(job);
      final jobs = await _repo.offers();
      state = state.copyWith(active: updated, jobs: jobs, isBusy: false);
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }
}

final driverControllerProvider =
    NotifierProvider<DriverController, DriverUiState>(DriverController.new);

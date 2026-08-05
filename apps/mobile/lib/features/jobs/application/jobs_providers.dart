import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/jobs/rest_jobs_repository.dart';
import '../../wallet/application/wallet_providers.dart'
    show apiClientProvider, apiConfigProvider;
import '../domain/jobs_models.dart';
import 'jobs_repository.dart';

/// Seed offline, or live assignments when `TAIFA_USE_REMOTE=true`.
final jobsRepositoryProvider = Provider<JobsRepository>((ref) {
  final config = ref.watch(apiConfigProvider);
  if (config.useRemoteBackend) {
    return RestJobsRepository(ref.watch(apiClientProvider));
  }
  return SeedJobsRepository();
});

enum JobsPhase { home, detail, active, receipt, history }

class JobsUiState {
  const JobsUiState({
    this.phase = JobsPhase.home,
    this.jobs = const [],
    this.query = '',
    this.selected,
    this.assignment,
    this.history = const [],
    this.isBusy = false,
    this.error,
  });

  final JobsPhase phase;
  final List<JobListing> jobs;
  final String query;
  final JobListing? selected;
  final JobAssignment? assignment;
  final List<JobAssignment> history;
  final bool isBusy;
  final String? error;

  JobsUiState copyWith({
    JobsPhase? phase,
    List<JobListing>? jobs,
    String? query,
    JobListing? selected,
    JobAssignment? assignment,
    List<JobAssignment>? history,
    bool? isBusy,
    String? error,
    bool clearSelected = false,
    bool clearAssignment = false,
    bool clearError = false,
  }) {
    return JobsUiState(
      phase: phase ?? this.phase,
      jobs: jobs ?? this.jobs,
      query: query ?? this.query,
      selected: clearSelected ? null : (selected ?? this.selected),
      assignment: clearAssignment ? null : (assignment ?? this.assignment),
      history: history ?? this.history,
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class JobsController extends Notifier<JobsUiState> {
  JobsRepository get _repo => ref.read(jobsRepositoryProvider);

  @override
  JobsUiState build() => const JobsUiState();

  Future<void> bootstrap() async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final jobs = await _repo.list();
      final history = await _repo.history();
      state = state.copyWith(
        jobs: jobs,
        history: history,
        isBusy: false,
        phase: JobsPhase.home,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> search(String q) async {
    state = state.copyWith(query: q, isBusy: true, clearError: true);
    state = state.copyWith(jobs: await _repo.list(query: q), isBusy: false);
  }

  void open(JobListing j) => state = state.copyWith(
    selected: j,
    phase: JobsPhase.detail,
    clearAssignment: true,
    clearError: true,
  );

  void backHome() => state = state.copyWith(
    phase: JobsPhase.home,
    clearSelected: true,
    clearAssignment: true,
    clearError: true,
  );

  Future<void> accept() async {
    final j = state.selected;
    if (j == null) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final a = await _repo.accept(j);
      state = state.copyWith(
        assignment: a,
        isBusy: false,
        phase: JobsPhase.active,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> advance() async {
    final a = state.assignment;
    if (a == null) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final next = await _repo.advance(a.id);
      if (next.status == JobAssignmentStatus.paid) {
        state = state.copyWith(
          assignment: next,
          history: await _repo.history(),
          isBusy: false,
          phase: JobsPhase.receipt,
        );
      } else {
        state = state.copyWith(assignment: next, isBusy: false);
      }
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  void openHistory() => state = state.copyWith(phase: JobsPhase.history);
}

final jobsControllerProvider = NotifierProvider<JobsController, JobsUiState>(
  JobsController.new,
);

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/insurance/rest_insurance_repository.dart';
import '../../wallet/application/wallet_providers.dart'
    show apiClientProvider, apiConfigProvider;
import '../domain/insurance_models.dart';
import 'insurance_repository.dart';

/// Seed offline, or live policies when `TAIFA_USE_REMOTE=true`.
final insuranceRepositoryProvider = Provider<InsuranceRepository>((ref) {
  final config = ref.watch(apiConfigProvider);
  if (config.useRemoteBackend) {
    return RestInsuranceRepository(ref.watch(apiClientProvider));
  }
  return SeedInsuranceRepository();
});

enum InsurancePhase { home, detail, confirm, receipt, history }

class InsuranceUiState {
  const InsuranceUiState({
    this.phase = InsurancePhase.home,
    this.plans = const [],
    this.selected,
    this.policy,
    this.history = const [],
    this.isBusy = false,
    this.error,
  });

  final InsurancePhase phase;
  final List<InsurancePlan> plans;
  final InsurancePlan? selected;
  final InsurancePolicy? policy;
  final List<InsurancePolicy> history;
  final bool isBusy;
  final String? error;

  InsuranceUiState copyWith({
    InsurancePhase? phase,
    List<InsurancePlan>? plans,
    InsurancePlan? selected,
    InsurancePolicy? policy,
    List<InsurancePolicy>? history,
    bool? isBusy,
    String? error,
    bool clearSelected = false,
    bool clearPolicy = false,
    bool clearError = false,
  }) {
    return InsuranceUiState(
      phase: phase ?? this.phase,
      plans: plans ?? this.plans,
      selected: clearSelected ? null : (selected ?? this.selected),
      policy: clearPolicy ? null : (policy ?? this.policy),
      history: history ?? this.history,
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class InsuranceController extends Notifier<InsuranceUiState> {
  InsuranceRepository get _repo => ref.read(insuranceRepositoryProvider);

  @override
  InsuranceUiState build() => const InsuranceUiState();

  Future<void> bootstrap() async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final plans = await _repo.listPlans();
      final history = await _repo.history();
      state = state.copyWith(
        plans: plans,
        history: history,
        isBusy: false,
        phase: InsurancePhase.home,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  void open(InsurancePlan plan) => state = state.copyWith(
    selected: plan,
    phase: InsurancePhase.detail,
    clearPolicy: true,
    clearError: true,
  );

  void backHome() => state = state.copyWith(
    phase: InsurancePhase.home,
    clearSelected: true,
    clearPolicy: true,
    clearError: true,
  );

  void goConfirm() {
    if (state.selected == null) return;
    state = state.copyWith(phase: InsurancePhase.confirm, clearError: true);
  }

  Future<void> buy() async {
    final plan = state.selected;
    if (plan == null) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final draft = InsurancePolicy(
        id: 'draft',
        plan: plan,
        status: PolicyStatus.drafting,
        createdAt: DateTime.now(),
      );
      final policy = await _repo.buy(draft);
      state = state.copyWith(
        policy: policy,
        history: await _repo.history(),
        isBusy: false,
        phase: InsurancePhase.receipt,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  void openHistory() => state = state.copyWith(phase: InsurancePhase.history);
}

final insuranceControllerProvider =
    NotifierProvider<InsuranceController, InsuranceUiState>(
      InsuranceController.new,
    );

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/wealth/rest_wealth_repository.dart';
import '../../wallet/application/wallet_providers.dart'
    show apiClientProvider, apiConfigProvider;
import '../../wallet/domain/currency.dart';
import '../../wallet/domain/money.dart';
import '../domain/wealth_models.dart';
import 'wealth_repository.dart';

/// Seed offline, or live contributions when `TAIFA_USE_REMOTE=true`.
final wealthRepositoryProvider = Provider<WealthRepository>((ref) {
  final config = ref.watch(apiConfigProvider);
  if (config.useRemoteBackend) {
    return RestWealthRepository(ref.watch(apiClientProvider));
  }
  return SeedWealthRepository();
});

enum WealthPhase { home, detail, confirm, receipt, history }

class WealthUiState {
  const WealthUiState({
    this.phase = WealthPhase.home,
    this.circles = const [],
    this.selected,
    this.amountMajor = 50000,
    this.contribution,
    this.history = const [],
    this.isBusy = false,
    this.error,
  });

  final WealthPhase phase;
  final List<HarambeeCircle> circles;
  final HarambeeCircle? selected;
  final int amountMajor;
  final WealthContribution? contribution;
  final List<WealthContribution> history;
  final bool isBusy;
  final String? error;

  Money get amount => Money.major(amountMajor, Currency.tzs);

  WealthUiState copyWith({
    WealthPhase? phase,
    List<HarambeeCircle>? circles,
    HarambeeCircle? selected,
    int? amountMajor,
    WealthContribution? contribution,
    List<WealthContribution>? history,
    bool? isBusy,
    String? error,
    bool clearSelected = false,
    bool clearContribution = false,
    bool clearError = false,
  }) {
    return WealthUiState(
      phase: phase ?? this.phase,
      circles: circles ?? this.circles,
      selected: clearSelected ? null : (selected ?? this.selected),
      amountMajor: amountMajor ?? this.amountMajor,
      contribution: clearContribution
          ? null
          : (contribution ?? this.contribution),
      history: history ?? this.history,
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class WealthController extends Notifier<WealthUiState> {
  WealthRepository get _repo => ref.read(wealthRepositoryProvider);

  @override
  WealthUiState build() => const WealthUiState();

  Future<void> bootstrap() async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final circles = await _repo.list();
      final history = await _repo.history();
      state = state.copyWith(
        circles: circles,
        history: history,
        isBusy: false,
        phase: WealthPhase.home,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  void open(HarambeeCircle c) => state = state.copyWith(
    selected: c,
    phase: WealthPhase.detail,
    clearContribution: true,
    clearError: true,
  );

  void backHome() => state = state.copyWith(
    phase: WealthPhase.home,
    clearSelected: true,
    clearContribution: true,
    clearError: true,
  );

  void goConfirm() {
    if (state.selected == null) return;
    state = state.copyWith(phase: WealthPhase.confirm, clearError: true);
  }

  void setAmount(int major) =>
      state = state.copyWith(amountMajor: major.clamp(5000, 5000000));

  Future<void> contribute() async {
    final c = state.selected;
    if (c == null) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final draft = WealthContribution(
        id: 'draft',
        circle: c,
        amount: state.amount,
        status: ContributionStatus.drafting,
        createdAt: DateTime.now(),
      );
      final paid = await _repo.contribute(draft);
      state = state.copyWith(
        contribution: paid,
        circles: await _repo.list(),
        history: await _repo.history(),
        isBusy: false,
        phase: WealthPhase.receipt,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  void openHistory() => state = state.copyWith(phase: WealthPhase.history);
}

final wealthControllerProvider =
    NotifierProvider<WealthController, WealthUiState>(WealthController.new);

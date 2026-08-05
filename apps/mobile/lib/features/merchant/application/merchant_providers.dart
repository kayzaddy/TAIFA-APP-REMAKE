import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/merchant/rest_merchant_repository.dart';
import '../../wallet/application/wallet_providers.dart'
    show apiClientProvider, apiConfigProvider;
import '../domain/merchant_models.dart';
import 'merchant_repository.dart';

/// Seed offline, or live kitchen queue when `TAIFA_USE_REMOTE=true`.
final merchantRepositoryProvider = Provider<MerchantRepository>((ref) {
  final config = ref.watch(apiConfigProvider);
  if (config.useRemoteBackend) {
    return RestMerchantRepository(ref.watch(apiClientProvider));
  }
  return SeedMerchantRepository();
});

enum MerchantPhase { dashboard, detail }

class MerchantUiState {
  const MerchantUiState({
    this.phase = MerchantPhase.dashboard,
    this.orders = const [],
    this.stats,
    this.selected,
    this.isBusy = false,
    this.error,
  });

  final MerchantPhase phase;
  final List<MerchantOrder> orders;
  final MerchantStats? stats;
  final MerchantOrder? selected;
  final bool isBusy;
  final String? error;

  MerchantUiState copyWith({
    MerchantPhase? phase,
    List<MerchantOrder>? orders,
    MerchantStats? stats,
    MerchantOrder? selected,
    bool? isBusy,
    String? error,
    bool clearSelected = false,
    bool clearError = false,
  }) {
    return MerchantUiState(
      phase: phase ?? this.phase,
      orders: orders ?? this.orders,
      stats: stats ?? this.stats,
      selected: clearSelected ? null : (selected ?? this.selected),
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class MerchantController extends Notifier<MerchantUiState> {
  MerchantRepository get _repo => ref.read(merchantRepositoryProvider);

  @override
  MerchantUiState build() => const MerchantUiState(isBusy: true);

  Future<void> bootstrap() async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final orders = await _repo.listOrders();
      final stats = await _repo.stats();
      state = state.copyWith(
        orders: orders,
        stats: stats,
        isBusy: false,
        phase: MerchantPhase.dashboard,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  void open(MerchantOrder o) => state = state.copyWith(
    selected: o,
    phase: MerchantPhase.detail,
    clearError: true,
  );

  void back() => state = state.copyWith(
    phase: MerchantPhase.dashboard,
    clearSelected: true,
  );

  Future<void> advanceSelected() async {
    final o = state.selected;
    if (o == null) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final updated = await _repo.advance(o.id);
      final orders = await _repo.listOrders();
      final stats = await _repo.stats();
      state = state.copyWith(
        selected: updated,
        orders: orders,
        stats: stats,
        isBusy: false,
        phase: updated.status == MerchantOrderStatus.completed
            ? MerchantPhase.dashboard
            : MerchantPhase.detail,
        clearSelected: updated.status == MerchantOrderStatus.completed,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }
}

final merchantControllerProvider =
    NotifierProvider<MerchantController, MerchantUiState>(
      MerchantController.new,
    );

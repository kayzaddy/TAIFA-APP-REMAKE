import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/huduma/rest_huduma_repository.dart';
import '../../wallet/application/wallet_providers.dart'
    show apiClientProvider, apiConfigProvider;
import '../domain/huduma_models.dart';
import 'huduma_repository.dart';

/// Seed offline, or live bookings when `TAIFA_USE_REMOTE=true`.
final hudumaRepositoryProvider = Provider<HudumaRepository>((ref) {
  final config = ref.watch(apiConfigProvider);
  if (config.useRemoteBackend) {
    return RestHudumaRepository(ref.watch(apiClientProvider));
  }
  return SeedHudumaRepository();
});

enum HudumaPhase { home, detail, confirm, receipt, history }

class HudumaUiState {
  const HudumaUiState({
    this.phase = HudumaPhase.home,
    this.services = const [],
    this.selected,
    this.slotLabel = 'Today · 2–4 pm',
    this.booking,
    this.history = const [],
    this.isBusy = false,
    this.error,
  });

  final HudumaPhase phase;
  final List<HudumaService> services;
  final HudumaService? selected;
  final String slotLabel;
  final HudumaBooking? booking;
  final List<HudumaBooking> history;
  final bool isBusy;
  final String? error;

  HudumaUiState copyWith({
    HudumaPhase? phase,
    List<HudumaService>? services,
    HudumaService? selected,
    String? slotLabel,
    HudumaBooking? booking,
    List<HudumaBooking>? history,
    bool? isBusy,
    String? error,
    bool clearSelected = false,
    bool clearBooking = false,
    bool clearError = false,
  }) {
    return HudumaUiState(
      phase: phase ?? this.phase,
      services: services ?? this.services,
      selected: clearSelected ? null : (selected ?? this.selected),
      slotLabel: slotLabel ?? this.slotLabel,
      booking: clearBooking ? null : (booking ?? this.booking),
      history: history ?? this.history,
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class HudumaController extends Notifier<HudumaUiState> {
  HudumaRepository get _repo => ref.read(hudumaRepositoryProvider);

  @override
  HudumaUiState build() => const HudumaUiState();

  Future<void> bootstrap() async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final services = await _repo.list();
      final history = await _repo.history();
      state = state.copyWith(
        services: services,
        history: history,
        isBusy: false,
        phase: HudumaPhase.home,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  void open(HudumaService service) => state = state.copyWith(
    selected: service,
    phase: HudumaPhase.detail,
    slotLabel: service.etaLabel,
    clearBooking: true,
    clearError: true,
  );

  void backHome() => state = state.copyWith(
    phase: HudumaPhase.home,
    clearSelected: true,
    clearBooking: true,
    clearError: true,
  );

  void setSlot(String slot) => state = state.copyWith(slotLabel: slot);

  void goConfirm() {
    if (state.selected == null) return;
    state = state.copyWith(phase: HudumaPhase.confirm, clearError: true);
  }

  Future<void> book() async {
    final service = state.selected;
    if (service == null) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final draft = HudumaBooking(
        id: 'draft',
        service: service,
        status: HudumaBookingStatus.drafting,
        slotLabel: state.slotLabel,
        createdAt: DateTime.now(),
      );
      final booking = await _repo.book(draft);
      state = state.copyWith(
        booking: booking,
        history: await _repo.history(),
        isBusy: false,
        phase: HudumaPhase.receipt,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  void openHistory() => state = state.copyWith(phase: HudumaPhase.history);
}

final hudumaControllerProvider =
    NotifierProvider<HudumaController, HudumaUiState>(HudumaController.new);

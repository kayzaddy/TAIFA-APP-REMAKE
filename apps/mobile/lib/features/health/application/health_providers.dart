import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/health/rest_appointment_repository.dart';
import '../../wallet/application/wallet_providers.dart'
    show apiClientProvider, apiConfigProvider;
import '../domain/health_models.dart';
import 'health_repository.dart';

final healthFacilityRepositoryProvider = Provider<HealthFacilityRepository>(
  (ref) => SeedHealthFacilityRepository(),
);

/// Seed offline, or live commerce API when `TAIFA_USE_REMOTE=true`.
final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  final config = ref.watch(apiConfigProvider);
  if (config.useRemoteBackend) {
    return RestAppointmentRepository(ref.watch(apiClientProvider));
  }
  return SeedAppointmentRepository();
});

enum HealthPhase { home, detail, checkout, confirmed, receipt, history }

class HealthUiState {
  const HealthUiState({
    this.phase = HealthPhase.home,
    this.facilities = const [],
    this.query = '',
    this.selected,
    this.slot,
    this.patientName = 'Amani Juma',
    this.appointment,
    this.history = const [],
    this.isBusy = false,
    this.error,
  });

  final HealthPhase phase;
  final List<HealthFacility> facilities;
  final String query;
  final HealthFacility? selected;
  final DateTime? slot;
  final String patientName;
  final HealthAppointment? appointment;
  final List<HealthAppointment> history;
  final bool isBusy;
  final String? error;

  HealthUiState copyWith({
    HealthPhase? phase,
    List<HealthFacility>? facilities,
    String? query,
    HealthFacility? selected,
    DateTime? slot,
    String? patientName,
    HealthAppointment? appointment,
    List<HealthAppointment>? history,
    bool? isBusy,
    String? error,
    bool clearSelected = false,
    bool clearAppointment = false,
    bool clearError = false,
  }) {
    return HealthUiState(
      phase: phase ?? this.phase,
      facilities: facilities ?? this.facilities,
      query: query ?? this.query,
      selected: clearSelected ? null : (selected ?? this.selected),
      slot: slot ?? this.slot,
      patientName: patientName ?? this.patientName,
      appointment: clearAppointment ? null : (appointment ?? this.appointment),
      history: history ?? this.history,
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class HealthController extends Notifier<HealthUiState> {
  HealthFacilityRepository get _facilities =>
      ref.read(healthFacilityRepositoryProvider);
  AppointmentRepository get _apts => ref.read(appointmentRepositoryProvider);

  @override
  HealthUiState build() => const HealthUiState();

  Future<void> bootstrap() async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final now = DateTime.now();
      final slot = DateTime(now.year, now.month, now.day + 1, 10, 0);
      final list = await _facilities.list();
      final history = await _apts.history();
      state = state.copyWith(
        facilities: list,
        history: history,
        slot: slot,
        isBusy: false,
        phase: HealthPhase.home,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> search(String q) async {
    state = state.copyWith(query: q, isBusy: true, clearError: true);
    state = state.copyWith(
      facilities: await _facilities.list(query: q),
      isBusy: false,
    );
  }

  void open(HealthFacility f) => state = state.copyWith(
    selected: f,
    phase: HealthPhase.detail,
    clearAppointment: true,
    clearError: true,
  );

  void backHome() => state = state.copyWith(
    phase: HealthPhase.home,
    clearSelected: true,
    clearAppointment: true,
    clearError: true,
  );

  void goCheckout() {
    if (state.selected == null) return;
    state = state.copyWith(phase: HealthPhase.checkout, clearError: true);
  }

  void setPatient(String n) => state = state.copyWith(patientName: n);
  void setSlot(DateTime d) => state = state.copyWith(slot: d);

  Future<void> book() async {
    final f = state.selected;
    final slot = state.slot;
    if (f == null || slot == null) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final draft = HealthAppointment(
        id: 'draft',
        facility: f,
        slot: slot,
        patientName: state.patientName.trim().isEmpty
            ? 'Amani Juma'
            : state.patientName.trim(),
        fee: f.consultFee,
        status: AppointmentStatus.drafting,
        createdAt: DateTime.now(),
      );
      final booked = await _apts.book(draft);
      state = state.copyWith(
        appointment: booked,
        isBusy: false,
        phase: HealthPhase.confirmed,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> pay() async {
    final a = state.appointment;
    if (a == null) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final paid = await _apts.pay(a.id);
      state = state.copyWith(
        appointment: paid,
        history: await _apts.history(),
        isBusy: false,
        phase: HealthPhase.receipt,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  void openHistory() => state = state.copyWith(phase: HealthPhase.history);
}

final healthControllerProvider =
    NotifierProvider<HealthController, HealthUiState>(HealthController.new);

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/flights/rest_flight_booking_repository.dart';
import '../../wallet/application/wallet_providers.dart'
    show apiClientProvider, apiConfigProvider;
import '../../wallet/domain/currency.dart';
import '../../wallet/domain/money.dart';
import '../data/flight_catalog.dart';
import '../domain/flight_models.dart';
import 'flight_repository.dart';
import 'seed_flight_repository.dart';

final flightSearchRepositoryProvider = Provider<FlightSearchRepository>(
  (ref) => SeedFlightSearchRepository(),
);

/// Seed offline, or live commerce API when `TAIFA_USE_REMOTE=true`.
final flightBookingRepositoryProvider = Provider<FlightBookingRepository>((
  ref,
) {
  final config = ref.watch(apiConfigProvider);
  if (config.useRemoteBackend) {
    return RestFlightBookingRepository(ref.watch(apiClientProvider));
  }
  return SeedFlightBookingRepository();
});

enum FlightPhase { search, results, checkout, ticketed, receipt, history }

class FlightUiState {
  const FlightUiState({
    this.phase = FlightPhase.search,
    this.airports = const [],
    this.originCode = 'DAR',
    this.destinationCode = 'ZNZ',
    this.departDate,
    this.passengers = 1,
    this.results = const [],
    this.selected,
    this.booking,
    this.history = const [],
    this.isBusy = false,
    this.error,
  });

  final FlightPhase phase;
  final List<Airport> airports;
  final String originCode;
  final String destinationCode;
  final DateTime? departDate;
  final int passengers;
  final List<FlightOffer> results;
  final FlightOffer? selected;
  final FlightBooking? booking;
  final List<FlightBooking> history;
  final bool isBusy;
  final String? error;

  Money get total {
    final offer = selected;
    if (offer == null) return Money.zero(Currency.tzs);
    return Money(offer.price.minorUnits * passengers, offer.price.currency);
  }

  FlightUiState copyWith({
    FlightPhase? phase,
    List<Airport>? airports,
    String? originCode,
    String? destinationCode,
    DateTime? departDate,
    int? passengers,
    List<FlightOffer>? results,
    FlightOffer? selected,
    FlightBooking? booking,
    List<FlightBooking>? history,
    bool? isBusy,
    String? error,
    bool clearError = false,
    bool clearSelected = false,
    bool clearBooking = false,
  }) {
    return FlightUiState(
      phase: phase ?? this.phase,
      airports: airports ?? this.airports,
      originCode: originCode ?? this.originCode,
      destinationCode: destinationCode ?? this.destinationCode,
      departDate: departDate ?? this.departDate,
      passengers: passengers ?? this.passengers,
      results: results ?? this.results,
      selected: clearSelected ? null : (selected ?? this.selected),
      booking: clearBooking ? null : (booking ?? this.booking),
      history: history ?? this.history,
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class FlightController extends Notifier<FlightUiState> {
  FlightSearchRepository get _search =>
      ref.read(flightSearchRepositoryProvider);
  FlightBookingRepository get _bookings =>
      ref.read(flightBookingRepositoryProvider);

  @override
  FlightUiState build() => const FlightUiState();

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> bootstrap() async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final airports = await _search.airports();
      final history = await _bookings.history();
      state = state.copyWith(
        airports: airports,
        history: history,
        departDate: _dateOnly(DateTime.now()).add(const Duration(days: 2)),
        isBusy: false,
        phase: FlightPhase.search,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  void setOrigin(String code) =>
      state = state.copyWith(originCode: code, clearError: true);
  void setDestination(String code) =>
      state = state.copyWith(destinationCode: code, clearError: true);
  void setDate(DateTime date) =>
      state = state.copyWith(departDate: _dateOnly(date), clearError: true);
  void setPassengers(int n) =>
      state = state.copyWith(passengers: n.clamp(1, 6), clearError: true);

  void swapAirports() {
    state = state.copyWith(
      originCode: state.destinationCode,
      destinationCode: state.originCode,
      clearError: true,
    );
  }

  void backToSearch() {
    state = state.copyWith(
      phase: FlightPhase.search,
      clearSelected: true,
      clearBooking: true,
      clearError: true,
    );
  }

  void backToResults() {
    state = state.copyWith(
      phase: FlightPhase.results,
      clearSelected: true,
      clearBooking: true,
      clearError: true,
    );
  }

  void openHistory() =>
      state = state.copyWith(phase: FlightPhase.history, clearError: true);

  Future<void> search() async {
    if (state.originCode == state.destinationCode) {
      state = state.copyWith(error: 'Choose different origin and destination.');
      return;
    }
    final date = state.departDate;
    if (date == null) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final results = await _search.search(
        originCode: state.originCode,
        destinationCode: state.destinationCode,
        date: date,
      );
      state = state.copyWith(
        results: results,
        isBusy: false,
        phase: FlightPhase.results,
        clearSelected: true,
      );
      if (results.isEmpty) {
        state = state.copyWith(
          error: 'No flights on this route for the selected day.',
        );
      }
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  void selectOffer(FlightOffer offer) {
    state = state.copyWith(
      selected: offer,
      phase: FlightPhase.checkout,
      clearError: true,
    );
  }

  Future<void> confirmBooking() async {
    final offer = state.selected;
    if (offer == null) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final draft = FlightBooking(
        id: 'draft',
        offer: offer,
        passengers: state.passengers,
        total: state.total,
        status: FlightBookingStatus.drafting,
        createdAt: DateTime.now(),
      );
      final booked = await _bookings.book(draft);
      state = state.copyWith(
        booking: booked,
        isBusy: false,
        phase: FlightPhase.ticketed,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> confirmPayment() async {
    final booking = state.booking;
    if (booking == null) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final paid = await _bookings.pay(booking.id);
      final history = await _bookings.history();
      state = state.copyWith(
        booking: paid,
        history: history,
        isBusy: false,
        phase: FlightPhase.receipt,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }
}

final flightControllerProvider =
    NotifierProvider<FlightController, FlightUiState>(FlightController.new);

/// Convenience for UI labels.
Airport airportByCode(String code) {
  return FlightCatalog.airports().firstWhere(
    (a) => a.code == code,
    orElse: () => Airport(code: code, city: code, name: code),
  );
}

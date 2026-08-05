import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/tourism/rest_tourism_assist_repository.dart';
import '../../../data/tourism/rest_tour_booking_repository.dart';
import '../../../data/tourism/rest_tourism_trip_repository.dart';
import '../../wallet/application/wallet_providers.dart'
    show apiClientProvider, apiConfigProvider;
import '../../wallet/domain/currency.dart';
import '../../wallet/domain/money.dart';
import '../domain/tourism_assist_models.dart';
import '../domain/tourism_checkout_models.dart';
import '../domain/tourism_models.dart';
import '../domain/tourism_trip_models.dart';
import 'seed_tourism_assist_repository.dart';
import 'seed_tourism_repository.dart';
import 'seed_tourism_trip_repository.dart';
import 'tourism_assist_repository.dart';
import 'tourism_repository.dart';
import 'tourism_trip_repository.dart';

final tourismRepositoryProvider = Provider<TourismRepository>(
  (ref) => SeedTourismRepository(),
);

/// Seed offline, or live commerce API when `TAIFA_USE_REMOTE=true`.
final tourBookingRepositoryProvider = Provider<TourBookingRepository>((ref) {
  final config = ref.watch(apiConfigProvider);
  if (config.useRemoteBackend) {
    return RestTourBookingRepository(ref.watch(apiClientProvider));
  }
  return SeedTourBookingRepository();
});

final tourismTripRepositoryProvider = Provider<TourismTripRepository>((ref) {
  final config = ref.watch(apiConfigProvider);
  if (config.useRemoteBackend) {
    return RestTourismTripRepository(ref.watch(apiClientProvider));
  }
  return SeedTourismTripRepository();
});

final tourismAssistRepositoryProvider = Provider<TourismAssistRepository>((ref) {
  final config = ref.watch(apiConfigProvider);
  if (config.useRemoteBackend) {
    return RestTourismAssistRepository(ref.watch(apiClientProvider));
  }
  return SeedTourismAssistRepository();
});

enum TourismPhase {
  home,
  planInterview,
  planOptions,
  itineraryDetail,
  tripHub,
  unifiedCheckout,
  tripCheckoutReceipt,
  tourismHelp,
  detail,
  checkout,
  confirmed,
  receipt,
  history,
}

class TourismUiState {
  const TourismUiState({
    this.phase = TourismPhase.home,
    this.tours = const [],
    this.query = '',
    this.selected,
    this.date,
    this.guests = 2,
    this.booking,
    this.history = const [],
    this.isBusy = false,
    this.error,
    this.activeTrip,
    this.tripItineraries = const [],
    this.focusItinerary,
    this.planBudgetTier = 'mid',
    this.planTravelStyle = 'leisure',
    this.planInterests = const [],
    this.cart,
    this.checkout,
    this.includeTripInsurance = true,
    this.includeTripEsim = false,
    this.nearbyPlaces = const [],
    this.lastSosCase,
  });

  final TourismPhase phase;
  final List<TourExperience> tours;
  final String query;
  final TourExperience? selected;
  final DateTime? date;
  final int guests;
  final TourBooking? booking;
  final List<TourBooking> history;
  final bool isBusy;
  final String? error;
  final TourismTrip? activeTrip;
  final List<TourismItinerary> tripItineraries;
  final TourismItinerary? focusItinerary;
  final String planBudgetTier;
  final String planTravelStyle;
  final List<String> planInterests;
  final TourismCart? cart;
  final TourismCheckout? checkout;
  final bool includeTripInsurance;
  final bool includeTripEsim;
  final List<TourismNearbyPlace> nearbyPlaces;
  final TourismAssistanceCase? lastSosCase;

  Money get total {
    final tour = selected;
    if (tour == null) return Money.zero(Currency.tzs);
    return Money(tour.price.minorUnits * guests, tour.price.currency);
  }

  TourismUiState copyWith({
    TourismPhase? phase,
    List<TourExperience>? tours,
    String? query,
    TourExperience? selected,
    DateTime? date,
    int? guests,
    TourBooking? booking,
    List<TourBooking>? history,
    bool? isBusy,
    String? error,
    TourismTrip? activeTrip,
    List<TourismItinerary>? tripItineraries,
    TourismItinerary? focusItinerary,
    String? planBudgetTier,
    String? planTravelStyle,
    List<String>? planInterests,
    TourismCart? cart,
    TourismCheckout? checkout,
    bool? includeTripInsurance,
    bool? includeTripEsim,
    List<TourismNearbyPlace>? nearbyPlaces,
    TourismAssistanceCase? lastSosCase,
    bool clearCart = false,
    bool clearCheckout = false,
    bool clearSosCase = false,
    bool clearError = false,
    bool clearSelected = false,
    bool clearBooking = false,
    bool clearFocusItinerary = false,
    bool clearActiveTrip = false,
  }) {
    return TourismUiState(
      phase: phase ?? this.phase,
      tours: tours ?? this.tours,
      query: query ?? this.query,
      selected: clearSelected ? null : (selected ?? this.selected),
      date: date ?? this.date,
      guests: guests ?? this.guests,
      booking: clearBooking ? null : (booking ?? this.booking),
      history: history ?? this.history,
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : (error ?? this.error),
      activeTrip: clearActiveTrip ? null : (activeTrip ?? this.activeTrip),
      tripItineraries: tripItineraries ?? this.tripItineraries,
      focusItinerary:
          clearFocusItinerary ? null : (focusItinerary ?? this.focusItinerary),
      planBudgetTier: planBudgetTier ?? this.planBudgetTier,
      planTravelStyle: planTravelStyle ?? this.planTravelStyle,
      planInterests: planInterests ?? this.planInterests,
      cart: clearCart ? null : (cart ?? this.cart),
      checkout: clearCheckout ? null : (checkout ?? this.checkout),
      includeTripInsurance: includeTripInsurance ?? this.includeTripInsurance,
      includeTripEsim: includeTripEsim ?? this.includeTripEsim,
      nearbyPlaces: nearbyPlaces ?? this.nearbyPlaces,
      lastSosCase: clearSosCase ? null : (lastSosCase ?? this.lastSosCase),
    );
  }
}

class TourismController extends Notifier<TourismUiState> {
  TourismRepository get _tours => ref.read(tourismRepositoryProvider);
  TourBookingRepository get _bookings =>
      ref.read(tourBookingRepositoryProvider);
  TourismTripRepository get _trips => ref.read(tourismTripRepositoryProvider);
  TourismAssistRepository get _assist =>
      ref.read(tourismAssistRepositoryProvider);

  @override
  TourismUiState build() => const TourismUiState();

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> bootstrap() async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final list = await _tours.list();
      final history = await _bookings.history();
      final tripRows = await _trips.listTrips();
      final active = tripRows.isNotEmpty ? tripRows.first : null;
      state = state.copyWith(
        tours: list,
        history: history,
        activeTrip: active,
        date: _dateOnly(DateTime.now()).add(const Duration(days: 3)),
        isBusy: false,
        phase: TourismPhase.home,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> search(String query) async {
    state = state.copyWith(query: query, isBusy: true, clearError: true);
    final list = await _tours.list(query: query);
    state = state.copyWith(tours: list, isBusy: false);
  }

  void startPlanFlow() {
    state = state.copyWith(
      phase: TourismPhase.planInterview,
      clearError: true,
      clearFocusItinerary: true,
    );
  }

  void setPlanBudget(String tier) =>
      state = state.copyWith(planBudgetTier: tier, clearError: true);

  void setPlanStyle(String style) =>
      state = state.copyWith(planTravelStyle: style, clearError: true);

  void togglePlanInterest(String interest) {
    final current = List<String>.from(state.planInterests);
    if (current.contains(interest)) {
      current.remove(interest);
    } else {
      current.add(interest);
    }
    state = state.copyWith(planInterests: current, clearError: true);
  }

  Future<void> submitPlan() async {
    final start = state.date;
    if (start == null) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      var trip = state.activeTrip;
      trip ??= await _trips.createTrip(
        partySize: state.guests,
        budgetTier: state.planBudgetTier,
        travelStyle: state.planTravelStyle,
        interests: state.planInterests,
        startDate: start,
      );
      final result = await _trips.planTrip(
        tripId: trip.id,
        partySize: state.guests,
        budgetTier: state.planBudgetTier,
        travelStyle: state.planTravelStyle,
        interests: state.planInterests,
        startDate: start,
      );
      state = state.copyWith(
        activeTrip: result.trip,
        tripItineraries: result.itineraries,
        isBusy: false,
        phase: TourismPhase.planOptions,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  void openItineraryDetail(TourismItinerary itinerary) {
    state = state.copyWith(
      focusItinerary: itinerary,
      phase: TourismPhase.itineraryDetail,
      clearError: true,
    );
  }

  Future<void> confirmItinerary(String itineraryId) async {
    final trip = state.activeTrip;
    if (trip == null) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final updated = await _trips.selectItinerary(
        tripId: trip.id,
        itineraryId: itineraryId,
      );
      state = state.copyWith(
        activeTrip: updated,
        isBusy: false,
        phase: TourismPhase.tripHub,
        clearFocusItinerary: true,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> openTripHub() async {
    final trip = state.activeTrip;
    if (trip == null) {
      startPlanFlow();
      return;
    }
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      var itineraries = state.tripItineraries;
      if (itineraries.isEmpty) {
        itineraries = await _trips.listItineraries(trip.id);
      }
      state = state.copyWith(
        tripItineraries: itineraries,
        isBusy: false,
        phase: TourismPhase.tripHub,
        clearFocusItinerary: true,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  void backFromPlanInterview() {
    state = state.copyWith(phase: TourismPhase.home, clearError: true);
  }

  void backFromPlanOptions() {
    state = state.copyWith(
      phase: TourismPhase.planInterview,
      clearFocusItinerary: true,
      clearError: true,
    );
  }

  void backFromItineraryDetail() {
    state = state.copyWith(
      phase: TourismPhase.planOptions,
      clearFocusItinerary: true,
      clearError: true,
    );
  }

  void backFromTripHub() {
    state = state.copyWith(phase: TourismPhase.home, clearError: true);
  }

  Future<TourismCheckout> _refreshCheckout() {
    final trip = state.activeTrip!;
    return _trips.createCheckout(
      tripId: trip.id,
      includeInsurance: state.includeTripInsurance,
      includeEsim: state.includeTripEsim,
    );
  }

  Future<void> openTourismHelp() async {
    state = state.copyWith(isBusy: true, clearError: true, clearSosCase: true);
    try {
      final places = await _assist.nearby();
      state = state.copyWith(
        nearbyPlaces: places,
        isBusy: false,
        phase: TourismPhase.tourismHelp,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  void backFromTourismHelp() {
    state = state.copyWith(phase: TourismPhase.tripHub, clearError: true);
  }

  Future<void> sendTourismSos({String notes = ''}) async {
    final trip = state.activeTrip;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final caseRow = await _assist.sendSos(
        tripId: trip?.id,
        notes: notes,
      );
      state = state.copyWith(lastSosCase: caseRow, isBusy: false);
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> openUnifiedCheckout() async {
    final trip = state.activeTrip;
    if (trip == null) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final cart = await _trips.buildCart(trip.id);
      final checkout = await _refreshCheckout();
      state = state.copyWith(
        cart: cart,
        checkout: checkout,
        isBusy: false,
        phase: TourismPhase.unifiedCheckout,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> setIncludeTripInsurance(bool value) async {
    final trip = state.activeTrip;
    if (trip == null) return;
    state = state.copyWith(includeTripInsurance: value, isBusy: true, clearError: true);
    try {
      final checkout = await _refreshCheckout();
      state = state.copyWith(checkout: checkout, isBusy: false);
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> setIncludeTripEsim(bool value) async {
    final trip = state.activeTrip;
    if (trip == null) return;
    state = state.copyWith(includeTripEsim: value, isBusy: true, clearError: true);
    try {
      final checkout = await _refreshCheckout();
      state = state.copyWith(checkout: checkout, isBusy: false);
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  void backFromUnifiedCheckout() {
    state = state.copyWith(
      phase: TourismPhase.tripHub,
      clearCheckout: true,
      clearError: true,
    );
  }

  Future<void> confirmUnifiedPayment() async {
    final trip = state.activeTrip;
    if (trip == null) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final key = 'tourism-${trip.id}-${DateTime.now().millisecondsSinceEpoch}';
      var paid = await _trips.payCheckout(tripId: trip.id, idempotencyKey: key);
      if (paid.esimOrderId != null) {
        final activation = await _assist.esimQr(paid.esimOrderId!);
        paid = TourismCheckout(
          id: paid.id,
          tripId: paid.tripId,
          status: paid.status,
          includeInsurance: paid.includeInsurance,
          includeEsim: paid.includeEsim,
          lines: paid.lines,
          travelSubtotalMinor: paid.travelSubtotalMinor,
          protectionSubtotalMinor: paid.protectionSubtotalMinor,
          connectivitySubtotalMinor: paid.connectivitySubtotalMinor,
          totalMinor: paid.totalMinor,
          insurancePolicyId: paid.insurancePolicyId,
          esimOrderId: paid.esimOrderId,
          esimActivation: activation,
          paymentRef: paid.paymentRef,
          currency: paid.currency,
        );
      }
      final trips = await _trips.listTrips();
      final active = trips.isNotEmpty ? trips.first : trip;
      state = state.copyWith(
        checkout: paid,
        activeTrip: active,
        isBusy: false,
        phase: TourismPhase.tripCheckoutReceipt,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  void backFromTripCheckoutReceipt() {
    state = state.copyWith(
      phase: TourismPhase.tripHub,
      clearCheckout: true,
      clearError: true,
    );
  }

  Future<void> _attachTourBookingIfNeeded(String bookingId) async {
    final trip = state.activeTrip;
    if (trip == null) return;
    try {
      final updated = await _trips.attachBooking(
        tripId: trip.id,
        bookingType: 'tour',
        bookingId: bookingId,
      );
      state = state.copyWith(activeTrip: updated);
    } catch (_) {
      // Non-blocking: booking still succeeded.
    }
  }

  void openTour(TourExperience tour) {
    state = state.copyWith(
      selected: tour,
      phase: TourismPhase.detail,
      clearBooking: true,
      clearError: true,
    );
  }

  void backToHome() {
    state = state.copyWith(
      phase: TourismPhase.home,
      clearSelected: true,
      clearBooking: true,
      clearError: true,
    );
  }

  void goCheckout() {
    if (state.selected == null) return;
    state = state.copyWith(phase: TourismPhase.checkout, clearError: true);
  }

  void backToDetail() {
    if (state.selected == null) {
      backToHome();
      return;
    }
    state = state.copyWith(phase: TourismPhase.detail, clearError: true);
  }

  void setGuests(int n) =>
      state = state.copyWith(guests: n.clamp(1, 8), clearError: true);

  void setDate(DateTime date) =>
      state = state.copyWith(date: _dateOnly(date), clearError: true);

  void openHistory() =>
      state = state.copyWith(phase: TourismPhase.history, clearError: true);

  Future<void> confirmBooking() async {
    final tour = state.selected;
    final date = state.date;
    if (tour == null || date == null) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final draft = TourBooking(
        id: 'draft',
        tour: tour,
        guests: state.guests,
        date: date,
        total: state.total,
        status: TourBookingStatus.drafting,
        createdAt: DateTime.now(),
      );
      final booked = await _bookings.book(draft);
      await _attachTourBookingIfNeeded(booked.id);
      state = state.copyWith(
        booking: booked,
        isBusy: false,
        phase: TourismPhase.confirmed,
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
      await _attachTourBookingIfNeeded(paid.id);
      state = state.copyWith(
        booking: paid,
        history: history,
        isBusy: false,
        phase: TourismPhase.receipt,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }
}

final tourismControllerProvider =
    NotifierProvider<TourismController, TourismUiState>(TourismController.new);

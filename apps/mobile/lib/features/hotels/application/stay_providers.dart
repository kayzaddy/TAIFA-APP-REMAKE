import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/hotels/rest_stay_booking_repository.dart';
import '../../wallet/application/wallet_providers.dart'
    show apiClientProvider, apiConfigProvider;
import '../../wallet/domain/currency.dart';
import '../../wallet/domain/money.dart';
import '../domain/hotel_models.dart';
import 'hotel_repository.dart';
import 'seed_hotel_repository.dart';

final hotelRepositoryProvider = Provider<HotelRepository>(
  (ref) => SeedHotelRepository(),
);

/// Seed offline, or live commerce API when `TAIFA_USE_REMOTE=true`.
final stayBookingRepositoryProvider = Provider<StayBookingRepository>((ref) {
  final config = ref.watch(apiConfigProvider);
  if (config.useRemoteBackend) {
    return RestStayBookingRepository(ref.watch(apiClientProvider));
  }
  return SeedStayBookingRepository();
});

enum StayPhase { home, detail, rooms, checkout, confirmed, receipt, history }

class StayUiState {
  const StayUiState({
    this.phase = StayPhase.home,
    this.hotels = const [],
    this.query = '',
    this.selected,
    this.selectedRoom,
    this.checkIn,
    this.checkOut,
    this.guests = 2,
    this.booking,
    this.history = const [],
    this.isBusy = false,
    this.error,
  });

  final StayPhase phase;
  final List<Hotel> hotels;
  final String query;
  final Hotel? selected;
  final RoomType? selectedRoom;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int guests;
  final StayBooking? booking;
  final List<StayBooking> history;
  final bool isBusy;
  final String? error;

  int get nights {
    final a = checkIn;
    final b = checkOut;
    if (a == null || b == null) return 1;
    final d = b.difference(a).inDays;
    return d < 1 ? 1 : d;
  }

  Money get roomSubtotal {
    final room = selectedRoom;
    if (room == null) return Money.zero(Currency.tzs);
    return Money(
      room.nightlyRate.minorUnits * nights,
      room.nightlyRate.currency,
    );
  }

  Money get taxes {
    final sub = roomSubtotal;
    // ~10% VAT/tourism levy stand-in for demo.
    return Money((sub.minorUnits * 0.1).round(), sub.currency);
  }

  Money get total => roomSubtotal + taxes;

  StayUiState copyWith({
    StayPhase? phase,
    List<Hotel>? hotels,
    String? query,
    Hotel? selected,
    RoomType? selectedRoom,
    DateTime? checkIn,
    DateTime? checkOut,
    int? guests,
    StayBooking? booking,
    List<StayBooking>? history,
    bool? isBusy,
    String? error,
    bool clearError = false,
    bool clearSelected = false,
    bool clearRoom = false,
    bool clearBooking = false,
  }) {
    return StayUiState(
      phase: phase ?? this.phase,
      hotels: hotels ?? this.hotels,
      query: query ?? this.query,
      selected: clearSelected ? null : (selected ?? this.selected),
      selectedRoom: clearRoom ? null : (selectedRoom ?? this.selectedRoom),
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      guests: guests ?? this.guests,
      booking: clearBooking ? null : (booking ?? this.booking),
      history: history ?? this.history,
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class StayController extends Notifier<StayUiState> {
  HotelRepository get _hotels => ref.read(hotelRepositoryProvider);
  StayBookingRepository get _bookings =>
      ref.read(stayBookingRepositoryProvider);

  @override
  StayUiState build() => const StayUiState();

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> bootstrap() async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final now = _dateOnly(DateTime.now());
      final list = await _hotels.list();
      final history = await _bookings.history();
      state = state.copyWith(
        hotels: list,
        history: history,
        checkIn: now.add(const Duration(days: 1)),
        checkOut: now.add(const Duration(days: 3)),
        isBusy: false,
        phase: StayPhase.home,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> search(String query) async {
    state = state.copyWith(query: query, isBusy: true, clearError: true);
    final list = await _hotels.list(query: query);
    state = state.copyWith(hotels: list, isBusy: false);
  }

  void openHotel(Hotel hotel) {
    state = state.copyWith(
      selected: hotel,
      phase: StayPhase.detail,
      clearRoom: true,
      clearBooking: true,
      clearError: true,
    );
  }

  void backToHome() {
    state = state.copyWith(
      phase: StayPhase.home,
      clearSelected: true,
      clearRoom: true,
      clearBooking: true,
      clearError: true,
    );
  }

  void openRooms() {
    if (state.selected == null) return;
    state = state.copyWith(phase: StayPhase.rooms, clearError: true);
  }

  void backToDetail() {
    if (state.selected == null) {
      backToHome();
      return;
    }
    state = state.copyWith(phase: StayPhase.detail, clearError: true);
  }

  void selectRoom(RoomType room) {
    if (guestsInvalid(room)) {
      state = state.copyWith(
        error:
            'This room sleeps ${room.maxGuests}. Adjust guests or pick another room.',
      );
      return;
    }
    state = state.copyWith(
      selectedRoom: room,
      phase: StayPhase.checkout,
      clearError: true,
    );
  }

  bool guestsInvalid(RoomType room) => state.guests > room.maxGuests;

  void setGuests(int guests) {
    final g = guests.clamp(1, 6);
    state = state.copyWith(guests: g, clearError: true);
  }

  void setCheckIn(DateTime date) {
    final d = _dateOnly(date);
    var out = state.checkOut ?? d.add(const Duration(days: 2));
    if (!out.isAfter(d)) {
      out = d.add(const Duration(days: 1));
    }
    state = state.copyWith(checkIn: d, checkOut: out, clearError: true);
  }

  void setCheckOut(DateTime date) {
    final d = _dateOnly(date);
    final inn =
        state.checkIn ?? _dateOnly(DateTime.now()).add(const Duration(days: 1));
    if (!d.isAfter(inn)) {
      state = state.copyWith(error: 'Check-out must be after check-in.');
      return;
    }
    state = state.copyWith(checkOut: d, clearError: true);
  }

  void openHistory() {
    state = state.copyWith(phase: StayPhase.history, clearError: true);
  }

  Future<void> confirmBooking() async {
    final hotel = state.selected;
    final room = state.selectedRoom;
    final checkIn = state.checkIn;
    final checkOut = state.checkOut;
    if (hotel == null || room == null || checkIn == null || checkOut == null) {
      return;
    }
    if (guestsInvalid(room)) {
      state = state.copyWith(error: 'Guest count exceeds room capacity.');
      return;
    }
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final draft = StayBooking(
        id: 'draft',
        hotel: hotel,
        room: room,
        checkIn: checkIn,
        checkOut: checkOut,
        guests: state.guests,
        nights: state.nights,
        nightlyRate: room.nightlyRate,
        taxes: state.taxes,
        total: state.total,
        status: StayBookingStatus.drafting,
        createdAt: DateTime.now(),
      );
      final booked = await _bookings.book(draft);
      state = state.copyWith(
        booking: booked,
        isBusy: false,
        phase: StayPhase.confirmed,
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
        phase: StayPhase.receipt,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }
}

final stayControllerProvider = NotifierProvider<StayController, StayUiState>(
  StayController.new,
);

import '../data/hotel_catalog.dart';
import '../domain/hotel_models.dart';
import 'hotel_repository.dart';

class SeedHotelRepository implements HotelRepository {
  @override
  Future<List<Hotel>> list({String? query}) async {
    await Future<void>.delayed(const Duration(milliseconds: 260));
    final all = HotelCatalog.all();
    final q = query?.trim().toLowerCase();
    if (q == null || q.isEmpty) return all;
    return all
        .where(
          (h) =>
              h.name.toLowerCase().contains(q) ||
              h.area.toLowerCase().contains(q) ||
              h.tagline.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Future<Hotel> getById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return HotelCatalog.all().firstWhere((h) => h.id == id);
  }
}

class SeedStayBookingRepository implements StayBookingRepository {
  final Map<String, StayBooking> _byId = {};
  final List<String> _order = [];
  int _seq = 0;

  @override
  Future<StayBooking> book(StayBooking draft) async {
    await Future<void>.delayed(const Duration(milliseconds: 420));
    final id = 'stay-${DateTime.now().millisecondsSinceEpoch}-${_seq++}';
    final code = 'TAF-${(100000 + _seq * 137) % 900000}';
    final booked = StayBooking(
      id: id,
      hotel: draft.hotel,
      room: draft.room,
      checkIn: draft.checkIn,
      checkOut: draft.checkOut,
      guests: draft.guests,
      nights: draft.nights,
      nightlyRate: draft.nightlyRate,
      taxes: draft.taxes,
      total: draft.total,
      status: StayBookingStatus.confirmed,
      createdAt: DateTime.now(),
      confirmationCode: code,
    );
    _byId[id] = booked;
    _order.insert(0, id);
    return booked;
  }

  @override
  Future<StayBooking> update(StayBooking booking) async {
    _byId[booking.id] = booking;
    return booking;
  }

  @override
  Future<StayBooking> pay(String bookingId) async {
    await Future<void>.delayed(const Duration(milliseconds: 480));
    final booking = await getById(bookingId);
    return update(
      booking.copyWith(
        status: StayBookingStatus.paid,
        paymentRef:
            'STAY-${bookingId.hashCode.abs().toRadixString(36).toUpperCase()}',
      ),
    );
  }

  @override
  Future<List<StayBooking>> history({int limit = 20}) async {
    await Future<void>.delayed(const Duration(milliseconds: 140));
    return _order.take(limit).map((id) => _byId[id]!).toList();
  }

  @override
  Future<StayBooking> getById(String id) async {
    final b = _byId[id];
    if (b == null) throw StateError('Booking not found: $id');
    return b;
  }
}

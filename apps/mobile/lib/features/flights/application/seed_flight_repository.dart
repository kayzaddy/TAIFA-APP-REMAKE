import '../data/flight_catalog.dart';
import '../domain/flight_models.dart';
import 'flight_repository.dart';

class SeedFlightSearchRepository implements FlightSearchRepository {
  @override
  Future<List<Airport>> airports() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return FlightCatalog.airports();
  }

  @override
  Future<List<FlightOffer>> search({
    required String originCode,
    required String destinationCode,
    required DateTime date,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 420));
    return FlightCatalog.search(
      originCode: originCode,
      destinationCode: destinationCode,
      date: date,
    );
  }
}

class SeedFlightBookingRepository implements FlightBookingRepository {
  final Map<String, FlightBooking> _byId = {};
  final List<String> _order = [];
  int _seq = 0;

  @override
  Future<FlightBooking> book(FlightBooking draft) async {
    await Future<void>.delayed(const Duration(milliseconds: 380));
    final id = 'tkt-${DateTime.now().millisecondsSinceEpoch}-${_seq++}';
    final pnr =
        'TA${(1000 + _seq * 41) % 9000}${String.fromCharCode(65 + (_seq % 26))}';
    final booked = FlightBooking(
      id: id,
      offer: draft.offer,
      passengers: draft.passengers,
      total: draft.total,
      status: FlightBookingStatus.ticketed,
      createdAt: DateTime.now(),
      pnr: pnr,
    );
    _byId[id] = booked;
    _order.insert(0, id);
    return booked;
  }

  @override
  Future<FlightBooking> pay(String bookingId) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    final booking = await getById(bookingId);
    final paid = booking.copyWith(
      status: FlightBookingStatus.paid,
      paymentRef:
          'FLT-${bookingId.hashCode.abs().toRadixString(36).toUpperCase()}',
    );
    _byId[bookingId] = paid;
    return paid;
  }

  @override
  Future<List<FlightBooking>> history({int limit = 20}) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return _order.take(limit).map((id) => _byId[id]!).toList();
  }

  @override
  Future<FlightBooking> getById(String id) async {
    final b = _byId[id];
    if (b == null) throw StateError('Flight booking not found: $id');
    return b;
  }
}

import '../domain/trip.dart';
import 'trip_repository.dart';

/// In-memory trip store used by the Foundation Sprint demo.
class SeedTripRepository implements TripRepository {
  final Map<String, Trip> _byId = {};
  final List<String> _order = [];
  int _seq = 0;

  @override
  bool get serverAuthoritative => false;

  @override
  Future<Trip> create(CreateTripRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final id = 'trip-${DateTime.now().millisecondsSinceEpoch}-${_seq++}';
    final trip = Trip(
      id: id,
      status: TripStatus.requesting,
      pickup: request.pickup,
      dropoff: request.dropoff,
      product: request.product,
      fare: request.product.fare,
      createdAt: DateTime.now(),
      route: request.route,
      distanceMeters: request.route?.distanceMeters,
      durationSeconds: request.route?.durationSeconds,
    );
    _byId[id] = trip;
    _order.insert(0, id);
    return trip;
  }

  @override
  Future<Trip> getById(String id) async {
    final trip = _byId[id];
    if (trip == null) throw StateError('Trip not found: $id');
    return trip;
  }

  @override
  Future<List<Trip>> history({int limit = 20}) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return _order.take(limit).map((id) => _byId[id]!).toList();
  }

  @override
  Future<Trip> update(Trip trip) async {
    _byId[trip.id] = trip;
    if (!_order.contains(trip.id)) _order.insert(0, trip.id);
    return trip;
  }

  @override
  Future<Trip> confirmPayment(String tripId) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final trip = await getById(tripId);
    final paid = trip.copyWith(
      status: TripStatus.paymentConfirmed,
      paymentRef:
          'PAY-${tripId.hashCode.abs().toRadixString(36).toUpperCase()}',
      completedAt: trip.completedAt ?? DateTime.now(),
    );
    return update(paid);
  }
}

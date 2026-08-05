import '../domain/place.dart';
import '../domain/ride_product.dart';
import '../domain/route_plan.dart';
import '../domain/trip.dart';
import '../../wallet/domain/money.dart';

class CreateTripRequest {
  const CreateTripRequest({
    required this.pickup,
    required this.dropoff,
    required this.product,
    this.route,
    this.paymentMethod = 'wallet',
    this.region = '',
    this.fare,
    this.hybridSmsDemo = false,
    this.passengerMsisdn = '',
  });

  final Place pickup;
  final Place dropoff;
  final RideProduct product;
  final RoutePlan? route;
  final String paymentMethod;
  final String region;

  /// Demo-only compatibility. The remote repository never sends this value.
  final Money? fare;

  /// When true, backend skips DEBUG auto-accept and sends SMS to feature-phone drivers.
  final bool hybridSmsDemo;
  final String passengerMsisdn;
}

/// Persist and load trips. Mock or REST behind the same interface.
abstract interface class TripRepository {
  /// True when dispatch, lifecycle, pricing and payment are server-authoritative.
  bool get serverAuthoritative;

  Future<Trip> create(CreateTripRequest request);
  Future<Trip> getById(String id);
  Future<List<Trip>> history({int limit = 20});
  Future<Trip> update(Trip trip);
  Future<Trip> confirmPayment(String tripId);
}

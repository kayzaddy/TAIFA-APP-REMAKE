// ignore_for_file: prefer_initializing_formals

import '../domain/driver.dart';
import '../domain/place.dart';
import '../domain/ride_product.dart';
import '../domain/route_plan.dart';
import '../domain/trip.dart';
import '../gateways/location_gateway.dart';
import '../gateways/matching_gateway.dart';
import '../gateways/pricing_gateway.dart';
import '../gateways/route_gateway.dart';
import 'trip_repository.dart';

/// Orchestrates a passenger trip using provider-agnostic gateways.
class RideService {
  RideService({
    required LocationGateway location,
    required RouteGateway routing,
    required PricingGateway pricing,
    required MatchingGateway matching,
    required TripRepository trips,
  }) : _location = location,
       _routing = routing,
       _pricing = pricing,
       _matching = matching,
       _trips = trips;

  final LocationGateway _location;
  final RouteGateway _routing;
  final PricingGateway _pricing;
  final MatchingGateway _matching;
  final TripRepository _trips;

  LocationGateway get location => _location;
  TripRepository get trips => _trips;

  Future<RoutePlan> plan(Place pickup, Place dropoff) =>
      _routing.planRoute(origin: pickup.point, destination: dropoff.point);

  Future<List<FareEstimate>> quote(RoutePlan route, Place pickup) =>
      _pricing.quote(route: route, pickup: pickup.point);

  Future<Trip> requestRide({
    required Place pickup,
    required Place dropoff,
    required RideProduct product,
    required RoutePlan route,
    bool hybridSmsDemo = false,
    String passengerMsisdn = '',
  }) async {
    var trip = await _trips.create(
      CreateTripRequest(
        pickup: pickup,
        dropoff: dropoff,
        product: product,
        route: route,
        hybridSmsDemo: hybridSmsDemo,
        passengerMsisdn: passengerMsisdn,
      ),
    );
    if (_trips.serverAuthoritative) return trip;
    trip = await _trips.update(trip.copyWith(status: TripStatus.searching));
    return trip;
  }

  Future<Trip> assignDriver(Trip trip) async {
    if (_trips.serverAuthoritative) {
      var current = trip;
      for (var attempt = 0; attempt < 30; attempt++) {
        current = await _trips.getById(trip.id);
        if (current.driver != null ||
            current.status == TripStatus.driverAssigned ||
            current.status == TripStatus.cancelled) {
          return current;
        }
        await Future<void>.delayed(const Duration(seconds: 1));
      }
      return current;
    }
    final driver = await _matching.matchDriver(
      pickup: trip.pickup,
      product: trip.product,
    );
    return _trips.update(
      trip.copyWith(
        status: TripStatus.driverAssigned,
        driver: driver,
        etaMinutes: trip.product.etaMinutes,
      ),
    );
  }

  Future<Trip> setStatus(Trip trip, TripStatus status, {Driver? driver}) {
    if (_trips.serverAuthoritative) return _trips.getById(trip.id);
    return _trips.update(
      trip.copyWith(
        status: status,
        driver: driver ?? trip.driver,
        startedAt: status == TripStatus.inProgress
            ? (trip.startedAt ?? DateTime.now())
            : trip.startedAt,
        completedAt: status == TripStatus.completed
            ? DateTime.now()
            : trip.completedAt,
      ),
    );
  }

  Future<Trip> pay(Trip trip) => _trips.confirmPayment(trip.id);

  Stream<Driver> watchDriverApproach(Trip trip) async* {
    if (_trips.serverAuthoritative) {
      for (var attempt = 0; attempt < 120; attempt++) {
        final current = await _trips.getById(trip.id);
        if (current.driver != null) yield current.driver!;
        if (current.status == TripStatus.completed ||
            current.status == TripStatus.cancelled) {
          return;
        }
        await Future<void>.delayed(const Duration(seconds: 2));
      }
      return;
    }
    final driver = trip.driver;
    if (driver == null) return;
    await for (final point in _matching.trackDriver(
      driver.id,
      toward: trip.pickup.point,
    )) {
      yield Driver(
        id: driver.id,
        fullName: driver.fullName,
        rating: driver.rating,
        tripsCompleted: driver.tripsCompleted,
        vehicle: driver.vehicle,
        phoneMasked: driver.phoneMasked,
        photoInitial: driver.photoInitial,
        location: point,
      );
    }
  }
}

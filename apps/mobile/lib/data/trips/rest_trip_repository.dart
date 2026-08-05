import '../../features/mobility/application/trip_repository.dart';
import '../../features/mobility/domain/driver.dart';
import '../../features/mobility/domain/route_plan.dart';
import '../../features/mobility/domain/trip.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import 'trip_api_paths.dart';
import 'trip_dto.dart';

/// Live [TripRepository]: persists ride lifecycle on `GET/POST/PATCH /trips`.
/// Matching, routing and map motion stay client-side; this layer stores the
/// durable receipt/history the backend already exposes.
class RestTripRepository implements TripRepository {
  RestTripRepository(this._client);

  final TaifaApiClient _client;

  @override
  bool get serverAuthoritative => true;

  /// Overlay for fields the API does not store (polyline, live driver point).
  final Map<String, _TripExtras> _extras = {};

  @override
  Future<Trip> create(CreateTripRequest request) async {
    try {
      final json = await _client.postJson(
        TripApiPaths.trips,
        body: TripDto.createBody(
          pickup: request.pickup,
          dropoff: request.dropoff,
          product: request.product,
          distanceMeters: request.route?.distanceMeters ?? 0,
          durationSeconds: request.route?.durationSeconds ?? 0,
          paymentMethod: request.paymentMethod,
          region: request.region,
          hybridSmsDemo: request.hybridSmsDemo,
          passengerMsisdn: request.passengerMsisdn,
        ),
      );
      final trip = TripDto.toDomain(json, route: request.route);
      _extras[trip.id] = _TripExtras(route: request.route);
      return trip;
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<Trip> getById(String id) async {
    try {
      final json = await _client.getJson(TripApiPaths.trip(id));
      final extras = _extras[id];
      return TripDto.toDomain(
        json,
        route: extras?.route,
        driver: extras?.driver,
      );
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<List<Trip>> history({int limit = 20}) async {
    try {
      final list = await _client.getJsonList(TripApiPaths.trips);
      return list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .map((json) {
            final id = json['id'].toString();
            final extras = _extras[id];
            return TripDto.toDomain(
              json,
              route: extras?.route,
              driver: extras?.driver,
            );
          })
          .take(limit)
          .toList();
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<Trip> update(Trip trip) async {
    try {
      final json = await _client.patchJson(
        TripApiPaths.trip(trip.id),
        body: TripDto.patchBody(trip),
      );
      _extras[trip.id] = _TripExtras(
        route: trip.route ?? _extras[trip.id]?.route,
        driver: trip.driver,
      );
      return TripDto.toDomain(
        json,
        route: trip.route ?? _extras[trip.id]?.route,
        driver: trip.driver,
      );
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<Trip> confirmPayment(String tripId) async {
    try {
      final json = await _client.postJson(
        TripApiPaths.payment(tripId),
        idempotencyKey: 'mobility-payment-$tripId',
      );
      final extras = _extras[tripId];
      return TripDto.toDomain(
        json,
        route: extras?.route,
        driver: extras?.driver,
      );
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  String _message(ApiException e) => switch (e) {
    NetworkException() => e.message,
    ApiStatusException(:final message) => message,
    ApiDecodeException() => e.message,
  };
}

class _TripExtras {
  const _TripExtras({this.route, this.driver});
  final RoutePlan? route;
  final Driver? driver;
}

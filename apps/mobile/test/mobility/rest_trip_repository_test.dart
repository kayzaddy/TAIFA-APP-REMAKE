import 'package:flutter_test/flutter_test.dart';
import 'package:taifa/data/api/api_client.dart';
import 'package:taifa/data/api/api_exception.dart';
import 'package:taifa/data/trips/rest_trip_repository.dart';
import 'package:taifa/data/trips/trip_api_paths.dart';
import 'package:taifa/features/mobility/application/trip_repository.dart';
import 'package:taifa/features/mobility/data/dar_places.dart';
import 'package:taifa/features/mobility/domain/ride_product.dart';
import 'package:taifa/features/mobility/domain/route_plan.dart';
import 'package:taifa/features/mobility/domain/trip.dart';
import 'package:taifa/features/wallet/domain/currency.dart';
import 'package:taifa/features/wallet/domain/money.dart';

class _FakeTripsClient implements TaifaApiClient {
  _FakeTripsClient({
    this.postResponse,
    this.getListResponse,
    this.patchResponse,
  });

  Map<String, dynamic>? postResponse;
  List<dynamic>? getListResponse;
  Map<String, dynamic>? patchResponse;

  String? lastPostPath;
  String? lastGetPath;
  String? lastPatchPath;
  String? lastIdempotencyKey;
  Map<String, dynamic>? lastBody;

  @override
  Future<Map<String, dynamic>> getJson(String path) async {
    lastGetPath = path;
    return postResponse ?? (throw const ApiDecodeException());
  }

  @override
  Future<List<dynamic>> getJsonList(String path) async {
    lastGetPath = path;
    return getListResponse ?? const [];
  }

  @override
  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic> body = const {},
    String? idempotencyKey,
  }) async {
    lastPostPath = path;
    lastBody = body;
    lastIdempotencyKey = idempotencyKey;
    return postResponse!;
  }

  @override
  Future<Map<String, dynamic>> patchJson(
    String path, {
    Map<String, dynamic> body = const {},
  }) async {
    lastPatchPath = path;
    lastBody = body;
    return patchResponse ?? postResponse!;
  }

  @override
  Future<void> deleteJson(String path) async {}
}

Map<String, dynamic> _tripJson({
  String id = '11111111-1111-1111-1111-111111111111',
  String status = 'requesting',
  String driverName = '',
  String paymentRef = '',
}) => {
  'id': id,
  'owner': 'dev_x',
  'status': status,
  'pickup_name': 'Masaki',
  'pickup_lat': -6.75,
  'pickup_lng': 39.28,
  'dropoff_name': 'Airport',
  'dropoff_lat': -6.88,
  'dropoff_lng': 39.20,
  'product_id': 'go',
  'product_name': 'TAIFA Go',
  'fare_minor': 850000,
  'currency': 'TZS',
  'driver_name': driverName,
  'vehicle_label': driverName.isEmpty
      ? ''
      : 'Silver Toyota Corolla · T 458 DSM',
  'payment_ref': paymentRef,
  'distance_meters': 12000,
  'duration_seconds': 1200,
  'created_at': '2026-07-15T00:00:00Z',
  'updated_at': '2026-07-15T00:00:00Z',
};

void main() {
  test('TripApiPaths match backend OpenAPI mount', () {
    expect(TripApiPaths.trips, 'trips/');
    expect(TripApiPaths.trip('abc'), 'trips/abc');
    expect(TripApiPaths.payment('abc'), 'trips/abc/payment');
  });

  test('RestTripRepository.create POSTs trip contract', () async {
    final client = _FakeTripsClient(postResponse: _tripJson());
    final route = RoutePlan(
      polyline: [DarPlaces.masaki.point, DarPlaces.airport.point],
      distanceMeters: 12000,
      durationSeconds: 1200,
    );
    const product = RideProduct(
      id: 'go',
      name: 'TAIFA Go',
      subtitle: 'Everyday',
      capacity: 4,
      etaMinutes: 4,
      fare: Money(850000, Currency.tzs),
      iconName: 'go',
    );

    final trip = await RestTripRepository(client).create(
      CreateTripRequest(
        pickup: DarPlaces.masaki,
        dropoff: DarPlaces.airport,
        product: product,
        fare: product.fare,
        route: route,
      ),
    );

    expect(client.lastPostPath, 'trips/');
    expect(client.lastBody!['pickup_name'], DarPlaces.masaki.name);
    expect(client.lastBody!.containsKey('fare_minor'), isFalse);
    expect(client.lastBody!['vehicle_mode'], 'taxi');
    expect(client.lastBody!['estimated_distance_meters'], 12000);
    expect(trip.id, '11111111-1111-1111-1111-111111111111');
    expect(trip.route, isNotNull);
    expect(trip.status, TripStatus.requesting);
  });

  test('RestTripRepository.update PATCHes status and driver', () async {
    final created = _tripJson();
    final client = _FakeTripsClient(
      postResponse: created,
      patchResponse: _tripJson(
        status: 'driver_en_route',
        driverName: 'Juma Ally',
      ),
    );
    final repo = RestTripRepository(client);
    final trip = await repo.create(
      CreateTripRequest(
        pickup: DarPlaces.masaki,
        dropoff: DarPlaces.airport,
        product: const RideProduct(
          id: 'go',
          name: 'TAIFA Go',
          subtitle: '',
          capacity: 4,
          etaMinutes: 4,
          fare: Money(850000, Currency.tzs),
          iconName: 'go',
        ),
        fare: const Money(850000, Currency.tzs),
      ),
    );

    final updated = await repo.update(
      trip.copyWith(
        status: TripStatus.driverEnRoute,
        driver: trip.driver, // null until we set below via patch response merge
      ),
    );

    // Force a patch with driver fields by building domain trip with driver name
    // via second update after patch response already maps driver from API.
    expect(client.lastPatchPath, 'trips/${trip.id}');
    expect(client.lastBody!['status'], 'driver_en_route');
    expect(updated.status, TripStatus.driverEnRoute);
    expect(updated.driver?.fullName, 'Juma Ally');
  });

  test('RestTripRepository.history GETs trip list', () async {
    final client = _FakeTripsClient(
      getListResponse: [
        _tripJson(id: 'a', status: 'payment_confirmed', paymentRef: 'PAY-1'),
        _tripJson(id: 'b', status: 'completed'),
      ],
    );
    final history = await RestTripRepository(client).history();
    expect(client.lastGetPath, 'trips/');
    expect(history, hasLength(2));
    expect(history.first.status, TripStatus.paymentConfirmed);
    expect(history.first.paymentRef, 'PAY-1');
  });

  test(
    'RestTripRepository.confirmPayment delegates to payment endpoint',
    () async {
      final id = '22222222-2222-2222-2222-222222222222';
      final client = _FakeTripsClient(
        postResponse: _tripJson(
          id: id,
          status: 'payment_confirmed',
          paymentRef: 'PAY-XYZ',
        ),
      );
      final paid = await RestTripRepository(client).confirmPayment(id);
      expect(client.lastPostPath, 'trips/$id/payment');
      expect(client.lastIdempotencyKey, 'mobility-payment-$id');
      expect(paid.status, TripStatus.paymentConfirmed);
    },
  );
}

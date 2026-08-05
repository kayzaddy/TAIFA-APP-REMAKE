import 'package:flutter_test/flutter_test.dart';
import 'package:taifa/features/mobility/application/map_scene_builder.dart';
import 'package:taifa/features/mobility/application/ride_providers.dart';
import 'package:taifa/features/mobility/data/dar_places.dart';
import 'package:taifa/features/mobility/domain/driver.dart';
import 'package:taifa/features/mobility/domain/geo_point.dart';
import 'package:taifa/features/mobility/domain/map_scene.dart';
import 'package:taifa/features/mobility/gateways/mock_maps_provider.dart';
import 'package:taifa/features/mobility/gateways/mock_matching_gateway.dart';
import 'package:taifa/features/mobility/gateways/mock_pricing_gateway.dart';
import 'package:taifa/features/mobility/gateways/mock_route_gateway.dart';

void main() {
  test('MockRouteGateway returns a polyline with positive distance', () async {
    final plan = await MockRouteGateway().planRoute(
      origin: DarPlaces.masaki.point,
      destination: DarPlaces.airport.point,
    );
    expect(plan.distanceMeters, greaterThan(1000));
    expect(plan.polyline.length, greaterThan(5));
    expect(plan.durationSeconds, greaterThan(60));
  });

  test('RoutePlan.pointAt interpolates along the polyline', () async {
    final plan = await MockRouteGateway().planRoute(
      origin: DarPlaces.masaki.point,
      destination: DarPlaces.airport.point,
    );
    expect(plan.pointAt(0), plan.polyline.first);
    expect(plan.pointAt(1), plan.polyline.last);
    final mid = plan.pointAt(0.5);
    expect(mid.latitude, isNot(equals(plan.polyline.first.latitude)));
    expect(mid.longitude, isNot(equals(plan.polyline.first.longitude)));
  });

  test('MockPricingGateway quotes multiple products', () async {
    final route = await MockRouteGateway().planRoute(
      origin: DarPlaces.home.point,
      destination: DarPlaces.work.point,
    );
    final quotes = await MockPricingGateway().quote(
      route: route,
      pickup: DarPlaces.home.point,
    );
    expect(quotes.length, 4);
    expect(quotes.first.total.isPositive, isTrue);
  });

  test('MockMatchingGateway assigns a driver near pickup', () async {
    final route = await MockRouteGateway().planRoute(
      origin: DarPlaces.masaki.point,
      destination: DarPlaces.kariakoo.point,
    );
    final quotes = await MockPricingGateway().quote(
      route: route,
      pickup: DarPlaces.masaki.point,
    );
    final driver = await MockMatchingGateway().matchDriver(
      pickup: DarPlaces.masaki,
      product: quotes.first.product,
    );
    expect(driver.fullName, isNotEmpty);
    expect(driver.location, isNotNull);
    expect(driver.vehicle.plate, isNotEmpty);
  });

  test('mapSceneForRide follows driver during en-route / in-trip', () {
    const driver = Driver(
      id: 'd1',
      fullName: 'Test',
      rating: 5,
      tripsCompleted: 1,
      phoneMasked: '+255',
      vehicle: Vehicle(
        id: 'v',
        make: 'Toyota',
        model: 'Corolla',
        color: 'Silver',
        plate: 'T 1',
        kind: VehicleKind.sedan,
      ),
      location: GeoPoint(-6.76, 39.22),
    );
    final scene = mapSceneForRide(
      const RideUiState(
        phase: RidePhase.enRoute,
        pickup: DarPlaces.masaki,
        dropoff: DarPlaces.airport,
        driver: driver,
      ),
    );
    expect(scene.followDriver, isTrue);
    expect(scene.effectiveCenter, driver.location);
  });

  test('mapSceneForRide exposes trip progress only inTrip', () {
    final inTrip = mapSceneForRide(
      const RideUiState(
        phase: RidePhase.inTrip,
        pickup: DarPlaces.masaki,
        tripProgress: 0.4,
      ),
    );
    expect(inTrip.progress, 0.4);

    final quoting = mapSceneForRide(
      const RideUiState(
        phase: RidePhase.quoting,
        pickup: DarPlaces.masaki,
        tripProgress: 0.4,
      ),
    );
    expect(quoting.progress, 0);
    expect(quoting.followDriver, isFalse);
  });

  test('MockMapsProvider builds a widget from MapScene', () {
    final widget = const MockMapsProvider().buildMap(
      scene: MapScene(cameraTarget: DarPlaces.masaki.point),
    );
    expect(widget, isNotNull);
  });
}

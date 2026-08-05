import 'dart:async';
import 'dart:math';

import '../domain/driver.dart';
import '../domain/geo_point.dart';
import '../domain/place.dart';
import '../domain/ride_product.dart';
import 'matching_gateway.dart';

class MockMatchingGateway implements MatchingGateway {
  final _rng = Random(42);

  static const _drivers = [
    Driver(
      id: 'drv-juma',
      fullName: 'Juma Ally',
      rating: 4.92,
      tripsCompleted: 1842,
      phoneMasked: '+255 754 ••• 210',
      photoInitial: 'J',
      vehicle: Vehicle(
        id: 'veh-1',
        make: 'Toyota',
        model: 'Corolla',
        color: 'Silver',
        plate: 'T 458 DSM',
        kind: VehicleKind.sedan,
      ),
    ),
    Driver(
      id: 'drv-neema',
      fullName: 'Neema Kileo',
      rating: 4.88,
      tripsCompleted: 964,
      phoneMasked: '+255 713 ••• 044',
      photoInitial: 'N',
      vehicle: Vehicle(
        id: 'veh-2',
        make: 'Honda',
        model: 'Fit',
        color: 'White',
        plate: 'T 902 AR',
        kind: VehicleKind.sedan,
      ),
    ),
    Driver(
      id: 'drv-baraka',
      fullName: 'Baraka Mushi',
      rating: 4.95,
      tripsCompleted: 3201,
      phoneMasked: '+255 655 ••• 118',
      photoInitial: 'B',
      vehicle: Vehicle(
        id: 'veh-3',
        make: 'Toyota',
        model: 'Noah',
        color: 'Black',
        plate: 'T 117 MBA',
        kind: VehicleKind.van,
      ),
    ),
  ];

  @override
  Future<Driver> matchDriver({
    required Place pickup,
    required RideProduct product,
  }) async {
    // Searching window — feels like a real matching delay.
    await Future<void>.delayed(const Duration(milliseconds: 2200));
    final base = _drivers[_rng.nextInt(_drivers.length)];
    final nearby = GeoPoint(
      pickup.point.latitude + (_rng.nextDouble() - 0.5) * 0.012,
      pickup.point.longitude + (_rng.nextDouble() - 0.5) * 0.012,
    );
    return Driver(
      id: base.id,
      fullName: base.fullName,
      rating: base.rating,
      tripsCompleted: base.tripsCompleted,
      vehicle: product.id == 'boda'
          ? const Vehicle(
              id: 'veh-boda',
              make: 'Bajaj',
              model: 'Boxer',
              color: 'Red',
              plate: 'MC 221 TZ',
              kind: VehicleKind.boda,
            )
          : product.id == 'xl'
          ? base.vehicle.copyAsSuv()
          : base.vehicle,
      phoneMasked: base.phoneMasked,
      photoInitial: base.photoInitial,
      location: nearby,
    );
  }

  @override
  Stream<GeoPoint> trackDriver(
    String driverId, {
    required GeoPoint toward,
  }) async* {
    var current = GeoPoint(toward.latitude + 0.01, toward.longitude - 0.008);
    const steps = 12;
    for (var i = 1; i <= steps; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 450));
      final t = i / steps;
      current = GeoPoint(
        current.latitude +
            (toward.latitude - current.latitude) * (1 / (steps - i + 1)),
        current.longitude +
            (toward.longitude - current.longitude) * (1 / (steps - i + 1)),
      );
      // Ease toward destination
      current = GeoPoint(
        (1 - t) * current.latitude + t * toward.latitude,
        (1 - t) * current.longitude + t * toward.longitude,
      );
      yield current;
    }
    yield toward;
  }
}

extension on Vehicle {
  Vehicle copyAsSuv() => Vehicle(
    id: id,
    make: 'Toyota',
    model: 'Land Cruiser Prado',
    color: color,
    plate: plate,
    kind: VehicleKind.suv,
  );
}

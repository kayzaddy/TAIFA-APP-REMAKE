import '../domain/driver.dart';
import '../domain/geo_point.dart';
import '../domain/place.dart';
import '../domain/ride_product.dart';

/// Dispatch / matching. Production later: real driver network.
abstract interface class MatchingGateway {
  /// Simulates searching then assigning a nearby driver.
  Future<Driver> matchDriver({
    required Place pickup,
    required RideProduct product,
  });

  Stream<GeoPoint> trackDriver(String driverId, {required GeoPoint toward});
}

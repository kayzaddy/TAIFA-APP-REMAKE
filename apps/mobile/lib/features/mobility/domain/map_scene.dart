import 'geo_point.dart';
import 'route_plan.dart';

/// Provider-agnostic description of what the map should show.
///
/// Ride UI builds a [MapScene]; a [MapsProvider] binds it to CustomPaint,
/// Google Maps, Mapbox, etc. without leaking SDK types into business logic.
class MapScene {
  const MapScene({
    required this.cameraTarget,
    this.route,
    this.pickup,
    this.dropoff,
    this.driver,
    this.progress = 0,
    this.followDriver = false,
  });

  /// Camera / projection center. When [followDriver] is true and [driver] is
  /// set, providers should prefer tracking the driver.
  final GeoPoint cameraTarget;
  final RoutePlan? route;
  final GeoPoint? pickup;
  final GeoPoint? dropoff;
  final GeoPoint? driver;

  /// 0..1 trip progress along [route] (in-trip live tracking).
  final double progress;
  final bool followDriver;

  GeoPoint get effectiveCenter {
    if (followDriver && driver != null) return driver!;
    return cameraTarget;
  }
}

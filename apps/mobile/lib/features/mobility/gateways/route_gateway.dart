import '../domain/geo_point.dart';
import '../domain/route_plan.dart';

/// Routing / distance matrix. Production later: Google Directions / Mapbox.
abstract interface class RouteGateway {
  Future<RoutePlan> planRoute({
    required GeoPoint origin,
    required GeoPoint destination,
  });
}

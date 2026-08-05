import '../domain/geo_point.dart';
import '../domain/ride_product.dart';
import '../domain/route_plan.dart';

/// Fare + ETA quotes for ride products.
abstract interface class PricingGateway {
  Future<List<FareEstimate>> quote({
    required RoutePlan route,
    required GeoPoint pickup,
  });
}

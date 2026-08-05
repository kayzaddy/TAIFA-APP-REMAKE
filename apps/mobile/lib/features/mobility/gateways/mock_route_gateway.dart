import 'dart:math';

import '../domain/geo_point.dart';
import '../domain/route_plan.dart';
import 'route_gateway.dart';

class MockRouteGateway implements RouteGateway {
  @override
  Future<RoutePlan> planRoute({
    required GeoPoint origin,
    required GeoPoint destination,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 420));
    final dist = _haversine(origin, destination).round();
    // City traffic: ~22 km/h average → seconds.
    final duration = max(180, (dist / 6.1).round());
    final steps = max(8, min(32, dist ~/ 180));
    final polyline = <GeoPoint>[
      for (var i = 0; i <= steps; i++)
        GeoPoint(
          origin.latitude +
              (destination.latitude - origin.latitude) * (i / steps) +
              sin(i / steps * pi) * 0.0012,
          origin.longitude +
              (destination.longitude - origin.longitude) * (i / steps) +
              cos(i / steps * pi) * 0.0008,
        ),
    ];
    return RoutePlan(
      polyline: polyline,
      distanceMeters: dist,
      durationSeconds: duration,
    );
  }

  static double _haversine(GeoPoint a, GeoPoint b) {
    const r = 6371000.0;
    final dLat = (b.latitude - a.latitude) * pi / 180;
    final dLon = (b.longitude - a.longitude) * pi / 180;
    final la1 = a.latitude * pi / 180;
    final la2 = b.latitude * pi / 180;
    final h =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(la1) * cos(la2) * sin(dLon / 2) * sin(dLon / 2);
    return 2 * r * asin(min(1.0, sqrt(h)));
  }
}

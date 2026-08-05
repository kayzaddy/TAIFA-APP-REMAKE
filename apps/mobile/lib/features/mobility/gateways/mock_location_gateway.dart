import 'dart:math';

import '../domain/geo_point.dart';
import '../domain/place.dart';
import '../gateways/location_gateway.dart';
import '../data/dar_places.dart';

class MockLocationGateway implements LocationGateway {
  MockLocationGateway({GeoPoint? start})
    : _current = start ?? DarPlaces.masaki.point;

  GeoPoint _current;
  final _rng = Random(7);

  @override
  Future<GeoPoint> currentLocation() async {
    await Future<void>.delayed(const Duration(milliseconds: 280));
    // Tiny jitter so the pin feels "live".
    _current = GeoPoint(
      _current.latitude + (_rng.nextDouble() - 0.5) * 0.0002,
      _current.longitude + (_rng.nextDouble() - 0.5) * 0.0002,
    );
    return _current;
  }

  @override
  Future<Place> reverseGeocode(GeoPoint point) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    Place? best;
    var bestDist = double.infinity;
    for (final p in DarPlaces.all) {
      final d = _haversine(point, p.point);
      if (d < bestDist) {
        bestDist = d;
        best = p;
      }
    }
    return best ??
        Place(
          id: 'plc-here',
          name: 'Current location',
          subtitle:
              '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}',
          point: point,
        );
  }

  @override
  Future<List<Place>> search(String query, {GeoPoint? near}) async {
    await Future<void>.delayed(const Duration(milliseconds: 320));
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return DarPlaces.all.take(5).toList();
    return DarPlaces.all
        .where(
          (p) =>
              p.name.toLowerCase().contains(q) ||
              p.subtitle.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Future<List<Place>> savedPlaces() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return const [DarPlaces.home, DarPlaces.work, DarPlaces.airport];
  }

  static double _haversine(GeoPoint a, GeoPoint b) {
    const r = 6371000.0;
    final dLat = _rad(b.latitude - a.latitude);
    final dLon = _rad(b.longitude - a.longitude);
    final la1 = _rad(a.latitude);
    final la2 = _rad(b.latitude);
    final h =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(la1) * cos(la2) * sin(dLon / 2) * sin(dLon / 2);
    return 2 * r * asin(min(1, sqrt(h)));
  }

  static double _rad(double d) => d * pi / 180;
}

import 'geo_point.dart';

/// A computed driving/biking path between two places.
class RoutePlan {
  const RoutePlan({
    required this.polyline,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  final List<GeoPoint> polyline;
  final int distanceMeters;
  final int durationSeconds;

  double get distanceKm => distanceMeters / 1000.0;

  String get distanceLabel {
    if (distanceMeters < 1000) return '${distanceMeters}m';
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  String get durationLabel {
    final m = (durationSeconds / 60).round().clamp(1, 999);
    if (m < 60) return '$m min';
    final h = m ~/ 60;
    final rem = m % 60;
    return rem == 0 ? '${h}h' : '${h}h ${rem}m';
  }

  /// Point at fraction [t] (0..1) along the polyline, linearly between vertices.
  GeoPoint pointAt(double t) {
    if (polyline.isEmpty) {
      return const GeoPoint(0, 0);
    }
    if (polyline.length == 1) return polyline.first;
    final clamped = t.clamp(0.0, 1.0);
    final maxIndex = polyline.length - 1;
    final scaled = clamped * maxIndex;
    final i = scaled.floor().clamp(0, maxIndex - 1);
    final local = scaled - i;
    final a = polyline[i];
    final b = polyline[i + 1];
    return GeoPoint(
      a.latitude + (b.latitude - a.latitude) * local,
      a.longitude + (b.longitude - a.longitude) * local,
    );
  }
}

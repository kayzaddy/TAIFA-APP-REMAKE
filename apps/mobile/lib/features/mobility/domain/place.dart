import 'geo_point.dart';

/// A named place (pickup, destination, or search result).
class Place {
  const Place({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.point,
    this.kind = PlaceKind.generic,
  });

  final String id;
  final String name;
  final String subtitle;
  final GeoPoint point;
  final PlaceKind kind;
}

enum PlaceKind { generic, home, work, landmark, airport, hotel }

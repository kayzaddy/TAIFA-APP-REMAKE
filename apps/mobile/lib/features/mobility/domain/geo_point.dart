/// Geographic coordinate used by location, routing, and map projection.
/// Independent of any maps SDK — a real Google/Mapbox adapter can map to its
/// native types later without changing business logic.
class GeoPoint {
  const GeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  @override
  bool operator ==(Object other) =>
      other is GeoPoint &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => '($latitude, $longitude)';
}

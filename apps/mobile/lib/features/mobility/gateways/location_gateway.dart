import '../domain/geo_point.dart';
import '../domain/place.dart';

/// Device / session location. Production later: GPS + Places SDK.
abstract interface class LocationGateway {
  Future<GeoPoint> currentLocation();
  Future<Place> reverseGeocode(GeoPoint point);
  Future<List<Place>> search(String query, {GeoPoint? near});
  Future<List<Place>> savedPlaces();
}

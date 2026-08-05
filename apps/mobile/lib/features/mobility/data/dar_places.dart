import '../domain/geo_point.dart';
import '../domain/place.dart';

/// Canonical demo places around Dar es Salaam — shared by mocks + UI.
class DarPlaces {
  const DarPlaces._();

  static const masaki = Place(
    id: 'plc-masaki',
    name: 'Masaki Peninsula',
    subtitle: 'Oyster Bay · Dar es Salaam',
    point: GeoPoint(-6.7490, 39.2830),
    kind: PlaceKind.landmark,
  );

  static const kariakoo = Place(
    id: 'plc-kariakoo',
    name: 'Kariakoo Market',
    subtitle: 'Ilala · Dar es Salaam',
    point: GeoPoint(-6.8210, 39.2740),
    kind: PlaceKind.landmark,
  );

  static const airport = Place(
    id: 'plc-jnia',
    name: 'Julius Nyerere Airport',
    subtitle: 'JNIA · Terminal 3',
    point: GeoPoint(-6.8781, 39.2026),
    kind: PlaceKind.airport,
  );

  static const postOffice = Place(
    id: 'plc-cpo',
    name: 'Askari Monument',
    subtitle: 'City Centre · Dar es Salaam',
    point: GeoPoint(-6.8160, 39.2803),
    kind: PlaceKind.landmark,
  );

  static const mlimani = Place(
    id: 'plc-mlimani',
    name: 'Mlimani City Mall',
    subtitle: 'Ubungo · Dar es Salaam',
    point: GeoPoint(-6.7726, 39.2410),
    kind: PlaceKind.landmark,
  );

  static const home = Place(
    id: 'plc-home',
    name: 'Home',
    subtitle: 'Mikocheni · Saved address',
    point: GeoPoint(-6.7655, 39.2585),
    kind: PlaceKind.home,
  );

  static const work = Place(
    id: 'plc-work',
    name: 'Work',
    subtitle: 'Golden Jubilee Tower · CBD',
    point: GeoPoint(-6.8147, 39.2890),
    kind: PlaceKind.work,
  );

  static const all = [
    masaki,
    kariakoo,
    airport,
    postOffice,
    mlimani,
    home,
    work,
  ];
}

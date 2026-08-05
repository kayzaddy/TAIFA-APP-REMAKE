import 'geo_point.dart';

class Vehicle {
  const Vehicle({
    required this.id,
    required this.make,
    required this.model,
    required this.color,
    required this.plate,
    required this.kind,
  });

  final String id;
  final String make;
  final String model;
  final String color;
  final String plate;
  final VehicleKind kind;

  String get displayName => '$color $make $model';
}

enum VehicleKind { sedan, suv, van, boda }

class Driver {
  const Driver({
    required this.id,
    required this.fullName,
    required this.rating,
    required this.tripsCompleted,
    required this.vehicle,
    required this.phoneMasked,
    this.photoInitial = 'D',
    this.location,
  });

  final String id;
  final String fullName;
  final double rating;
  final int tripsCompleted;
  final Vehicle vehicle;
  final String phoneMasked;
  final String photoInitial;
  final GeoPoint? location;

  Driver copyWith({GeoPoint? location}) {
    return Driver(
      id: id,
      fullName: fullName,
      rating: rating,
      tripsCompleted: tripsCompleted,
      vehicle: vehicle,
      phoneMasked: phoneMasked,
      photoInitial: photoInitial,
      location: location ?? this.location,
    );
  }
}

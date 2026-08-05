import '../../wallet/domain/money.dart';
import 'driver.dart';
import 'place.dart';
import 'ride_product.dart';
import 'route_plan.dart';

/// Lifecycle of a passenger trip. Terminal: completed | cancelled.
enum TripStatus {
  draft,
  requesting,
  searching,
  driverAssigned,
  driverEnRoute,
  driverArrived,
  inProgress,
  completed,
  cancelled,
  paymentConfirmed,
}

extension TripStatusX on TripStatus {
  bool get isActive =>
      this == TripStatus.searching ||
      this == TripStatus.driverAssigned ||
      this == TripStatus.driverEnRoute ||
      this == TripStatus.driverArrived ||
      this == TripStatus.inProgress;

  bool get isTerminal =>
      this == TripStatus.completed ||
      this == TripStatus.cancelled ||
      this == TripStatus.paymentConfirmed;

  String get label => switch (this) {
    TripStatus.draft => 'Draft',
    TripStatus.requesting => 'Requesting',
    TripStatus.searching => 'Finding your driver',
    TripStatus.driverAssigned => 'Driver assigned',
    TripStatus.driverEnRoute => 'Driver on the way',
    TripStatus.driverArrived => 'Driver has arrived',
    TripStatus.inProgress => 'Trip in progress',
    TripStatus.completed => 'Trip completed',
    TripStatus.cancelled => 'Cancelled',
    TripStatus.paymentConfirmed => 'Paid',
  };
}

class Trip {
  const Trip({
    required this.id,
    required this.status,
    required this.pickup,
    required this.dropoff,
    required this.product,
    required this.fare,
    required this.createdAt,
    this.route,
    this.driver,
    this.etaMinutes,
    this.startedAt,
    this.completedAt,
    this.paymentRef,
    this.distanceMeters,
    this.durationSeconds,
  });

  final String id;
  final TripStatus status;
  final Place pickup;
  final Place dropoff;
  final RideProduct product;
  final Money fare;
  final DateTime createdAt;
  final RoutePlan? route;
  final Driver? driver;
  final int? etaMinutes;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? paymentRef;
  final int? distanceMeters;
  final int? durationSeconds;

  Trip copyWith({
    TripStatus? status,
    RoutePlan? route,
    Driver? driver,
    int? etaMinutes,
    DateTime? startedAt,
    DateTime? completedAt,
    String? paymentRef,
    int? distanceMeters,
    int? durationSeconds,
  }) {
    return Trip(
      id: id,
      status: status ?? this.status,
      pickup: pickup,
      dropoff: dropoff,
      product: product,
      fare: fare,
      createdAt: createdAt,
      route: route ?? this.route,
      driver: driver ?? this.driver,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      paymentRef: paymentRef ?? this.paymentRef,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      durationSeconds: durationSeconds ?? this.durationSeconds,
    );
  }
}

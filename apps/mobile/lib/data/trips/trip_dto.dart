import '../../features/mobility/domain/driver.dart';
import '../../features/mobility/domain/geo_point.dart';
import '../../features/mobility/domain/place.dart';
import '../../features/mobility/domain/ride_product.dart';
import '../../features/mobility/domain/route_plan.dart';
import '../../features/mobility/domain/trip.dart';
import '../../features/wallet/domain/currency.dart';
import '../../features/wallet/domain/money.dart';

/// Maps `/api/v1/trips` JSON ↔ domain [Trip].
///
/// The API stores a flat summary (no polyline / full driver). Callers can pass
/// [route] / [driver] overlays from an in-memory cache during an active ride.
class TripDto {
  const TripDto._();

  static Trip toDomain(
    Map<String, dynamic> json, {
    RoutePlan? route,
    Driver? driver,
  }) {
    final currency = Currency.fromCode(json['currency'] as String? ?? 'TZS');
    final fareMinor = (json['fare_minor'] as num?)?.toInt() ?? 0;
    final productId = json['product_id'] as String? ?? 'go';
    final productName = json['product_name'] as String? ?? 'Ride';
    final pickup = Place(
      id: 'pickup-${json['id']}',
      name: json['pickup_name'] as String? ?? 'Pickup',
      subtitle: '',
      point: GeoPoint(_double(json['pickup_lat']), _double(json['pickup_lng'])),
    );
    final dropoff = Place(
      id: 'dropoff-${json['id']}',
      name: json['dropoff_name'] as String? ?? 'Dropoff',
      subtitle: '',
      point: GeoPoint(
        _double(json['dropoff_lat']),
        _double(json['dropoff_lng']),
      ),
    );

    final driverName = (json['driver_name'] as String?)?.trim() ?? '';
    final vehicleLabel = (json['vehicle_label'] as String?)?.trim() ?? '';
    final resolvedDriver =
        driver ??
        (driverName.isEmpty
            ? null
            : Driver(
                id: 'drv-${json['id']}',
                fullName: driverName,
                rating: 4.9,
                tripsCompleted: 0,
                phoneMasked: '',
                photoInitial: driverName.isNotEmpty ? driverName[0] : 'D',
                vehicle: _vehicleFromLabel(vehicleLabel),
              ));

    final paymentRef = (json['payment_ref'] as String?)?.trim();
    return Trip(
      id: json['id'].toString(),
      status: statusFromApi(json['status'] as String? ?? 'requested'),
      pickup: pickup,
      dropoff: dropoff,
      product: RideProduct(
        id: productId,
        name: productName,
        subtitle: '',
        capacity: 4,
        etaMinutes: 5,
        fare: Money(fareMinor, currency),
        iconName: productId,
      ),
      fare: Money(fareMinor, currency),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      route: route,
      driver: resolvedDriver,
      paymentRef: (paymentRef == null || paymentRef.isEmpty)
          ? null
          : paymentRef,
      distanceMeters: (json['distance_meters'] as num?)?.toInt(),
      durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
    );
  }

  static Map<String, dynamic> createBody({
    required Place pickup,
    required Place dropoff,
    required RideProduct product,
    int distanceMeters = 0,
    int durationSeconds = 0,
    String paymentMethod = 'wallet',
    String region = '',
    bool hybridSmsDemo = false,
    String passengerMsisdn = '',
  }) {
    return {
      'pickup_name': pickup.name,
      'pickup_lat': pickup.point.latitude,
      'pickup_lng': pickup.point.longitude,
      'dropoff_name': dropoff.name,
      'dropoff_lat': dropoff.point.latitude,
      'dropoff_lng': dropoff.point.longitude,
      'vehicle_mode': _vehicleMode(product.id),
      'region': region,
      'estimated_distance_meters': distanceMeters,
      'estimated_duration_seconds': durationSeconds,
      'payment_method': paymentMethod,
      if (hybridSmsDemo) 'hybrid_sms_demo': true,
      if (passengerMsisdn.isNotEmpty) 'passenger_msisdn': passengerMsisdn,
    };
  }

  static Map<String, dynamic> patchBody(Trip trip) {
    return <String, dynamic>{'status': statusToApi(trip.status)};
  }

  static String statusToApi(TripStatus status) => switch (status) {
    TripStatus.draft || TripStatus.requesting => 'requested',
    TripStatus.searching => 'searching',
    TripStatus.driverAssigned => 'driver_assigned',
    TripStatus.driverEnRoute => 'driver_en_route',
    TripStatus.driverArrived => 'driver_arrived',
    TripStatus.inProgress => 'in_progress',
    TripStatus.completed => 'completed',
    TripStatus.cancelled => 'cancelled',
    TripStatus.paymentConfirmed => 'payment_confirmed',
  };

  static TripStatus statusFromApi(String raw) => switch (raw) {
    'searching' => TripStatus.searching,
    'requested' => TripStatus.requesting,
    'driver_assigned' => TripStatus.driverAssigned,
    'driver_en_route' => TripStatus.driverEnRoute,
    'driver_arrived' => TripStatus.driverArrived,
    'arrived' => TripStatus.driverArrived,
    'passenger_boarded' => TripStatus.driverArrived,
    'trip_started' => TripStatus.inProgress,
    'in_progress' => TripStatus.inProgress,
    'completed' => TripStatus.completed,
    'cancelled' => TripStatus.cancelled,
    'payment_confirmed' => TripStatus.paymentConfirmed,
    'settled' => TripStatus.paymentConfirmed,
    'payment_pending' => TripStatus.completed,
    _ => TripStatus.requesting,
  };

  static double _double(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _vehicleMode(String productId) => switch (productId) {
    'boda' || 'motorcycle' => 'motorcycle',
    'bajaji' => 'bajaji',
    'xl' || 'van' => 'van',
    'pickup' => 'pickup',
    'truck' => 'truck',
    'bus' => 'bus',
    'ev' || 'electric_vehicle' => 'electric_vehicle',
    'comfort' => 'private_car',
    _ => 'taxi',
  };

  static Vehicle _vehicleFromLabel(String label) {
    if (label.isEmpty) {
      return const Vehicle(
        id: 'veh-unknown',
        make: 'Vehicle',
        model: '',
        color: '',
        plate: '',
        kind: VehicleKind.sedan,
      );
    }
    // "Silver Toyota Corolla · T 458 DSM"
    final parts = label.split(' · ');
    final plate = parts.length > 1 ? parts.last.trim() : '';
    final head = parts.first.trim().split(RegExp(r'\s+'));
    final color = head.isNotEmpty ? head.first : '';
    final make = head.length > 1 ? head[1] : 'Vehicle';
    final model = head.length > 2 ? head.sublist(2).join(' ') : '';
    return Vehicle(
      id: 'veh-$plate',
      make: make,
      model: model,
      color: color,
      plate: plate,
      kind: VehicleKind.sedan,
    );
  }
}

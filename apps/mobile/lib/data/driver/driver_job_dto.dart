import '../../features/driver/domain/driver_models.dart';
import '../../features/wallet/domain/currency.dart';
import '../../features/wallet/domain/money.dart';

/// Maps `/api/v1/commerce/driver-jobs` JSON ↔ domain [DriverJob].
class DriverJobDto {
  const DriverJobDto._();

  static DriverJob toDomain(Map<String, dynamic> json) {
    final currency = Currency.fromCode(json['currency'] as String? ?? 'TZS');
    return DriverJob(
      id: json['id'].toString(),
      riderName: json['rider_name'] as String? ?? '',
      pickup: json['pickup'] as String? ?? '',
      dropoff: json['dropoff'] as String? ?? '',
      fare: Money((json['fare_minor'] as num?)?.toInt() ?? 0, currency),
      etaMinutes: (json['eta_minutes'] as num?)?.toInt() ?? 5,
      status: statusFromApi(json['status'] as String? ?? 'offered'),
    );
  }

  static Map<String, dynamic> createBody(DriverJob job) => {
    'rider_name': job.riderName,
    'pickup': job.pickup,
    'dropoff': job.dropoff,
    'fare_minor': job.fare.minorUnits,
    'currency': job.fare.currency.code,
    'eta_minutes': job.etaMinutes,
    'status': statusToApi(job.status),
  };

  static Map<String, dynamic> patchBody(DriverJob job) => {
    'status': statusToApi(job.status),
  };

  static String statusToApi(DriverJobStatus status) => switch (status) {
    DriverJobStatus.offered => 'offered',
    DriverJobStatus.accepted => 'accepted',
    DriverJobStatus.enRoute => 'en_route',
    DriverJobStatus.arrived => 'arrived',
    DriverJobStatus.inTrip => 'in_trip',
    DriverJobStatus.completed => 'completed',
    DriverJobStatus.declined => 'declined',
  };

  static DriverJobStatus statusFromApi(String raw) => switch (raw) {
    'accepted' => DriverJobStatus.accepted,
    'en_route' => DriverJobStatus.enRoute,
    'arrived' => DriverJobStatus.arrived,
    'in_trip' => DriverJobStatus.inTrip,
    'completed' => DriverJobStatus.completed,
    'declined' => DriverJobStatus.declined,
    _ => DriverJobStatus.offered,
  };
}

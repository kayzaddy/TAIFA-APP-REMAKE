import '../../wallet/domain/money.dart';

enum DriverJobStatus {
  offered,
  accepted,
  enRoute,
  arrived,
  inTrip,
  completed,
  declined,
}

extension DriverJobStatusX on DriverJobStatus {
  String get label => switch (this) {
    DriverJobStatus.offered => 'Offer',
    DriverJobStatus.accepted => 'Accepted',
    DriverJobStatus.enRoute => 'En route',
    DriverJobStatus.arrived => 'Arrived',
    DriverJobStatus.inTrip => 'Trip',
    DriverJobStatus.completed => 'Completed',
    DriverJobStatus.declined => 'Declined',
  };
}

class DriverJob {
  const DriverJob({
    required this.id,
    required this.riderName,
    required this.pickup,
    required this.dropoff,
    required this.fare,
    required this.etaMinutes,
    required this.status,
  });

  final String id;
  final String riderName;
  final String pickup;
  final String dropoff;
  final Money fare;
  final int etaMinutes;
  final DriverJobStatus status;

  DriverJob copyWith({DriverJobStatus? status}) => DriverJob(
    id: id,
    riderName: riderName,
    pickup: pickup,
    dropoff: dropoff,
    fare: fare,
    etaMinutes: etaMinutes,
    status: status ?? this.status,
  );
}

import '../../wallet/domain/money.dart';

class HealthFacility {
  const HealthFacility({
    required this.id,
    required this.name,
    required this.area,
    required this.specialty,
    required this.rating,
    required this.consultFee,
  });

  final String id;
  final String name;
  final String area;
  final String specialty;
  final double rating;
  final Money consultFee;
}

enum AppointmentStatus { drafting, booked, confirmed, paid, cancelled }

extension AppointmentStatusX on AppointmentStatus {
  String get label => switch (this) {
    AppointmentStatus.drafting => 'Draft',
    AppointmentStatus.booked => 'Booked',
    AppointmentStatus.confirmed => 'Confirmed',
    AppointmentStatus.paid => 'Paid',
    AppointmentStatus.cancelled => 'Cancelled',
  };
}

class HealthAppointment {
  const HealthAppointment({
    required this.id,
    required this.facility,
    required this.slot,
    required this.patientName,
    required this.fee,
    required this.status,
    required this.createdAt,
    this.confirmationCode,
    this.paymentRef,
  });

  final String id;
  final HealthFacility facility;
  final DateTime slot;
  final String patientName;
  final Money fee;
  final AppointmentStatus status;
  final DateTime createdAt;
  final String? confirmationCode;
  final String? paymentRef;

  HealthAppointment copyWith({
    AppointmentStatus? status,
    String? confirmationCode,
    String? paymentRef,
  }) {
    return HealthAppointment(
      id: id,
      facility: facility,
      slot: slot,
      patientName: patientName,
      fee: fee,
      status: status ?? this.status,
      createdAt: createdAt,
      confirmationCode: confirmationCode ?? this.confirmationCode,
      paymentRef: paymentRef ?? this.paymentRef,
    );
  }
}

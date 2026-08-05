import '../../features/health/data/health_catalog.dart';
import '../../features/health/domain/health_models.dart';
import '../../features/wallet/domain/currency.dart';
import '../../features/wallet/domain/money.dart';

/// Maps `/api/v1/commerce/health-appointments` JSON ↔ domain [HealthAppointment].
class HealthAppointmentDto {
  const HealthAppointmentDto._();

  static HealthAppointment toDomain(
    Map<String, dynamic> json, {
    HealthFacility? facility,
  }) {
    final currency = Currency.fromCode(json['currency'] as String? ?? 'TZS');
    final facilityId = json['facility_id'] as String? ?? '';
    final fee = Money((json['fee_minor'] as num?)?.toInt() ?? 0, currency);
    final conf = (json['confirmation_code'] as String?)?.trim();
    final pay = (json['payment_ref'] as String?)?.trim();

    return HealthAppointment(
      id: json['id'].toString(),
      facility:
          facility ??
          _resolveFacility(
            facilityId,
            json['facility_name'] as String? ?? 'Facility',
            json['area'] as String? ?? '',
            json['specialty'] as String? ?? '',
            fee,
          ),
      slot:
          DateTime.tryParse(json['slot_at'] as String? ?? '') ?? DateTime.now(),
      patientName: json['patient_name'] as String? ?? '',
      fee: fee,
      status: statusFromApi(json['status'] as String? ?? 'confirmed'),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      confirmationCode: (conf == null || conf.isEmpty) ? null : conf,
      paymentRef: (pay == null || pay.isEmpty) ? null : pay,
    );
  }

  static Map<String, dynamic> createBody(
    HealthAppointment draft, {
    String? confirmationCode,
  }) => {
    'facility_id': draft.facility.id,
    'facility_name': draft.facility.name,
    'specialty': draft.facility.specialty,
    'area': draft.facility.area,
    'patient_name': draft.patientName,
    'slot_at': draft.slot.toUtc().toIso8601String(),
    'fee_minor': draft.fee.minorUnits,
    'currency': draft.fee.currency.code,
    if (confirmationCode != null && confirmationCode.isNotEmpty)
      'confirmation_code': confirmationCode,
  };

  static Map<String, dynamic> patchBody(HealthAppointment appointment) {
    final body = <String, dynamic>{'status': statusToApi(appointment.status)};
    if (appointment.confirmationCode != null &&
        appointment.confirmationCode!.isNotEmpty) {
      body['confirmation_code'] = appointment.confirmationCode;
    }
    return body;
  }

  static String statusToApi(AppointmentStatus status) => switch (status) {
    AppointmentStatus.drafting || AppointmentStatus.booked => 'booked',
    AppointmentStatus.confirmed => 'confirmed',
    AppointmentStatus.paid => 'paid',
    AppointmentStatus.cancelled => 'cancelled',
  };

  static AppointmentStatus statusFromApi(String raw) => switch (raw) {
    'booked' => AppointmentStatus.booked,
    'paid' => AppointmentStatus.paid,
    'cancelled' => AppointmentStatus.cancelled,
    _ => AppointmentStatus.confirmed,
  };

  static HealthFacility _resolveFacility(
    String id,
    String name,
    String area,
    String specialty,
    Money fee,
  ) {
    try {
      return HealthCatalog.all().firstWhere((f) => f.id == id);
    } catch (_) {
      return HealthFacility(
        id: id.isEmpty ? 'hlt-unknown' : id,
        name: name,
        area: area,
        specialty: specialty,
        rating: 4.5,
        consultFee: fee,
      );
    }
  }
}

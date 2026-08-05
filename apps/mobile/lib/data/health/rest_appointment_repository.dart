import '../../features/health/application/health_repository.dart';
import '../../features/health/domain/health_models.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import 'health_api_paths.dart';
import 'health_appointment_dto.dart';

/// Live [AppointmentRepository]: persists consults on `/commerce/health-appointments`.
/// Facility catalog stays client-side; the API stores durable appointment summaries.
class RestAppointmentRepository implements AppointmentRepository {
  RestAppointmentRepository(this._client);

  final TaifaApiClient _client;
  final Map<String, HealthFacility> _facilities = {};
  int _codeSeq = 0;

  @override
  Future<HealthAppointment> book(HealthAppointment draft) async {
    try {
      _codeSeq++;
      final code = draft.confirmationCode ?? 'HL-${1000 + _codeSeq * 13}';
      final json = await _client.postJson(
        HealthApiPaths.healthAppointments,
        body: HealthAppointmentDto.createBody(draft, confirmationCode: code),
      );
      final apt = HealthAppointmentDto.toDomain(
        json,
        facility: draft.facility,
      ).copyWith(status: AppointmentStatus.confirmed, confirmationCode: code);
      _facilities[apt.id] = draft.facility;
      if ((json['confirmation_code'] as String?)?.trim().isEmpty ?? true) {
        return _patch(apt);
      }
      return apt;
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<HealthAppointment> pay(String id) async {
    try {
      final json = await _client.postJson(
        HealthApiPaths.appointmentPay(id),
        body: const {},
        idempotencyKey: 'health-pay-$id',
      );
      return HealthAppointmentDto.toDomain(json, facility: _facilities[id]);
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<List<HealthAppointment>> history() async {
    try {
      final list = await _client.getJsonList(HealthApiPaths.healthAppointments);
      return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).map(
        (json) {
          final id = json['id'].toString();
          return HealthAppointmentDto.toDomain(json, facility: _facilities[id]);
        },
      ).toList();
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  Future<HealthAppointment> _patch(HealthAppointment appointment) async {
    try {
      final json = await _client.patchJson(
        HealthApiPaths.healthAppointment(appointment.id),
        body: HealthAppointmentDto.patchBody(appointment),
      );
      _facilities[appointment.id] = appointment.facility;
      return HealthAppointmentDto.toDomain(
        json,
        facility: appointment.facility,
      );
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  String _message(ApiException e) => switch (e) {
    NetworkException() => e.message,
    ApiStatusException(:final message) => message,
    ApiDecodeException() => e.message,
  };
}

import '../../features/education/application/education_repository.dart';
import '../../features/education/domain/education_models.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import 'edu_payment_dto.dart';
import 'education_api_paths.dart';

/// Live [EduPaymentRepository]: persists invoices on `/commerce/edu-payments`.
/// School catalog stays client-side.
class RestEduPaymentRepository implements EduPaymentRepository {
  RestEduPaymentRepository(this._client);

  final TaifaApiClient _client;
  final Map<String, School> _schools = {};
  int _seq = 0;

  @override
  Future<EduPayment> invoice(EduPayment draft) async {
    try {
      _seq++;
      final invoiceNo = draft.invoiceNo ?? 'INV-EDU-${3000 + _seq}';
      final json = await _client.postJson(
        EducationApiPaths.eduPayments,
        body: EduPaymentDto.createBody(draft, invoiceNo: invoiceNo),
      );
      final payment = EduPaymentDto.toDomain(
        json,
        school: draft.school,
      ).copyWith(status: EduPaymentStatus.invoiced, invoiceNo: invoiceNo);
      _schools[payment.id] = draft.school;
      if ((json['invoice_no'] as String?)?.trim().isEmpty ?? true) {
        return _patch(payment);
      }
      return payment;
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<EduPayment> pay(String id) async {
    try {
      final json = await _client.postJson(
        EducationApiPaths.eduPaymentPay(id),
        body: const {},
        idempotencyKey: 'edu-pay-$id',
      );
      return EduPaymentDto.toDomain(json, school: _schools[id]);
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<List<EduPayment>> history() async {
    try {
      final list = await _client.getJsonList(EducationApiPaths.eduPayments);
      return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).map(
        (json) {
          final id = json['id'].toString();
          return EduPaymentDto.toDomain(json, school: _schools[id]);
        },
      ).toList();
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  Future<EduPayment> _patch(EduPayment payment) async {
    try {
      final json = await _client.patchJson(
        EducationApiPaths.eduPayment(payment.id),
        body: EduPaymentDto.patchBody(payment),
      );
      _schools[payment.id] = payment.school;
      return EduPaymentDto.toDomain(json, school: payment.school);
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

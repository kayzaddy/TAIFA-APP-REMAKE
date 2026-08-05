import '../../features/education/data/education_catalog.dart';
import '../../features/education/domain/education_models.dart';
import '../../features/wallet/domain/currency.dart';
import '../../features/wallet/domain/money.dart';

/// Maps `/api/v1/commerce/edu-payments` JSON ↔ domain [EduPayment].
class EduPaymentDto {
  const EduPaymentDto._();

  static EduPayment toDomain(Map<String, dynamic> json, {School? school}) {
    final currency = Currency.fromCode(json['currency'] as String? ?? 'TZS');
    final schoolId = json['school_id'] as String? ?? '';
    final amount = Money(
      (json['amount_minor'] as num?)?.toInt() ?? 0,
      currency,
    );
    final inv = (json['invoice_no'] as String?)?.trim();
    final pay = (json['payment_ref'] as String?)?.trim();

    return EduPayment(
      id: json['id'].toString(),
      school:
          school ??
          _resolveSchool(
            schoolId,
            json['school_name'] as String? ?? 'School',
            json['level'] as String? ?? '',
            json['area'] as String? ?? '',
            amount,
          ),
      studentName: json['student_name'] as String? ?? '',
      amount: amount,
      status: statusFromApi(json['status'] as String? ?? 'invoiced'),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      invoiceNo: (inv == null || inv.isEmpty) ? null : inv,
      paymentRef: (pay == null || pay.isEmpty) ? null : pay,
    );
  }

  static Map<String, dynamic> createBody(
    EduPayment draft, {
    String? invoiceNo,
  }) => {
    'school_id': draft.school.id,
    'school_name': draft.school.name,
    'level': draft.school.level,
    'area': draft.school.area,
    'student_name': draft.studentName,
    'amount_minor': draft.amount.minorUnits,
    'currency': draft.amount.currency.code,
    if (invoiceNo != null && invoiceNo.isNotEmpty) 'invoice_no': invoiceNo,
  };

  static Map<String, dynamic> patchBody(EduPayment payment) {
    final body = <String, dynamic>{'status': statusToApi(payment.status)};
    if (payment.invoiceNo != null && payment.invoiceNo!.isNotEmpty) {
      body['invoice_no'] = payment.invoiceNo;
    }
    return body;
  }

  static String statusToApi(EduPaymentStatus status) => switch (status) {
    EduPaymentStatus.drafting || EduPaymentStatus.invoiced => 'invoiced',
    EduPaymentStatus.paid => 'paid',
    EduPaymentStatus.cancelled => 'cancelled',
  };

  static EduPaymentStatus statusFromApi(String raw) => switch (raw) {
    'paid' => EduPaymentStatus.paid,
    'cancelled' => EduPaymentStatus.cancelled,
    _ => EduPaymentStatus.invoiced,
  };

  static School _resolveSchool(
    String id,
    String name,
    String level,
    String area,
    Money fee,
  ) {
    try {
      return EducationCatalog.all().firstWhere((s) => s.id == id);
    } catch (_) {
      return School(
        id: id.isEmpty ? 'edu-unknown' : id,
        name: name,
        level: level,
        area: area,
        termFee: fee,
      );
    }
  }
}

import '../../features/gov/data/gov_catalog.dart';
import '../../features/gov/domain/gov_models.dart';
import '../../features/wallet/domain/currency.dart';
import '../../features/wallet/domain/money.dart';

/// Maps `/api/v1/commerce/gov-requests` JSON ↔ domain [GovRequest].
class GovRequestDto {
  const GovRequestDto._();

  static GovRequest toDomain(Map<String, dynamic> json, {GovService? service}) {
    final currency = Currency.fromCode(json['currency'] as String? ?? 'TZS');
    final serviceId = json['service_id'] as String? ?? '';
    final fee = Money((json['fee_minor'] as num?)?.toInt() ?? 0, currency);
    final ref = (json['reference'] as String?)?.trim();
    final pay = (json['payment_ref'] as String?)?.trim();

    return GovRequest(
      id: json['id'].toString(),
      service:
          service ??
          _resolveService(
            serviceId,
            json['service_title'] as String? ?? 'Service',
            json['agency'] as String? ?? '',
            json['category'] as String? ?? '',
            fee,
            (json['eta_days'] as num?)?.toInt() ?? 7,
          ),
      status: statusFromApi(json['status'] as String? ?? 'in_review'),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      applicantName: json['applicant_name'] as String? ?? '',
      reference: (ref == null || ref.isEmpty) ? null : ref,
      paymentRef: (pay == null || pay.isEmpty) ? null : pay,
    );
  }

  static Map<String, dynamic> createBody(
    GovRequest draft, {
    String? reference,
  }) => {
    'service_id': draft.service.id,
    'service_title': draft.service.title,
    'agency': draft.service.agency,
    'category': draft.service.category,
    'applicant_name': draft.applicantName,
    'fee_minor': draft.service.fee.minorUnits,
    'currency': draft.service.fee.currency.code,
    'eta_days': draft.service.etaDays,
    if (reference != null && reference.isNotEmpty) 'reference': reference,
  };

  static Map<String, dynamic> patchBody(GovRequest request) {
    final body = <String, dynamic>{'status': statusToApi(request.status)};
    if (request.reference != null && request.reference!.isNotEmpty) {
      body['reference'] = request.reference;
    }
    return body;
  }

  static String statusToApi(GovRequestStatus status) => switch (status) {
    GovRequestStatus.drafting || GovRequestStatus.submitted => 'submitted',
    GovRequestStatus.inReview => 'in_review',
    GovRequestStatus.approved => 'approved',
    GovRequestStatus.paid => 'paid',
    GovRequestStatus.rejected => 'rejected',
  };

  static GovRequestStatus statusFromApi(String raw) => switch (raw) {
    'submitted' => GovRequestStatus.submitted,
    'approved' => GovRequestStatus.approved,
    'paid' => GovRequestStatus.paid,
    'rejected' => GovRequestStatus.rejected,
    _ => GovRequestStatus.inReview,
  };

  static GovService _resolveService(
    String id,
    String title,
    String agency,
    String category,
    Money fee,
    int etaDays,
  ) {
    try {
      return GovCatalog.all().firstWhere((s) => s.id == id);
    } catch (_) {
      return GovService(
        id: id.isEmpty ? 'gov-unknown' : id,
        title: title,
        agency: agency,
        description: '',
        fee: fee,
        etaDays: etaDays,
        category: category,
      );
    }
  }
}

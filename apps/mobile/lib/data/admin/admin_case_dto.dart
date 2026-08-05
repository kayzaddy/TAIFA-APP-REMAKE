import '../../features/admin/domain/admin_models.dart';

/// Maps `/api/v1/commerce/admin-cases` JSON ↔ domain [AdminCase].
class AdminCaseDto {
  const AdminCaseDto._();

  static AdminCase toDomain(Map<String, dynamic> json) {
    return AdminCase(
      id: json['id'].toString(),
      kind: kindFromApi(json['kind'] as String? ?? 'kyc'),
      title: json['title'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      detail: json['detail'] as String? ?? '',
      status: statusFromApi(json['status'] as String? ?? 'open'),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  static Map<String, dynamic> createBody(AdminCase c) => {
    'kind': kindToApi(c.kind),
    'status': statusToApi(c.status),
    'title': c.title,
    'subject': c.subject,
    'detail': c.detail,
  };

  static Map<String, dynamic> patchBody(AdminCase c) => {
    'status': statusToApi(c.status),
  };

  static String kindToApi(AdminCaseKind kind) => switch (kind) {
    AdminCaseKind.kyc => 'kyc',
    AdminCaseKind.dispute => 'dispute',
    AdminCaseKind.freeze => 'freeze',
  };

  static AdminCaseKind kindFromApi(String raw) => switch (raw) {
    'dispute' => AdminCaseKind.dispute,
    'freeze' => AdminCaseKind.freeze,
    _ => AdminCaseKind.kyc,
  };

  static String statusToApi(AdminCaseStatus status) => switch (status) {
    AdminCaseStatus.open => 'open',
    AdminCaseStatus.reviewing => 'reviewing',
    AdminCaseStatus.resolved => 'resolved',
  };

  static AdminCaseStatus statusFromApi(String raw) => switch (raw) {
    'reviewing' => AdminCaseStatus.reviewing,
    'resolved' => AdminCaseStatus.resolved,
    _ => AdminCaseStatus.open,
  };
}

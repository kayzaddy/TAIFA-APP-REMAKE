enum AdminCaseKind { kyc, dispute, freeze }

enum AdminCaseStatus { open, reviewing, resolved }

extension AdminCaseStatusX on AdminCaseStatus {
  String get label => switch (this) {
    AdminCaseStatus.open => 'Open',
    AdminCaseStatus.reviewing => 'Reviewing',
    AdminCaseStatus.resolved => 'Resolved',
  };
}

class AdminCase {
  const AdminCase({
    required this.id,
    required this.kind,
    required this.title,
    required this.subject,
    required this.detail,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final AdminCaseKind kind;
  final String title;
  final String subject;
  final String detail;
  final AdminCaseStatus status;
  final DateTime createdAt;

  AdminCase copyWith({AdminCaseStatus? status}) {
    return AdminCase(
      id: id,
      kind: kind,
      title: title,
      subject: subject,
      detail: detail,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}

class AdminStats {
  const AdminStats({
    required this.activeUsers,
    required this.openCases,
    required this.merchants,
    required this.flaggedWallets,
  });

  final int activeUsers;
  final int openCases;
  final int merchants;
  final int flaggedWallets;
}

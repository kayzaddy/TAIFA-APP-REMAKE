enum RegistryApplicationType {
  driver,
  vehicle,
  station,
  fleet,
  transportCompany,
}

enum RegistryApplicationStatus {
  draft,
  submitted,
  pendingReview,
  documentsMissing,
  rejected,
  suspended,
  approved,
  blocked,
}

class RegistryApplication {
  const RegistryApplication({
    required this.id,
    required this.number,
    required this.type,
    required this.status,
    required this.stage,
    required this.region,
    required this.district,
    required this.updatedAt,
  });

  final String id;
  final String number;
  final RegistryApplicationType type;
  final RegistryApplicationStatus status;
  final String stage;
  final String region;
  final String district;
  final DateTime updatedAt;

  bool get mayOperate => status == RegistryApplicationStatus.approved;
}

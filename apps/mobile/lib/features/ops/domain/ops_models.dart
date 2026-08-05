enum OpsIncidentKind { ride, food, payment, system }

enum OpsIncidentStatus { open, acknowledged, resolved }

extension OpsIncidentStatusX on OpsIncidentStatus {
  String get label => switch (this) {
    OpsIncidentStatus.open => 'Open',
    OpsIncidentStatus.acknowledged => 'Ack',
    OpsIncidentStatus.resolved => 'Resolved',
  };
}

class OpsIncident {
  const OpsIncident({
    required this.id,
    required this.kind,
    required this.title,
    required this.region,
    required this.detail,
    required this.severity,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final OpsIncidentKind kind;
  final String title;
  final String region;
  final String detail;
  final String severity;
  final OpsIncidentStatus status;
  final DateTime createdAt;

  OpsIncident copyWith({OpsIncidentStatus? status}) {
    return OpsIncident(
      id: id,
      kind: kind,
      title: title,
      region: region,
      detail: detail,
      severity: severity,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}

class OpsStats {
  const OpsStats({
    required this.activeRides,
    required this.openFoodOrders,
    required this.paymentQueue,
    required this.openIncidents,
  });

  final int activeRides;
  final int openFoodOrders;
  final int paymentQueue;
  final int openIncidents;
}

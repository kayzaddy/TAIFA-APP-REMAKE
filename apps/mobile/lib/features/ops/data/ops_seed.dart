import '../domain/ops_models.dart';

class OpsSeed {
  const OpsSeed._();

  static List<OpsIncident> incidents() {
    final now = DateTime.now();
    return [
      OpsIncident(
        id: 'ops-ride-1',
        kind: OpsIncidentKind.ride,
        title: 'Matching backlog · Kinondoni',
        region: 'Dar es Salaam',
        detail: 'ETA spikes > 12 min. Surge recommend +15%.',
        severity: 'High',
        status: OpsIncidentStatus.open,
        createdAt: now.subtract(const Duration(minutes: 6)),
      ),
      OpsIncident(
        id: 'ops-pay-1',
        kind: OpsIncidentKind.payment,
        title: 'M-Pesa webhook lag',
        region: 'National',
        detail: 'Settlement worker lag 94s. 41 txns pending reconcile.',
        severity: 'Critical',
        status: OpsIncidentStatus.open,
        createdAt: now.subtract(const Duration(minutes: 14)),
      ),
      OpsIncident(
        id: 'ops-food-1',
        kind: OpsIncidentKind.food,
        title: 'Courier shortage · Masaki',
        region: 'Dar es Salaam',
        detail: '18 food orders waiting > 25 min for courier assign.',
        severity: 'Medium',
        status: OpsIncidentStatus.acknowledged,
        createdAt: now.subtract(const Duration(minutes: 32)),
      ),
      OpsIncident(
        id: 'ops-sys-1',
        kind: OpsIncidentKind.system,
        title: 'Maps tile cache miss',
        region: 'Zanzibar',
        detail: 'Mock map fallback engaged. No user-facing hard fail.',
        severity: 'Low',
        status: OpsIncidentStatus.open,
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
    ];
  }
}

import '../data/ops_seed.dart';
import '../domain/ops_models.dart';

abstract interface class OpsRepository {
  Future<List<OpsIncident>> listIncidents();
  Future<OpsStats> stats();
  Future<OpsIncident> advance(String id);
}

class SeedOpsRepository implements OpsRepository {
  final Map<String, OpsIncident> _byId = {
    for (final i in OpsSeed.incidents()) i.id: i,
  };

  @override
  Future<List<OpsIncident>> listIncidents() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final list = _byId.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<OpsStats> stats() async {
    final incidents = await listIncidents();
    final open = incidents
        .where((i) => i.status != OpsIncidentStatus.resolved)
        .length;
    return OpsStats(
      activeRides: 186,
      openFoodOrders: 94,
      paymentQueue: 41,
      openIncidents: open,
    );
  }

  @override
  Future<OpsIncident> advance(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 280));
    final cur = _byId[id]!;
    final next = switch (cur.status) {
      OpsIncidentStatus.open => OpsIncidentStatus.acknowledged,
      OpsIncidentStatus.acknowledged => OpsIncidentStatus.resolved,
      OpsIncidentStatus.resolved => OpsIncidentStatus.resolved,
    };
    final updated = cur.copyWith(status: next);
    _byId[id] = updated;
    return updated;
  }
}

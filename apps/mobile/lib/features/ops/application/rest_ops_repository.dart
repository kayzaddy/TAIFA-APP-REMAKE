import '../../../data/api/api_client.dart';
import '../../../data/trips/mobility_ops_client.dart';
import '../../../data/trips/trip_api_paths.dart';
import '../domain/ops_models.dart';
import 'ops_repository.dart';

/// Live Mobility Command Center backed by city ops + safety incident APIs.
class RestOpsRepository implements OpsRepository {
  RestOpsRepository(this._client);

  final TaifaApiClient _client;
  late final MobilityOpsClient _ops = MobilityOpsClient(_client);

  @override
  Future<List<OpsIncident>> listIncidents() async {
    final rows = await _ops.listIncidents();
    return rows.map(_toIncident).toList();
  }

  @override
  Future<OpsStats> stats() async {
    final json = await _client.getJson(TripApiPaths.operationsDashboard);
    return OpsStats(
      activeRides: _asInt(json['live_trips']),
      openFoodOrders: _asInt(json['queue_length_total']),
      paymentQueue: _asInt(json['ride_requests_today']),
      openIncidents: _asInt(json['open_sos']),
    );
  }

  @override
  Future<OpsIncident> advance(String id) async {
    final current = await _client.getJson(TripApiPaths.safetyIncident(id));
    final status = current['status']?.toString() ?? 'open';
    final next = switch (status) {
      'open' => 'acknowledged',
      'acknowledged' => 'resolved',
      'responding' => 'resolved',
      _ => status,
    };
    final updated = await _ops.advanceIncident(incidentId: id, status: next);
    return _toIncident(updated);
  }

  OpsIncident _toIncident(Map<String, dynamic> row) {
    final status = switch (row['status']?.toString()) {
      'acknowledged' || 'responding' => OpsIncidentStatus.acknowledged,
      'resolved' || 'false_alarm' => OpsIncidentStatus.resolved,
      _ => OpsIncidentStatus.open,
    };
    return OpsIncident(
      id: row['id'].toString(),
      kind: OpsIncidentKind.ride,
      title: '${row['kind'] ?? 'incident'}'.toUpperCase(),
      region: 'mobility',
      detail: row['severity']?.toString() ?? '',
      severity: row['severity']?.toString() ?? 'critical',
      status: status,
      createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}

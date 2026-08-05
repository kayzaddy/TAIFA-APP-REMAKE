import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../station_ops/application/station_ops_providers.dart';

class CityOpsScreen extends ConsumerStatefulWidget {
  const CityOpsScreen({super.key});

  @override
  ConsumerState<CityOpsScreen> createState() => _CityOpsScreenState();
}

class _CityOpsScreenState extends ConsumerState<CityOpsScreen> {
  final _region = TextEditingController(text: 'Dar es Salaam');
  final _district = TextEditingController(text: 'Ilala');
  Map<String, dynamic> _ops = const {};
  Map<String, dynamic> _map = const {};
  List<Map<String, dynamic>> _incidents = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _region.dispose();
    _district.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = ref.read(mobilityOpsClientProvider);
      final region = _region.text.trim();
      final district = _district.text.trim();
      final ops = await client.cityOperations(
        region: region,
        district: district,
      );
      final map = await client.cityMap(region: region, district: district);
      final incidents = await client.listIncidents(region: region);
      setState(() {
        _ops = ops;
        _map = map;
        _incidents = incidents;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _advance(String id, String status) async {
    try {
      await ref.read(mobilityOpsClientProvider).advanceIncident(
            incidentId: id,
            status: status,
          );
      await _load();
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final kpis = (_ops['kpis'] as Map?)?.cast<String, dynamic>() ?? const {};
    final transit = (kpis['transit'] as Map?)?.cast<String, dynamic>() ?? const {};
    final rankings =
        ((_ops['station_rankings'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
    final summary =
        (_map['summary'] as Map?)?.cast<String, dynamic>() ?? const {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('City Operations'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_loading) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _region,
                    decoration: const InputDecoration(labelText: 'Region'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _district,
                    decoration: const InputDecoration(labelText: 'District'),
                  ),
                ),
                IconButton(
                  onPressed: _load,
                  icon: const Icon(Icons.search_rounded),
                ),
              ],
            ),
          ),
          if (_error != null)
            MaterialBanner(
              content: Text(_error!),
              actions: [
                TextButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Chip('Live trips', '${kpis['live_trips'] ?? summary['live_trips'] ?? 0}'),
                    _Chip('Drivers', '${kpis['available_drivers'] ?? 0}'),
                    _Chip('Stations', '${kpis['stations'] ?? summary['stations'] ?? 0}'),
                    _Chip('SOS', '${kpis['open_sos'] ?? summary['open_sos'] ?? 0}'),
                    _Chip('Completed', '${kpis['completed_today'] ?? 0}'),
                    _Chip('Health', '${kpis['system_health'] ?? '-'}'),
                    _Chip('BRT tickets', '${transit['tickets_issued_today'] ?? 0}'),
                    _Chip('BRT scans', '${transit['validations_today'] ?? 0}'),
                    _Chip('BRT buses', '${transit['avl_vehicles_in_service'] ?? 0}'),
                    _Chip('L&F open', '${transit['lost_found_open'] ?? 0}'),
                    _Chip('L&F claimed', '${transit['lost_found_claimed'] ?? 0}'),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Station rankings',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                ...rankings.take(8).map(
                      (row) => ListTile(
                        leading: CircleAvatar(child: Text('${row['rank'] ?? '-'}')),
                        title: Text(row['name']?.toString() ?? 'Station'),
                        subtitle: Text(
                          'Demand ${row['demand_score_e4'] ?? 0} · '
                          'Gap ${row['supply_gap'] ?? 0} · '
                          '${row['station_health'] ?? '-'}',
                        ),
                      ),
                    ),
                const SizedBox(height: 16),
                Text(
                  'Incidents',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (_incidents.isEmpty)
                  const Text('No open incidents in region')
                else
                  ..._incidents.map(
                    (incident) => Card(
                      child: ListTile(
                        title: Text(
                          '${incident['kind']} · ${incident['status']}',
                        ),
                        subtitle: Text(incident['severity']?.toString() ?? ''),
                        trailing: Wrap(
                          children: [
                            if (incident['status'] == 'open')
                              TextButton(
                                onPressed: () => _advance(
                                  incident['id'].toString(),
                                  'acknowledged',
                                ),
                                child: const Text('Ack'),
                              ),
                            if (incident['status'] == 'acknowledged')
                              TextButton(
                                onPressed: () => _advance(
                                  incident['id'].toString(),
                                  'resolved',
                                ),
                                child: const Text('Resolve'),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text('$label: $value'));
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../station_ops/application/station_ops_providers.dart';

class NationalOpsScreen extends ConsumerStatefulWidget {
  const NationalOpsScreen({super.key});

  @override
  ConsumerState<NationalOpsScreen> createState() => _NationalOpsScreenState();
}

class _NationalOpsScreenState extends ConsumerState<NationalOpsScreen> {
  Map<String, dynamic> _command = const {};
  Map<String, dynamic> _analytics = const {};
  Map<String, dynamic> _optimization = const {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = ref.read(mobilityOpsClientProvider);
      final command = await client.nationalCommandCenter();
      final analytics = await client.nationalAnalytics(days: 30);
      final optimization = await client.nationalOptimization();
      setState(() {
        _command = command;
        _analytics = analytics;
        _optimization = optimization;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final national =
        (_command['national'] as Map?)?.cast<String, dynamic>() ?? const {};
    final transit = (national['transit'] as Map?)?.cast<String, dynamic>() ?? const {};
    final regions =
        ((_command['regions'] as List?) ?? const []).map((e) => '$e').toList();
    final regional =
        ((_command['regional_kpis'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
    final byRegion =
        ((_analytics['by_region'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
    final expansion =
        ((_optimization['station_expansion'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('National Operations'),
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
                Text(
                  'United Republic of Tanzania',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'National Mobility Command Center',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Chip('Regions', '${national['regions'] ?? regions.length}'),
                    _Chip('Stations', '${national['stations'] ?? 0}'),
                    _Chip('Drivers', '${national['available_drivers'] ?? 0}'),
                    _Chip('Live trips', '${national['live_trips'] ?? 0}'),
                    _Chip('SOS', '${national['open_sos'] ?? 0}'),
                    _Chip('Emergency', '${national['emergency_open'] ?? 0}'),
                    _Chip('Intercity', '${national['intercity_departures_today'] ?? 0}'),
                    _Chip('Logistics', '${national['logistics_open'] ?? 0}'),
                    _Chip('PT routes', '${national['public_transit_routes'] ?? 0}'),
                    _Chip('BRT tickets', '${transit['tickets_issued_today'] ?? 0}'),
                    _Chip('BRT scans', '${transit['validations_today'] ?? 0}'),
                    _Chip('BRT AVL', '${transit['avl_vehicles_in_service'] ?? 0}'),
                    _Chip('Health', '${national['system_health'] ?? '-'}'),
                    _Chip(
                      'Fare today',
                      '${national['fare_today_minor'] ?? 0}',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Regions online',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final region in regions) Chip(label: Text(region)),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Regional KPIs',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (final row in regional.take(20))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${row['region'] ?? '-'}'),
                    subtitle: Text(
                      'Live ${row['live_trips'] ?? 0} · Drivers ${row['available_drivers'] ?? 0} · '
                      'SOS ${row['open_sos'] ?? 0} · ${row['system_health'] ?? '-'}',
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  'Demand by region (30d)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (final row in byRegion.take(15))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${row['region'] ?? '-'}'),
                    subtitle: Text(
                      'Requested ${row['requested'] ?? 0} · Completed ${row['completed'] ?? 0} · '
                      'Fare ${row['fare'] ?? 0}',
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  'Station expansion signals',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (expansion.isEmpty)
                  const Text('No high-demand expansion signals right now.')
                else
                  for (final row in expansion.take(10))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('${row['station'] ?? row['station_id'] ?? '-'}'),
                      subtitle: Text(
                        '${row['region'] ?? '-'} · predicted ${row['predicted_requests'] ?? 0}',
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
    return Chip(
      label: Text('$label: $value'),
    );
  }
}

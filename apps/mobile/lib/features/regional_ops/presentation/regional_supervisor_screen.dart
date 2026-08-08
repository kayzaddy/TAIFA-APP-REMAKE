import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../wallet/application/wallet_providers.dart' show apiClientProvider;
import 'package:lucide_icons_flutter/lucide_icons.dart';

class RegionalSupervisorScreen extends ConsumerStatefulWidget {
  const RegionalSupervisorScreen({super.key});

  @override
  ConsumerState<RegionalSupervisorScreen> createState() =>
      _RegionalSupervisorScreenState();
}

class _RegionalSupervisorScreenState
    extends ConsumerState<RegionalSupervisorScreen> {
  Map<String, dynamic> _payload = const {};
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
      final json = await ref
          .read(apiClientProvider)
          .getJson('trips/regional/supervisor');
      setState(() {
        _payload = json;
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
    final kpis =
        (_payload['kpis'] as Map?)?.cast<String, dynamic>() ?? const {};
    final stations =
        ((_payload['stations'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
    final assignments =
        ((_payload['assignments'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Regional Supervisor'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(LucideIcons.refreshCw),
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
                if (assignments.isNotEmpty) ...[
                  Text(
                    'Assignments',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  ...assignments.map(
                    (row) => ListTile(
                      title: Text(
                        '${row['role_title']} · ${row['region']}',
                      ),
                      subtitle: Text(
                        '${row['scope']} ${row['district'] ?? ''} '
                        '${row['zone'] ?? ''}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(label: Text('Live ${kpis['live_trips'] ?? 0}')),
                    Chip(
                      label: Text('Drivers ${kpis['available_drivers'] ?? 0}'),
                    ),
                    Chip(label: Text('SOS ${kpis['open_sos'] ?? 0}')),
                    Chip(
                      label: Text('Health ${kpis['system_health'] ?? '-'}'),
                    ),
                    Chip(
                      label: Text(
                        'Fare ${kpis['fare_today_minor'] ?? 0}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Station rankings',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                ...stations.take(12).map(
                      (row) => ListTile(
                        leading: CircleAvatar(
                          child: Text('${row['rank'] ?? '-'}'),
                        ),
                        title: Text(row['name']?.toString() ?? 'Station'),
                        subtitle: Text(
                          '${row['station_health']} · gap ${row['supply_gap']}',
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

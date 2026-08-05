import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../station_ops/application/station_ops_providers.dart';

class FleetOpsScreen extends ConsumerStatefulWidget {
  const FleetOpsScreen({super.key});

  @override
  ConsumerState<FleetOpsScreen> createState() => _FleetOpsScreenState();
}

class _FleetOpsScreenState extends ConsumerState<FleetOpsScreen> {
  List<Map<String, dynamic>> _fleets = const [];
  Map<String, dynamic> _intel = const {};
  String? _selectedFleetId;
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
      final fleets = await client.listFleets();
      Map<String, dynamic> intel = const {};
      String? selected = _selectedFleetId;
      if (fleets.isNotEmpty) {
        selected ??= fleets.first['id']?.toString();
        if (selected != null) {
          intel = await client.fleetIntelligence(selected);
        }
      }
      setState(() {
        _fleets = fleets;
        _selectedFleetId = selected;
        _intel = intel;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _select(String fleetId) async {
    setState(() {
      _selectedFleetId = fleetId;
      _loading = true;
    });
    try {
      final intel = await ref
          .read(mobilityOpsClientProvider)
          .fleetIntelligence(fleetId);
      setState(() {
        _intel = intel;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fleet Intelligence'),
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
          if (_fleets.isNotEmpty)
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: _fleets
                    .map(
                      (fleet) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(fleet['name']?.toString() ?? 'Fleet'),
                          selected: fleet['id']?.toString() == _selectedFleetId,
                          onSelected: (_) =>
                              _select(fleet['id'].toString()),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          Expanded(
            child: _fleets.isEmpty
                ? const Center(child: Text('No fleets for this principal'))
                : ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      Text(
                        _intel['name']?.toString() ?? 'Fleet',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text('Type: ${_intel['fleet_type'] ?? '-'}'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _Metric('Drivers', '${_intel['drivers'] ?? 0}'),
                          _Metric('Online', '${_intel['online_drivers'] ?? 0}'),
                          _Metric('Vehicles', '${_intel['vehicles'] ?? 0}'),
                          _Metric(
                            'Compliant',
                            '${_intel['compliant_vehicles'] ?? 0}',
                          ),
                          _Metric(
                            'Active trips',
                            '${_intel['active_trips'] ?? 0}',
                          ),
                          _Metric(
                            'Completed today',
                            '${_intel['completed_today'] ?? 0}',
                          ),
                          _Metric(
                            'Gross fare',
                            '${_intel['gross_fare_minor'] ?? 0}',
                          ),
                          _Metric(
                            'Maintenance due',
                            '${_intel['maintenance_due'] ?? 0}',
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label),
              const SizedBox(height: 6),
              Text(value, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}

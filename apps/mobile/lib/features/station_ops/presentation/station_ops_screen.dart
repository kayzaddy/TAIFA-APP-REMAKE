import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/station_ops_providers.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class StationOpsScreen extends ConsumerStatefulWidget {
  const StationOpsScreen({super.key});

  @override
  ConsumerState<StationOpsScreen> createState() => _StationOpsScreenState();
}

class _StationOpsScreenState extends ConsumerState<StationOpsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(stationOpsControllerProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(stationOpsControllerProvider);
    final controller = ref.read(stationOpsControllerProvider.notifier);
    final dashboard = state.dashboard;
    final performance =
        (dashboard['performance'] as Map?)?.cast<String, dynamic>() ?? const {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Station Operations'),
        actions: [
          IconButton(
            onPressed: state.loading ? null : controller.load,
            icon: const Icon(LucideIcons.refreshCw),
          ),
        ],
      ),
      body: Column(
        children: [
          if (state.loading) const LinearProgressIndicator(),
          if (state.error != null)
            MaterialBanner(
              content: Text(state.error!),
              actions: [
                TextButton(onPressed: controller.load, child: const Text('Retry')),
              ],
            ),
          if (state.stations.isNotEmpty)
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: state.stations
                    .map(
                      (station) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(station['name']?.toString() ?? 'Station'),
                          selected:
                              station['id']?.toString() ==
                              state.selectedStationId,
                          onSelected: (_) => controller.selectStation(
                            station['id'].toString(),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          Expanded(
            child: state.stations.isEmpty
                ? const Center(
                    child: Text(
                      'No managed stations for this device principal.',
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _Metric(
                            label: 'Queue',
                            value: '${dashboard['queue_length'] ?? 0}',
                          ),
                          _Metric(
                            label: 'Online',
                            value: '${dashboard['online_drivers'] ?? 0}',
                          ),
                          _Metric(
                            label: 'On trip',
                            value: '${dashboard['drivers_on_trip'] ?? 0}',
                          ),
                          _Metric(
                            label: 'Completed',
                            value: '${dashboard['completed_today'] ?? 0}',
                          ),
                          _Metric(
                            label: 'Cancelled',
                            value: '${dashboard['cancelled_today'] ?? 0}',
                          ),
                          _Metric(
                            label: 'Wait (s)',
                            value:
                                '${dashboard['average_waiting_seconds'] ?? 0}',
                          ),
                          _Metric(
                            label: 'Revenue',
                            value:
                                '${dashboard['gross_fare_today_minor'] ?? 0}',
                          ),
                          _Metric(
                            label: 'Health',
                            value: '${dashboard['station_health'] ?? '-'}',
                          ),
                          _Metric(
                            label: 'Completion',
                            value: '${performance['completion_rate_e4'] ?? 0}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Driver queue',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (state.queue.isEmpty)
                        const Text('Queue is empty')
                      else
                        ...state.queue.map(
                          (entry) => Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text('${entry['position'] ?? '-'}'),
                              ),
                              title: Text(
                                entry['driver_name']?.toString() ??
                                    entry['driver']?.toString() ??
                                    'Driver',
                              ),
                              subtitle: Text(
                                'Priority ${entry['priority'] ?? 0}',
                              ),
                              trailing: IconButton(
                                tooltip: 'Move up',
                                onPressed: () => controller.moveDriverUp(
                                  entry['driver'].toString(),
                                ),
                                icon: const Icon(LucideIcons.arrowUp),
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

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 6),
              Text(value, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../mobility_transit/application/transit_providers.dart';
import '../../station_ops/application/station_ops_providers.dart';

class MobilityDriverScreen extends ConsumerStatefulWidget {
  const MobilityDriverScreen({super.key});

  @override
  ConsumerState<MobilityDriverScreen> createState() =>
      _MobilityDriverScreenState();
}

class _MobilityDriverScreenState extends ConsumerState<MobilityDriverScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mobilityDriverControllerProvider.notifier).load();
      ref.read(transitDriverControllerProvider.notifier).loadRuns();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mobilityDriverControllerProvider);
    final controller = ref.read(mobilityDriverControllerProvider.notifier);
    final brtState = ref.watch(transitDriverControllerProvider);
    final brtCtrl = ref.read(transitDriverControllerProvider.notifier);
    final profile = state.profile;
    final daily =
        (state.earnings['daily'] as Map?)?.cast<String, dynamic>() ?? const {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mobility Driver'),
        actions: [
          IconButton(
            onPressed: state.loading ? null : controller.load,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Emergency SOS',
            onPressed: controller.sos,
            icon: const Icon(Icons.sos_rounded),
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
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Text(
                  profile['full_name']?.toString() ?? 'Driver',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Status: ${profile['availability'] ?? '-'} · '
                  'Trips: ${profile['completed_trips'] ?? 0}',
                ),
                const SizedBox(height: 12),
                Text(
                  'Today: ${daily['gross_fare_minor'] ?? 0} '
                  '${daily['currency'] ?? 'TZS'} · '
                  '${daily['trips'] ?? 0} trips',
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    FilledButton(
                      onPressed: () => controller.setAvailability('available'),
                      child: const Text('Go online'),
                    ),
                    OutlinedButton(
                      onPressed: () => controller.setAvailability('break'),
                      child: const Text('Break'),
                    ),
                    OutlinedButton(
                      onPressed: () => controller.setAvailability('busy'),
                      child: const Text('Busy'),
                    ),
                    OutlinedButton(
                      onPressed: () => controller.setAvailability('offline'),
                      child: const Text('Go offline'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'BRT scheduled runs',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (brtState.error != null)
                  Text(brtState.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                if (brtState.runs.isEmpty)
                  const Text('No upcoming Mwendokasi shifts (requires transit-driver role)')
                else
                  ...brtState.runs.map((run) {
                    final next = switch (run.status) {
                      'scheduled' => 'boarding',
                      'boarding' => 'departed',
                      'departed' => 'completed',
                      _ => '',
                    };
                    return Card(
                      child: ListTile(
                        title: Text(run.routeName),
                        subtitle: Text(
                          '${run.vehicleLabel} · ${run.originStop} → ${run.destinationStop} · ${run.status}',
                        ),
                        trailing: next.isEmpty
                            ? null
                            : FilledButton(
                                onPressed: brtState.isBusy
                                    ? null
                                    : () => brtCtrl.advanceRun(run.id, next),
                                child: Text(next),
                              ),
                      ),
                    );
                  }),
                const SizedBox(height: 24),
                Text(
                  'Ride offers',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (state.offers.isEmpty)
                  const Text('No pending offers')
                else
                  ...state.offers.map((offer) {
                    return Card(
                      child: ListTile(
                        title: Text(
                          offer['pickup_name']?.toString() ??
                              'Offer ${offer['id']}',
                        ),
                        subtitle: Text(
                          '${offer['dropoff_name'] ?? ''} · '
                          'ETA ${offer['eta_seconds'] ?? '-'}s · '
                          'score ${offer['score_e4'] ?? '-'}',
                        ),
                        trailing: Wrap(
                          spacing: 4,
                          children: [
                            TextButton(
                              onPressed: () => controller.acceptOffer(
                                offer['id'].toString(),
                              ),
                              child: const Text('Accept'),
                            ),
                            TextButton(
                              onPressed: () => controller.rejectOffer(
                                offer['id'].toString(),
                              ),
                              child: const Text('Reject'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

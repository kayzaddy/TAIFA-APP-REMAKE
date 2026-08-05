import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../../../app/theme/taifa_theme.dart';
import '../application/transit_providers.dart';
import '../domain/transit_models.dart';
import 'transit_map_view.dart';

class TransitLiveMapScreen extends ConsumerStatefulWidget {
  const TransitLiveMapScreen({super.key});

  @override
  ConsumerState<TransitLiveMapScreen> createState() => _TransitLiveMapScreenState();
}

class _TransitLiveMapScreenState extends ConsumerState<TransitLiveMapScreen> {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transitLiveMapControllerProvider.notifier).load();
      _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        ref.read(transitLiveMapControllerProvider.notifier).load(silent: true);
      });
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transitLiveMapControllerProvider);
    final palette = context.taifa;
    final map = state.liveMap;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: const Text('Live BRT map'),
        actions: [
          IconButton(
            onPressed: () => ref.read(transitLiveMapControllerProvider.notifier).load(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          if (state.isBusy && map == null)
            const LinearProgressIndicator(color: TaifaColors.gold400),
          Expanded(
            child: map == null
                ? Center(child: Text(state.error ?? 'Loading map…', style: TextStyle(color: palette.textMuted)))
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      TransitMapView(liveMap: map),
                      Positioned(
                        left: TaifaSpacing.screenH,
                        right: TaifaSpacing.screenH,
                        bottom: 16,
                        child: _VehicleList(vehicles: map.vehicles),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _VehicleList extends StatelessWidget {
  const _VehicleList({required this.vehicles});
  final List<TransitMapVehicle> vehicles;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    if (vehicles.isEmpty) {
      return Material(
        borderRadius: BorderRadius.circular(14),
        color: palette.surface.withValues(alpha: 0.92),
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Text('No buses in service on this corridor'),
        ),
      );
    }
    return Material(
      borderRadius: BorderRadius.circular(14),
      color: palette.surface.withValues(alpha: 0.92),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Live buses (${vehicles.length})',
              style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            ...vehicles.take(4).map(
                  (v) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.directions_bus_filled, color: TaifaColors.emerald500, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${v.vehicleLabel} → ${v.nextStopCode}',
                            style: TextStyle(color: palette.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          '${v.speedKmh} km/h · ${(v.etaNextStopSeconds / 60).ceil()}m',
                          style: TextStyle(color: palette.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

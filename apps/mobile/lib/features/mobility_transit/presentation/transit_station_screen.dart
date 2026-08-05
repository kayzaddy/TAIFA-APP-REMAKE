import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../../../app/theme/taifa_theme.dart';
import '../application/transit_providers.dart';

class TransitStationScreen extends ConsumerStatefulWidget {
  const TransitStationScreen({super.key, required this.stopCode});

  final String stopCode;

  @override
  ConsumerState<TransitStationScreen> createState() => _TransitStationScreenState();
}

class _TransitStationScreenState extends ConsumerState<TransitStationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transitControllerProvider.notifier).loadStation(widget.stopCode);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transitControllerProvider);
    final detail = state.stationDetail;
    final palette = context.taifa;

    return Scaffold(
      appBar: AppBar(
        title: Text(detail?.name ?? 'Station'),
      ),
      body: state.isBusy && detail == null
          ? const Center(child: CircularProgressIndicator(color: TaifaColors.gold400))
          : detail == null
              ? Center(child: Text(state.error ?? 'Station not found', style: TextStyle(color: palette.textMuted)))
              : ListView(
                  padding: const EdgeInsets.all(TaifaSpacing.screenH),
                  children: [
                    if (detail.imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(detail.imageUrl, height: 160, fit: BoxFit.cover),
                      ),
                    const SizedBox(height: 12),
                    Text(detail.name, style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w800, fontSize: 22)),
                    Text('${detail.platform} · ${detail.region}', style: TextStyle(color: palette.textMuted)),
                    const SizedBox(height: 16),
                    Text('Facilities', style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: detail.facilities
                          .map((f) => Chip(label: Text(f.replaceAll('_', ' '))))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    Text('Upcoming departures', style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    ...detail.upcoming.map((u) {
                      final time = '${u['departure_time'] ?? ''}';
                      final label = time.length >= 5 ? time.substring(0, 5) : time;
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.directions_bus_filled_rounded, color: TaifaColors.emerald500),
                          title: Text('${u['route_name'] ?? ''}', style: TextStyle(color: palette.textPrimary)),
                          subtitle: Text('${u['route_code'] ?? ''}', style: TextStyle(color: palette.textMuted, fontSize: 12)),
                          trailing: Text(label, style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w700)),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => context.push('/mobility/transit/plan'),
                        child: const Text('Plan journey from here'),
                      ),
                    ),
                  ],
                ),
    );
  }
}

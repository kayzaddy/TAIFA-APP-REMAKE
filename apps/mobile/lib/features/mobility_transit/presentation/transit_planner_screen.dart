import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../../../app/theme/taifa_theme.dart';
import '../application/transit_providers.dart';
import '../domain/transit_models.dart';

class TransitPlannerScreen extends ConsumerStatefulWidget {
  const TransitPlannerScreen({super.key});

  @override
  ConsumerState<TransitPlannerScreen> createState() => _TransitPlannerScreenState();
}

class _TransitPlannerScreenState extends ConsumerState<TransitPlannerScreen> {
  late final TextEditingController _originCtrl;
  late final TextEditingController _destCtrl;

  @override
  void initState() {
    super.initState();
    _originCtrl = TextEditingController(text: 'kimara');
    _destCtrl = TextEditingController(text: 'kivukoni');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transitControllerProvider.notifier)
        ..setPlanStops(origin: 'kimara', destination: 'kivukoni')
        ..runPlanner();
    });
  }

  @override
  void dispose() {
    _originCtrl.dispose();
    _destCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transitControllerProvider);
    final ctrl = ref.read(transitControllerProvider.notifier);
    final palette = context.taifa;

    return Scaffold(
      appBar: AppBar(title: const Text('Plan journey')),
      body: ListView(
        padding: const EdgeInsets.all(TaifaSpacing.screenH),
        children: [
          TextField(
            controller: _originCtrl,
            decoration: const InputDecoration(labelText: 'Origin stop code'),
            onChanged: (v) => ctrl.setPlanStops(origin: v),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _destCtrl,
            decoration: const InputDecoration(labelText: 'Destination stop code'),
            onChanged: (v) => ctrl.setPlanStops(destination: v),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: state.isBusy ? null : ctrl.runPlanner,
            child: state.isBusy
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Find routes'),
          ),
          if (state.error != null) ...[
            const SizedBox(height: 8),
            Text(state.error!, style: TextStyle(color: palette.accent, fontSize: 12)),
          ],
          const SizedBox(height: 20),
          Text('Options', style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 8),
          if (state.planOptions.isEmpty && !state.isBusy)
            Text('No routes found for this pair.', style: TextStyle(color: palette.textMuted))
          else
            ...state.planOptions.map((plan) => _PlanCard(
                  plan: plan,
                  onBuy: () async {
                    await ctrl.openRoute(plan.routeId);
                    if (context.mounted) {
                      final ticket = await ctrl.purchaseTicket(
                        originStop: plan.originStop,
                        destinationStop: plan.destinationStop,
                      );
                      if (ticket != null && context.mounted) {
                        context.push('/mobility/transit/ticket');
                      }
                    }
                  },
                )),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.onBuy});
  final TransitPlanOption plan;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    plan.brand.isNotEmpty ? plan.brand : plan.mode.toUpperCase(),
                    style: TextStyle(
                      color: TaifaColors.emerald500,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (plan.isTransfer)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                    ),
                    child: const Text(
                      'Transfer',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
            Text(plan.routeName, style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w800)),
            Text('${plan.originStop} → ${plan.destinationStop} · ~${plan.durationMinutes} min',
                style: TextStyle(color: palette.textMuted, fontSize: 12)),
            if (plan.isTransfer && plan.transferStop.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Transfer at ${plan.transferStop}',
                style: TextStyle(color: palette.textMuted, fontSize: 11, fontStyle: FontStyle.italic),
              ),
              if (plan.legs.isNotEmpty) ...[
                const SizedBox(height: 6),
                ...plan.legs.map(
                  (leg) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      '• ${leg['route_name']} (${leg['mode']})',
                      style: TextStyle(color: palette.textMuted, fontSize: 11),
                    ),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Text(plan.fare.format(), style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w800)),
                const Spacer(),
                FilledButton(
                  onPressed: onBuy,
                  child: Text(plan.isTransfer ? 'Buy 1st leg' : 'Buy ticket'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

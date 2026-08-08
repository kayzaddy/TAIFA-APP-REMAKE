import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../../../app/theme/taifa_theme.dart';
import '../application/transit_providers.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class TransitAdminScreen extends ConsumerStatefulWidget {
  const TransitAdminScreen({super.key});

  @override
  ConsumerState<TransitAdminScreen> createState() => _TransitAdminScreenState();
}

class _TransitAdminScreenState extends ConsumerState<TransitAdminScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transitAdminControllerProvider.notifier).bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transitAdminControllerProvider);
    final ctrl = ref.read(transitAdminControllerProvider.notifier);
    final palette = context.taifa;
    final ops = state.analytics?.ops ?? const {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('BRT Admin'),
        actions: [
          IconButton(
            onPressed: state.isBusy ? null : ctrl.bootstrap,
            icon: const Icon(LucideIcons.refreshCw),
          ),
        ],
      ),
      body: state.isBusy && state.routes.isEmpty
          ? const Center(child: CircularProgressIndicator(color: TaifaColors.gold400))
          : ListView(
              padding: const EdgeInsets.all(TaifaSpacing.screenH),
              children: [
                if (state.message != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(state.message!, style: TextStyle(color: TaifaColors.emerald500)),
                  ),
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(state.error!, style: TextStyle(color: palette.accent)),
                  ),
                Text(
                  'Corridor analytics',
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _KpiChip('Tickets today', '${ops['tickets_issued_today'] ?? 0}'),
                    _KpiChip('Validations', '${ops['validations_today'] ?? 0}'),
                    _KpiChip('AVL buses', '${ops['avl_vehicles_in_service'] ?? 0}'),
                    _KpiChip('Alerts', '${ops['active_alerts'] ?? 0}'),
                    _KpiChip('L&F open', '${ops['lost_found_open'] ?? 0}'),
                    _KpiChip('L&F claimed', '${ops['lost_found_claimed'] ?? 0}'),
                  ],
                ),
                if (state.lostFoundItems.isNotEmpty) ...[
                  const SizedBox(height: TaifaSpacing.md),
                  Text(
                    'Lost & found queue',
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  ...state.lostFoundItems.map(
                    (item) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.title, style: TextStyle(color: palette.textPrimary)),
                      subtitle: Text(
                        '${item.kind} · ${item.stopCode} · ${item.status}',
                        style: TextStyle(color: palette.textMuted, fontSize: 11),
                      ),
                      trailing: TextButton(
                        onPressed: state.isBusy ? null : () => ctrl.opsCloseLostFound(item.id),
                        child: const Text('Close'),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: TaifaSpacing.md),
                Text(
                  'Routes',
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                ...state.routes.map(
                  (route) => SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(route.name, style: TextStyle(color: palette.textPrimary)),
                    subtitle: Text(route.code, style: TextStyle(color: palette.textMuted, fontSize: 11)),
                    value: true,
                    onChanged: state.isBusy
                        ? null
                        : (v) => ctrl.toggleRouteActive(route, v),
                  ),
                ),
                const SizedBox(height: TaifaSpacing.md),
                Text(
                  'Pass products',
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                ...state.products.map(
                  (product) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(product.name, style: TextStyle(color: palette.textPrimary)),
                    subtitle: Text(
                      '${product.code} · ${product.fare.format()}',
                      style: TextStyle(color: palette.textMuted, fontSize: 11),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: state.isBusy ? null : ctrl.createWeeklyPass,
                  icon: const Icon(LucideIcons.creditCard),
                  label: const Text('Add weekly pass product'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context.push('/city-ops'),
                  icon: const Icon(LucideIcons.layoutGrid),
                  label: const Text('Open city control center'),
                ),
              ],
            ),
    );
  }
}

class _KpiChip extends StatelessWidget {
  const _KpiChip(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w800)),
          Text(label, style: TextStyle(color: palette.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}

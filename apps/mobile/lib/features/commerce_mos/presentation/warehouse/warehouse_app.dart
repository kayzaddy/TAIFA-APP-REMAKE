import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/taifa_dimens.dart';
import '../../application/mos_providers.dart';
import '../widgets/commerce_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Warehouse staff — receive, count, low-stock focus.
class CommerceWarehouseApp extends ConsumerStatefulWidget {
  const CommerceWarehouseApp({super.key});

  @override
  ConsumerState<CommerceWarehouseApp> createState() => _CommerceWarehouseAppState();
}

class _CommerceWarehouseAppState extends ConsumerState<CommerceWarehouseApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mosControllerProvider.notifier).bootstrap();
      ref.read(mosControllerProvider.notifier).runAssist('reorder');
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mosControllerProvider);
    final ctrl = ref.read(mosControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Warehouse'),
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft), onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(TaifaSpacing.screenH),
        children: [
          MosNextAction(
            title: state.lowStockProducts.isEmpty
                ? 'Stock looks healthy'
                : 'Receive low-stock SKUs',
            subtitle: 'Available · reserved · receive · count',
            actionLabel: 'AI reorder tips',
            onAction: () => ctrl.runAssist('inventory_forecast'),
          ),
          const SizedBox(height: TaifaSpacing.lg),
          ...state.assistTips.map((t) => ListTile(leading: const Icon(LucideIcons.lightbulb), title: Text(t))),
          const SizedBox(height: TaifaSpacing.md),
          Text('Inventory', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          for (final p in state.products)
            Card(
              child: ListTile(
                title: Text(p.name),
                subtitle: Text(
                  'Avail ${p.stockAvailable} · Reserved ${p.stockReserved}',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    MosStatusChip(
                      p.isOutOfStock
                          ? 'Out'
                          : p.isLowStock
                              ? 'Low'
                              : 'OK',
                      tone: p.isOutOfStock
                          ? MosTone.danger
                          : p.isLowStock
                              ? MosTone.warning
                              : MosTone.success,
                    ),
                    TextButton(
                      onPressed: () => ctrl.receiveStock(p.id, 20),
                      child: const Text('Receive +20'),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: TaifaSpacing.lg),
          Text('Fulfillment queue', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          ...state.orders.where((o) => o.paid && o.status != 'fulfilled').map(
                (o) => ListTile(
                  title: Text(o.id),
                  subtitle: Text('${o.lines.length} lines · pick → pack'),
                  trailing: FilledButton.tonal(
                    onPressed: () => ctrl.fulfill(o.id),
                    child: const Text('Fulfill'),
                  ),
                ),
              ),
          if (state.orders.where((o) => o.paid && o.status != 'fulfilled').isEmpty)
            const MosEmpty('No paid orders waiting for pick/pack', icon: LucideIcons.truck),
        ],
      ),
    );
  }
}

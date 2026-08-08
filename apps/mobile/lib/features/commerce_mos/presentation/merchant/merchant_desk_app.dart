import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/taifa_colors.dart';
import '../../../../app/theme/taifa_dimens.dart';
import '../../application/mos_providers.dart';
import '../widgets/commerce_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Merchant Owner / Manager desk — today's business health.
class CommerceMerchantDeskApp extends ConsumerStatefulWidget {
  const CommerceMerchantDeskApp({super.key});

  @override
  ConsumerState<CommerceMerchantDeskApp> createState() => _CommerceMerchantDeskAppState();
}

class _CommerceMerchantDeskAppState extends ConsumerState<CommerceMerchantDeskApp> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mosControllerProvider.notifier).bootstrap();
      ref.read(mosControllerProvider.notifier).runAssist('briefing');
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mosControllerProvider);
    final a = state.analytics;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Merchant Desk'),
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft), onPressed: () => context.pop()),
        actions: [
          IconButton(
            tooltip: 'AI briefing',
            onPressed: () => ref.read(mosControllerProvider.notifier).runAssist('briefing'),
            icon: const Icon(LucideIcons.brain),
          ),
          IconButton(
            onPressed: () => context.push('/wallet'),
            icon: const Icon(LucideIcons.wallet),
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          ListView(
            padding: const EdgeInsets.all(TaifaSpacing.screenH),
            children: [
              MosNextAction(
                title: state.unpaidOrders.isNotEmpty
                    ? '${state.unpaidOrders.length} orders need payment'
                    : state.lowStockProducts.isNotEmpty
                        ? 'Inventory needs attention'
                        : 'Ready for today\'s sales',
                subtitle: state.lowStockProducts.isNotEmpty
                    ? '${state.lowStockProducts.length} SKUs low or out'
                    : 'Open POS or review Winga opportunities',
                actionLabel: state.unpaidOrders.isNotEmpty
                    ? 'Review orders'
                    : state.lowStockProducts.isNotEmpty
                        ? 'Open warehouse'
                        : 'Open POS',
                onAction: () {
                  if (state.unpaidOrders.isNotEmpty) {
                    setState(() => _tab = 1);
                  } else if (state.lowStockProducts.isNotEmpty) {
                    context.push('/commerce/warehouse');
                  } else {
                    context.push('/commerce/pos');
                  }
                },
              ),
              const SizedBox(height: TaifaSpacing.lg),
              MosStatGrid(
                items: [
                  ('Today GMV', _money(a.gmvMinor), TaifaColors.emerald600),
                  ('Paid orders', '${a.ordersPaid}', TaifaColors.ocean500),
                  ('Low stock', '${a.lowStock}', TaifaColors.gold500),
                  ('Customers', '${a.customers}', TaifaColors.emerald700),
                ],
              ),
              const SizedBox(height: TaifaSpacing.xl),
              Text('AI copilot', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              ...state.assistTips.map((t) => ListTile(leading: const Icon(LucideIcons.sparkles), title: Text(t))),
              if (state.error != null)
                Text(state.error!, style: TextStyle(color: Colors.red.shade700)),
            ],
          ),
          _OrdersTab(state: state),
          _CatalogTab(state: state),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(LucideIcons.layoutGrid), label: 'Home'),
          NavigationDestination(icon: Icon(LucideIcons.receipt), label: 'Orders'),
          NavigationDestination(icon: Icon(LucideIcons.package), label: 'Catalog'),
        ],
      ),
    );
  }

  String _money(int minor) {
    final v = minor / 100;
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}k';
    return v.toStringAsFixed(0);
  }
}

class _OrdersTab extends ConsumerWidget {
  const _OrdersTab({required this.state});
  final MosUiState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.orders.isEmpty) return const MosEmpty('No orders yet — make your first sale in POS');
    return ListView.separated(
      padding: const EdgeInsets.all(TaifaSpacing.screenH),
      itemCount: state.orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: TaifaSpacing.sm),
      itemBuilder: (context, i) {
        final o = state.orders[i];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(TaifaSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(o.id, style: const TextStyle(fontWeight: FontWeight.w800))),
                    MosStatusChip(o.paid ? 'paid' : o.status, tone: o.paid ? MosTone.success : MosTone.warning),
                  ],
                ),
                const SizedBox(height: TaifaSpacing.sm),
                MosOrderTimeline(currentIndex: o.paid ? (o.status == 'fulfilled' ? 6 : 2) : 1),
                const SizedBox(height: TaifaSpacing.sm),
                MosPaymentSummary(
                  amountMinor: o.totalMinor,
                  status: o.paid ? 'ledger confirmed' : 'awaiting payment',
                  paymentRef: o.paymentRef,
                ),
                if (o.paid && o.status != 'fulfilled')
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => ref.read(mosControllerProvider.notifier).fulfill(o.id),
                      child: const Text('Fulfill'),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CatalogTab extends ConsumerWidget {
  const _CatalogTab({required this.state});
  final MosUiState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(TaifaSpacing.screenH),
      children: [
        for (final p in state.products)
          MosProductTile(
            name: p.name,
            sku: p.sku,
            priceMinor: p.priceMinor,
            stockLabel: p.isOutOfStock
                ? 'Out of stock'
                : p.isLowStock
                    ? 'Low · ${p.stockAvailable}'
                    : 'Avail ${p.stockAvailable}',
            trailing: TextButton(
              onPressed: () async {
                await ref.read(mosControllerProvider.notifier).publishWinga(p.id);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${p.name} published to Winga')),
                );
              },
              child: const Text('Winga'),
            ),
          ),
      ],
    );
  }
}

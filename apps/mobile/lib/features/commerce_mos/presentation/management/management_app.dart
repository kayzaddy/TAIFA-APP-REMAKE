import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/taifa_colors.dart';
import '../../../../app/theme/taifa_dimens.dart';
import '../../application/mos_providers.dart';
import '../widgets/commerce_kit.dart';

/// Executive / branch manager analytics dashboard.
class CommerceManagementApp extends ConsumerStatefulWidget {
  const CommerceManagementApp({super.key});

  @override
  ConsumerState<CommerceManagementApp> createState() => _CommerceManagementAppState();
}

class _CommerceManagementAppState extends ConsumerState<CommerceManagementApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mosControllerProvider.notifier).bootstrap();
      ref.read(mosControllerProvider.notifier).runAssist('pricing');
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mosControllerProvider);
    final a = state.analytics;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Management'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        actions: [
          IconButton(
            onPressed: () => context.push('/winga'),
            icon: const Icon(Icons.handshake_outlined),
            tooltip: 'Winga',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(TaifaSpacing.screenH),
        children: [
          Text('Business performance', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: TaifaSpacing.lg),
          MosStatGrid(
            items: [
              ('GMV', _fmt(a.gmvMinor), TaifaColors.emerald600),
              ('Orders', '${a.ordersTotal}', TaifaColors.ocean500),
              ('Paid', '${a.ordersPaid}', TaifaColors.emerald700),
              ('SKU risk', '${a.lowStock}', TaifaColors.gold500),
            ],
          ),
          const SizedBox(height: TaifaSpacing.xl),
          ListTile(
            leading: const Icon(Icons.store),
            title: Text('Products · ${a.products}'),
            subtitle: Text(a.wingaEnabled ? 'Winga publishing enabled' : 'Winga not linked'),
          ),
          ListTile(
            leading: const Icon(Icons.groups_outlined),
            title: Text('Customers · ${a.customers}'),
          ),
          ListTile(
            leading: const Icon(Icons.local_shipping_outlined),
            title: const Text('Mobility deliveries'),
            subtitle: const Text('Dispatch refs attach on fulfillment (shared Mobility)'),
            onTap: () => context.push('/mobility'),
          ),
          const SizedBox(height: TaifaSpacing.lg),
          Text('Growth recommendations', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          ...state.assistTips.map((t) => ListTile(leading: const Icon(Icons.trending_up), title: Text(t))),
          const SizedBox(height: TaifaSpacing.lg),
          Text('Top products', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          for (final p in state.products.take(5))
            MosProductTile(
              name: p.name,
              sku: p.sku,
              priceMinor: p.priceMinor,
              stockLabel: 'Avail ${p.stockAvailable}',
            ),
        ],
      ),
    );
  }

  String _fmt(int minor) {
    final v = minor / 100;
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}k';
    return v.toStringAsFixed(0);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/taifa_dimens.dart';
import '../../application/mos_providers.dart';
import '../widgets/commerce_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Procurement officer — suppliers, POs, vendor performance.
class CommerceProcurementApp extends ConsumerStatefulWidget {
  const CommerceProcurementApp({super.key});

  @override
  ConsumerState<CommerceProcurementApp> createState() => _CommerceProcurementAppState();
}

class _CommerceProcurementAppState extends ConsumerState<CommerceProcurementApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mosControllerProvider.notifier).bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mosControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Procurement'),
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft), onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(TaifaSpacing.screenH),
        children: [
          MosNextAction(
            title: state.purchaseOrders.isEmpty
                ? 'No open purchase orders'
                : '${state.purchaseOrders.length} PO(s) in flight',
            subtitle: 'Suppliers · receiving · approvals',
            actionLabel: state.lowStockProducts.isEmpty ? 'Review suppliers' : 'Reorder low stock',
            onAction: () {},
          ),
          const SizedBox(height: TaifaSpacing.xl),
          Text('Suppliers', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          for (final s in state.suppliers)
            ListTile(
              leading: const Icon(LucideIcons.truck),
              title: Text(s.name),
              subtitle: Text(s.code),
              trailing: Text('${s.rating.toStringAsFixed(1)}★'),
            ),
          const SizedBox(height: TaifaSpacing.lg),
          Text('Purchase orders', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          if (state.purchaseOrders.isEmpty)
            const MosEmpty('Create POs from the MOS API when ready')
          else
            for (final po in state.purchaseOrders)
              Card(
                child: ListTile(
                  title: Text(po.id),
                  subtitle: Text('${po.supplierName} · ${po.status}'),
                  trailing: MosMoneyText(po.totalMinor),
                ),
              ),
        ],
      ),
    );
  }
}

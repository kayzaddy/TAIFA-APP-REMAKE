import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/taifa_colors.dart';
import '../../../../app/theme/taifa_dimens.dart';
import '../../application/mos_providers.dart';
import '../widgets/commerce_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Cashier POS — fast search, favorites, cart, ledger pay.
class CommercePosApp extends ConsumerStatefulWidget {
  const CommercePosApp({super.key});

  @override
  ConsumerState<CommercePosApp> createState() => _CommercePosAppState();
}

class _CommercePosAppState extends ConsumerState<CommercePosApp> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ctrl = ref.read(mosControllerProvider.notifier);
      await ctrl.bootstrap();
      if (ref.read(mosControllerProvider).posSession?.isOpen != true) {
        await ctrl.openPos();
      }
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mosControllerProvider);
    final ctrl = ref.read(mosControllerProvider.notifier);
    final favorites = state.products.where((p) => p.favorite).toList();
    final catalog = state.products.where((p) => !p.isOutOfStock).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Point of Sale'),
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft), onPressed: () => context.pop()),
        actions: [
          MosStatusChip(
            state.posSession?.isOpen == true ? 'Shift open' : 'Shift closed',
            tone: state.posSession?.isOpen == true ? MosTone.success : MosTone.warning,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(TaifaSpacing.screenH),
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                prefixIcon: Icon(LucideIcons.scanLine),
                hintText: 'Search SKU, name, or scan barcode',
                border: OutlineInputBorder(),
              ),
              onChanged: ctrl.search,
            ),
          ),
          if (favorites.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: TaifaSpacing.screenH),
                child: Text('Favorites', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: TaifaSpacing.screenH),
                children: [
                  for (final p in favorites)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(p.name),
                        onPressed: () => ctrl.addToCart(p),
                      ),
                    ),
                ],
              ),
            ),
          ],
          Expanded(
            child: ListView.builder(
              itemCount: catalog.length,
              itemBuilder: (context, i) {
                final p = catalog[i];
                return MosProductTile(
                  name: p.name,
                  sku: p.sku,
                  priceMinor: p.priceMinor,
                  stockLabel: 'Avail ${p.stockAvailable}',
                  onTap: () => ctrl.addToCart(p),
                  trailing: IconButton(
                    icon: const Icon(LucideIcons.shoppingCart),
                    onPressed: () => ctrl.addToCart(p),
                  ),
                );
              },
            ),
          ),
          _CartBar(state: state),
        ],
      ),
    );
  }
}

class _CartBar extends ConsumerWidget {
  const _CartBar({required this.state});
  final MosUiState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(mosControllerProvider.notifier);
    return Material(
      elevation: 8,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(TaifaSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text('${state.cart.length} lines', style: const TextStyle(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  MosMoneyText(
                    state.cartTotalMinor,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                ],
              ),
              if (state.cart.isNotEmpty) ...[
                const SizedBox(height: TaifaSpacing.sm),
                MosPaymentSummary(
                  amountMinor: state.cartTotalMinor,
                  status: 'ready to capture via Taifa Payments',
                ),
              ],
              const SizedBox(height: TaifaSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: state.cart.isEmpty ? null : ctrl.clearCart,
                      child: const Text('Clear'),
                    ),
                  ),
                  const SizedBox(width: TaifaSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: state.isBusy || state.cart.isEmpty
                          ? null
                          : () async {
                              final order = await ctrl.checkoutCart();
                              if (!context.mounted || order == null) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Sale complete · ${order.paymentRef}'),
                                  backgroundColor: TaifaColors.emerald700,
                                ),
                              );
                            },
                      child: Text(state.isBusy ? 'Processing…' : 'Charge'),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => ctrl.closePos(closingCashMinor: state.cartTotalMinor),
                child: const Text('Close shift'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

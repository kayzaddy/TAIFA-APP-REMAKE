import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/taifa_colors.dart';
import '../../../../app/theme/taifa_dimens.dart';
import '../../application/mos_providers.dart';
import '../widgets/commerce_kit.dart';

/// Customer commerce experience — browse, cart, pay, track.
class CommerceCustomerApp extends ConsumerStatefulWidget {
  const CommerceCustomerApp({super.key});

  @override
  ConsumerState<CommerceCustomerApp> createState() => _CommerceCustomerAppState();
}

class _CommerceCustomerAppState extends ConsumerState<CommerceCustomerApp> {
  int _tab = 0;
  final _wishlist = <String>{};

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
    final ctrl = ref.read(mosControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          ListView(
            padding: const EdgeInsets.all(TaifaSpacing.screenH),
            children: [
              TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search products',
                  border: OutlineInputBorder(),
                ),
                onChanged: ctrl.search,
              ),
              const SizedBox(height: TaifaSpacing.lg),
              for (final p in state.products.where((p) => !p.isOutOfStock))
                MosProductTile(
                  name: p.name,
                  sku: p.category,
                  priceMinor: p.priceMinor,
                  stockLabel: 'In stock',
                  onTap: () => ctrl.addToCart(p),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          _wishlist.contains(p.id) ? Icons.favorite : Icons.favorite_border,
                          color: TaifaColors.gold500,
                        ),
                        onPressed: () => setState(() {
                          if (!_wishlist.add(p.id)) _wishlist.remove(p.id);
                        }),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_shopping_cart),
                        onPressed: () => ctrl.addToCart(p),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          _CartCheckout(state: state),
          _TrackOrders(state: state),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.storefront_outlined), label: 'Browse'),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: state.cart.isNotEmpty,
              label: Text('${state.cart.length}'),
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            label: 'Cart',
          ),
          const NavigationDestination(icon: Icon(Icons.local_shipping_outlined), label: 'Orders'),
        ],
      ),
    );
  }
}

class _CartCheckout extends ConsumerWidget {
  const _CartCheckout({required this.state});
  final MosUiState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(mosControllerProvider.notifier);
    if (state.cart.isEmpty) return const MosEmpty('Your cart is empty');
    return ListView(
      padding: const EdgeInsets.all(TaifaSpacing.screenH),
      children: [
        for (final c in state.cart)
          ListTile(
            title: Text(c.product.name),
            subtitle: Text('× ${c.quantity}'),
            trailing: MosMoneyText(c.lineTotalMinor),
          ),
        MosPaymentSummary(
          amountMinor: state.cartTotalMinor,
          status: 'checkout ready',
        ),
        const SizedBox(height: TaifaSpacing.lg),
        FilledButton(
          onPressed: state.isBusy
              ? null
              : () async {
                  final order = await ctrl.checkoutCart();
                  if (!context.mounted || order == null) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Order ${order.id} paid securely')),
                  );
                },
          child: const Text('Pay securely'),
        ),
      ],
    );
  }
}

class _TrackOrders extends StatelessWidget {
  const _TrackOrders({required this.state});
  final MosUiState state;

  @override
  Widget build(BuildContext context) {
    if (state.orders.isEmpty) return const MosEmpty('No orders yet');
    return ListView.builder(
      padding: const EdgeInsets.all(TaifaSpacing.screenH),
      itemCount: state.orders.length,
      itemBuilder: (context, i) {
        final o = state.orders[i];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(TaifaSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(o.id, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                MosOrderTimeline(currentIndex: o.status == 'fulfilled' ? 6 : (o.paid ? 2 : 1)),
                if (o.paymentRef.isNotEmpty)
                  Text('Receipt · ${o.paymentRef}', style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
        );
      },
    );
  }
}

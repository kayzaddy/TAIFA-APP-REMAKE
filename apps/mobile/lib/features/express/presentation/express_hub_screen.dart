import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../application/express_providers.dart';

/// Taifa Express hub — Smart Shopping List first.
class ExpressHubScreen extends ConsumerStatefulWidget {
  const ExpressHubScreen({super.key});

  @override
  ConsumerState<ExpressHubScreen> createState() => _ExpressHubScreenState();
}

class _ExpressHubScreenState extends ConsumerState<ExpressHubScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(expressControllerProvider.notifier).loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expressControllerProvider);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Taifa Express'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(TaifaSpacing.screenH),
        children: [
          Text(
            'Think in shopping lists.',
            style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: TaifaSpacing.sm),
          Text(
            'Write what you need. Express matches inventory, checks out, and shows live delivery.',
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: TaifaSpacing.xl),
          FilledButton.icon(
            onPressed: () => context.push('/express/list'),
            icon: const Icon(Icons.edit_note),
            label: const Text('Write Shopping List'),
          ),
          const SizedBox(height: TaifaSpacing.sm),
          OutlinedButton.icon(
            onPressed: state.basket.isEmpty
                ? null
                : () => context.push('/express/basket'),
            icon: const Icon(Icons.shopping_basket_outlined),
            label: Text(
              state.basket.isEmpty
                  ? 'Basket Review'
                  : 'Basket Review (${state.basket.length})',
            ),
          ),
          const SizedBox(height: TaifaSpacing.xl),
          Text('How it works', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('1. Write Shopping List\n2. Add To Basket\n3. CHECKOUT\n4. Watch Delivery Live',
              style: text.bodyMedium),
          if (state.lastOrder != null) ...[
            const SizedBox(height: TaifaSpacing.xl),
            Text('Active order', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(state.lastOrder!.publicCode),
              subtitle: Text(
                '${state.lastOrder!.status} · ${state.lastOrder!.storeName}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/express/track/${state.lastOrder!.id}'),
            ),
          ],
          if (state.orders.isNotEmpty) ...[
            const SizedBox(height: TaifaSpacing.lg),
            Text('Recent', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ...state.orders.take(5).map(
              (o) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.local_shipping_outlined, color: TaifaColors.emerald600),
                title: Text(o.publicCode),
                subtitle: Text('${o.status} · ${o.totalMinor} ${o.currency}'),
                onTap: () => context.push('/express/track/${o.id}'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

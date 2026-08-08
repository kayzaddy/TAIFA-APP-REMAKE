import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../application/express_providers.dart';
import '../domain/express_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Review matched list items before one-tap checkout.
class BasketReviewScreen extends ConsumerStatefulWidget {
  const BasketReviewScreen({super.key});

  @override
  ConsumerState<BasketReviewScreen> createState() => _BasketReviewScreenState();
}

class _BasketReviewScreenState extends ConsumerState<BasketReviewScreen> {
  final _address = TextEditingController(text: 'Masaki, Dar es Salaam');
  final _notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(expressControllerProvider.notifier).refreshQuote();
    });
  }

  @override
  void dispose() {
    _address.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _checkout() async {
    final ctrl = ref.read(expressControllerProvider.notifier);
    ctrl.setAddress(_address.text);
    ctrl.setNotes(_notes.text);
    final order = await ctrl.checkout(autoReady: true);
    if (!mounted || order == null) return;
    context.go('/express/track/${order.id}');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expressControllerProvider);
    final ctrl = ref.read(expressControllerProvider.notifier);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final quote = state.quote;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Basket Review'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/express/list');
            }
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(TaifaSpacing.screenH),
        children: [
          Text(
            'Review your list',
            style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Edit quantities, then CHECKOUT — Express finds the merchant and rider.',
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: TaifaSpacing.lg),
          if (state.basket.isEmpty)
            Text('Basket is empty. Write a shopping list first.', style: text.bodyLarge)
          else
            ...List.generate(state.basket.length, (i) {
              final item = state.basket[i];
              return _BasketTile(
                item: item,
                onMinus: () {
                  if (item.qty <= 1) {
                    ctrl.removeBasketItem(i);
                  } else {
                    ctrl.updateBasketItem(i, item.copyWith(qty: item.qty - 1));
                  }
                  ctrl.refreshQuote();
                },
                onPlus: () {
                  ctrl.updateBasketItem(i, item.copyWith(qty: item.qty + 1));
                  ctrl.refreshQuote();
                },
                onDelete: () {
                  ctrl.removeBasketItem(i);
                  ctrl.refreshQuote();
                },
              );
            }),
          if (state.unknown.isNotEmpty) ...[
            const SizedBox(height: TaifaSpacing.md),
            Text('Could not match', style: text.titleSmall),
            ...state.unknown.map(
              (u) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(LucideIcons.circleHelp, color: scheme.error),
                title: Text(u.name),
                subtitle: const Text('Try another name or remove'),
              ),
            ),
          ],
          const SizedBox(height: TaifaSpacing.xl),
          TextField(
            controller: _address,
            decoration: const InputDecoration(
              labelText: 'Delivery address',
              border: OutlineInputBorder(),
            ),
            onChanged: ctrl.setAddress,
          ),
          const SizedBox(height: TaifaSpacing.sm),
          TextField(
            controller: _notes,
            decoration: const InputDecoration(
              labelText: 'Order notes (optional)',
              border: OutlineInputBorder(),
            ),
            onChanged: ctrl.setNotes,
          ),
          const SizedBox(height: TaifaSpacing.md),
          Text('Payment', style: text.titleSmall),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'prepaid', label: Text('Wallet now')),
              ButtonSegment(value: 'on_delivery', label: Text('On delivery')),
            ],
            selected: {state.paymentTiming},
            onSelectionChanged: (s) => ctrl.setPaymentTiming(s.first),
          ),
          const SizedBox(height: TaifaSpacing.md),
          if (quote != null) ...[
            _FeeRow(label: 'Basket', value: '${quote.subtotalMinor} ${quote.currency}'),
            _FeeRow(label: 'Delivery', value: '${quote.deliveryFeeMinor} ${quote.currency}'),
            _FeeRow(label: 'Platform fee', value: '${quote.platformFeeMinor} ${quote.currency}'),
            const Divider(),
            _FeeRow(
              label: 'Total',
              value: '${quote.totalMinor} ${quote.currency}',
              bold: true,
            ),
            Text(
              'ETA ~${quote.etaMinutes} min'
              '${quote.storeName.isEmpty ? '' : ' · ${quote.storeName}'}',
              style: text.bodySmall,
            ),
          ] else if (state.basket.isNotEmpty)
            Text(
              'Subtotal ~${state.basketSubtotal} TZS',
              style: text.bodyMedium,
            ),
          if (state.error != null) ...[
            const SizedBox(height: TaifaSpacing.sm),
            Text(state.error!, style: text.bodyMedium?.copyWith(color: scheme.error)),
          ],
          const SizedBox(height: TaifaSpacing.lg),
          FilledButton(
            onPressed: state.isBusy || state.basket.isEmpty ? null : _checkout,
            child: Text(state.isBusy ? 'Starting fulfillment…' : 'CHECKOUT'),
          ),
        ],
      ),
    );
  }
}

class _BasketTile extends StatelessWidget {
  const _BasketTile({
    required this.item,
    required this.onMinus,
    required this.onPlus,
    required this.onDelete,
  });

  final ExpressBasketItem item;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(LucideIcons.circleCheckBig, color: TaifaColors.emerald600),
      title: Text(
        item.unit.isEmpty ? item.name : '${item.name} (${item.unit})',
        style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        [
          if (item.storeName.isNotEmpty) item.storeName,
          if (item.priceMinor > 0) '${item.lineTotalMinor} TZS',
        ].join(' · '),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            onPressed: onMinus,
            icon: const Icon(LucideIcons.circleMinus, size: 20),
          ),
          Text('×${item.qty}', style: text.titleSmall),
          IconButton(
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            onPressed: onPlus,
            icon: const Icon(LucideIcons.circlePlus, size: 20),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            onPressed: onDelete,
            icon: const Icon(LucideIcons.trash2, size: 20),
          ),
        ],
      ),
    );
  }
}

class _FeeRow extends StatelessWidget {
  const _FeeRow({required this.label, required this.value, this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label, style: style),
          const Spacer(),
          Text(value, style: style),
        ],
      ),
    );
  }
}

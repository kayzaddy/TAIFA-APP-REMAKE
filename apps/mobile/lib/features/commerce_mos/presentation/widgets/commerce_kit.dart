import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/taifa_colors.dart';
import '../../../../app/theme/taifa_dimens.dart';

/// Taifa Commerce design system primitives for MOS journeys.
class MosMoneyText extends StatelessWidget {
  const MosMoneyText(this.minor, {super.key, this.currency = 'TZS', this.style});

  final int minor;
  final String currency;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final v = minor / 100;
    final formatted = v.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return Text('$currency $formatted', style: style);
  }
}

class MosStatusChip extends StatelessWidget {
  const MosStatusChip(this.label, {super.key, this.tone = MosTone.neutral});

  final String label;
  final MosTone tone;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      MosTone.success => TaifaColors.emerald600,
      MosTone.warning => TaifaColors.gold500,
      MosTone.danger => Colors.red.shade700,
      MosTone.info => TaifaColors.ocean500,
      MosTone.neutral => Theme.of(context).colorScheme.outline,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(TaifaRadii.pill),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

enum MosTone { success, warning, danger, info, neutral }

class MosNextAction extends StatelessWidget {
  const MosNextAction({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TaifaColors.emerald700.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(TaifaRadii.xl),
      child: Padding(
        padding: const EdgeInsets.all(TaifaSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: TaifaSpacing.md),
            FilledButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                onAction();
              },
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class MosOrderTimeline extends StatelessWidget {
  const MosOrderTimeline({super.key, required this.currentIndex});

  final int currentIndex;

  static const stages = [
    'Draft',
    'Open',
    'Paid',
    'Pick',
    'Pack',
    'Ship',
    'Done',
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final idx = currentIndex.clamp(0, stages.length - 1);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < stages.length; i++) ...[
            if (i > 0)
              Container(
                width: 12,
                height: 2,
                color: i <= idx ? TaifaColors.emerald600 : scheme.outlineVariant,
              ),
            Column(
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundColor: i <= idx ? TaifaColors.emerald600 : scheme.surfaceContainerHighest,
                  foregroundColor: i <= idx ? Colors.white : scheme.onSurfaceVariant,
                  child: Text('${i + 1}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                ),
                Text(stages[i], style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class MosProductTile extends StatelessWidget {
  const MosProductTile({
    super.key,
    required this.name,
    required this.sku,
    required this.priceMinor,
    required this.stockLabel,
    this.onTap,
    this.trailing,
  });

  final String name;
  final String sku;
  final int priceMinor;
  final String stockLabel;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text('$sku · $stockLabel'),
      trailing: trailing ?? MosMoneyText(priceMinor),
    );
  }
}

class MosStatGrid extends StatelessWidget {
  const MosStatGrid({super.key, required this.items});

  final List<(String, String, Color)> items;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: TaifaSpacing.sm,
      crossAxisSpacing: TaifaSpacing.sm,
      childAspectRatio: 1.45,
      children: [
        for (final (label, value, color) in items)
          Material(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(TaifaRadii.lg),
            child: Padding(
              padding: const EdgeInsets.all(TaifaSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelMedium),
                  const Spacer(),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class MosPaymentSummary extends StatelessWidget {
  const MosPaymentSummary({
    super.key,
    required this.amountMinor,
    required this.status,
    this.paymentRef = '',
    this.taxMinor = 0,
    this.discountMinor = 0,
  });

  final int amountMinor;
  final String status;
  final String paymentRef;
  final int taxMinor;
  final int discountMinor;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(TaifaSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payment transparency', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: TaifaSpacing.sm),
            _row('Amount', MosMoneyText(amountMinor)),
            if (taxMinor > 0) _row('Tax', MosMoneyText(taxMinor)),
            if (discountMinor > 0) _row('Discount', MosMoneyText(discountMinor)),
            _row('Status', Text(status)),
            if (paymentRef.isNotEmpty) _row('Ledger ref', Text(paymentRef)),
            const SizedBox(height: 4),
            Text(
              'Settles via Taifa Payments · AI never authorizes money.',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String k, Widget v) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [Expanded(child: Text(k)), v]),
      );
}

class MosEmpty extends StatelessWidget {
  const MosEmpty(this.message, {super.key, this.icon = Icons.inbox_outlined});
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TaifaSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: TaifaSpacing.md),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

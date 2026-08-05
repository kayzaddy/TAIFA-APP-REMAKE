import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/taifa_colors.dart';
import '../../../../app/theme/taifa_dimens.dart';

/// Experience-layer primitives — answers “what next?” on every surface.
class WingaJourneyStepper extends StatelessWidget {
  const WingaJourneyStepper({
    super.key,
    required this.steps,
    required this.currentIndex,
  });

  final List<String> steps;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0)
              Container(
                width: 16,
                height: 2,
                color: i <= currentIndex
                    ? TaifaColors.emerald600
                    : scheme.outlineVariant,
              ),
            Column(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: i < currentIndex
                      ? TaifaColors.emerald600
                      : i == currentIndex
                          ? TaifaColors.gold500
                          : scheme.surfaceContainerHighest,
                  foregroundColor: i <= currentIndex
                      ? Colors.white
                      : scheme.onSurfaceVariant,
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  steps[i],
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight:
                            i == currentIndex ? FontWeight.w800 : FontWeight.w500,
                        color: i == currentIndex
                            ? scheme.onSurface
                            : scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class WingaTrustBadge extends StatelessWidget {
  const WingaTrustBadge({
    super.key,
    required this.label,
    this.verified = true,
  });

  final String label;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final color = verified ? TaifaColors.emerald600 : TaifaColors.gray500;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(TaifaRadii.pill),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            verified ? Icons.verified : Icons.hourglass_empty,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class WingaNextActionBar extends StatelessWidget {
  const WingaNextActionBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: TaifaColors.emerald700.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(TaifaRadii.xl),
      child: Padding(
        padding: const EdgeInsets.all(TaifaSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: TaifaSpacing.md),
            Row(
              children: [
                if (secondaryLabel != null && onSecondary != null) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onSecondary,
                      child: Text(secondaryLabel!),
                    ),
                  ),
                  const SizedBox(width: TaifaSpacing.sm),
                ],
                Expanded(
                  flex: secondaryLabel == null ? 1 : 1,
                  child: FilledButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      onAction();
                    },
                    child: Text(actionLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class WingaLoadingBlock extends StatelessWidget {
  const WingaLoadingBlock({super.key, this.label = 'Loading…'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TaifaSpacing.xxl),
      child: Column(
        children: [
          const LinearProgressIndicator(),
          const SizedBox(height: TaifaSpacing.md),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class WingaOfflineBanner extends StatelessWidget {
  const WingaOfflineBanner({super.key, this.message = 'Offline mode · changes sync when connected'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TaifaColors.ocean500.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: TaifaSpacing.screenH,
          vertical: TaifaSpacing.sm,
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_outlined, size: 18, color: TaifaColors.ocean500),
            const SizedBox(width: TaifaSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: TaifaColors.ocean500,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WingaCommissionBreakdown extends StatelessWidget {
  const WingaCommissionBreakdown({
    super.key,
    required this.dealAmountMinor,
    required this.commissionMinor,
    required this.status,
    this.currency = 'TZS',
    this.bps = 0,
    this.providerName = '',
  });

  final int dealAmountMinor;
  final int commissionMinor;
  final String status;
  final String currency;
  final int bps;
  final String providerName;

  String _fmt(int minor) {
    final v = minor / 100;
    return '$currency ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TaifaRadii.lg)),
      child: Padding(
        padding: const EdgeInsets.all(TaifaSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Commission transparency',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: TaifaSpacing.md),
            _row('Deal value', _fmt(dealAmountMinor)),
            _row('Rate', bps > 0 ? '${(bps / 100).toStringAsFixed(1)}%' : '—'),
            _row('Your share', _fmt(commissionMinor), emphasize: true),
            _row('Status', status),
            if (providerName.isNotEmpty) _row('Provider', providerName),
            const SizedBox(height: TaifaSpacing.sm),
            Text(
              'Settled to your Taifa Wallet via the ledger. AI never moves money.',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String k, String v, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(k)),
          Text(
            v,
            style: TextStyle(
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
              color: emphasize ? TaifaColors.emerald700 : null,
            ),
          ),
        ],
      ),
    );
  }
}

class WingaPaymentSummary extends StatelessWidget {
  const WingaPaymentSummary({
    super.key,
    required this.amountMinor,
    required this.currency,
    required this.payee,
    required this.status,
    this.paymentRef = '',
  });

  final int amountMinor;
  final String currency;
  final String payee;
  final String status;
  final String paymentRef;

  @override
  Widget build(BuildContext context) {
    final major = amountMinor / 100;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(TaifaSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payment', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: TaifaSpacing.sm),
            Text(
              '$currency ${major.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: TaifaColors.emerald700,
                  ),
            ),
            const SizedBox(height: TaifaSpacing.sm),
            Text('To · $payee'),
            Text('Status · $status'),
            if (paymentRef.isNotEmpty) Text('Receipt · $paymentRef'),
          ],
        ),
      ),
    );
  }
}

class WingaOpportunityCard extends StatelessWidget {
  const WingaOpportunityCard({
    super.key,
    required this.title,
    required this.industry,
    required this.location,
    required this.commissionLabel,
    required this.urgency,
    this.trending = false,
    this.onApply,
    this.onSave,
  });

  final String title;
  final String industry;
  final String location;
  final String commissionLabel;
  final String urgency;
  final bool trending;
  final VoidCallback? onApply;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TaifaRadii.xl),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(TaifaSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (trending)
                  const WingaTrustBadge(label: 'Trending', verified: true),
                if (trending) const SizedBox(width: 6),
                WingaTrustBadge(label: urgency, verified: urgency != 'Closing soon'),
                const Spacer(),
                if (onSave != null)
                  IconButton(
                    onPressed: onSave,
                    icon: const Icon(Icons.bookmark_border),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: TaifaSpacing.sm),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '$industry · $location',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: TaifaSpacing.md),
            Row(
              children: [
                Text(
                  commissionLabel,
                  style: const TextStyle(
                    color: TaifaColors.goldDeep,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                if (onApply != null)
                  FilledButton.tonal(
                    onPressed: onApply,
                    child: const Text('Apply'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class WingaGoalHeader extends StatelessWidget {
  const WingaGoalHeader({
    super.key,
    required this.goal,
    required this.hint,
  });

  final String goal;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          goal,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          hint,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/taifa_colors.dart';
import '../../../../app/theme/taifa_dimens.dart';

/// Shared Winga brokerage UI primitives on top of Taifa design tokens.
class WingaMoneyText extends StatelessWidget {
  const WingaMoneyText(
    this.minor, {
    super.key,
    this.currency = 'TZS',
    this.style,
  });

  final int minor;
  final String currency;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final major = minor / 100;
    final formatted = major >= 1000
        ? major.toStringAsFixed(0).replaceAllMapped(
              RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
              (m) => '${m[1]},',
            )
        : major.toStringAsFixed(0);
    return Text(
      '$currency $formatted',
      style: style ?? Theme.of(context).textTheme.titleMedium,
    );
  }
}

class WingaSectionHeader extends StatelessWidget {
  const WingaSectionHeader(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TaifaSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class WingaStatCard extends StatelessWidget {
  const WingaStatCard({
    super.key,
    required this.label,
    required this.value,
    this.accent = TaifaColors.emerald600,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(TaifaSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(TaifaRadii.lg),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: TaifaSpacing.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class WingaChipRow extends StatelessWidget {
  const WingaChipRow({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });

  final List<String> labels;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: TaifaSpacing.xs),
        itemBuilder: (context, i) {
          if (i == 0) {
            return FilterChip(
              label: const Text('All'),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
            );
          }
          final label = labels[i - 1];
          return FilterChip(
            label: Text(label),
            selected: selected == label,
            onSelected: (_) => onSelected(label),
          );
        },
      ),
    );
  }
}

class WingaOfferingTile extends StatelessWidget {
  const WingaOfferingTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.priceMinor,
    required this.kind,
    this.favorited = false,
    this.onTap,
    this.onFavorite,
  });

  final String title;
  final String subtitle;
  final int priceMinor;
  final String kind;
  final bool favorited;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(TaifaRadii.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TaifaRadii.lg),
        child: Padding(
          padding: const EdgeInsets.all(TaifaSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: TaifaColors.emerald700.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(TaifaRadii.md),
                ),
                child: Text(
                  kind.isEmpty ? '?' : kind[0].toUpperCase(),
                  style: const TextStyle(
                    color: TaifaColors.emerald700,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: TaifaSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    WingaMoneyText(
                      priceMinor,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: TaifaColors.goldDeep,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
              if (onFavorite != null)
                IconButton(
                  onPressed: onFavorite,
                  icon: Icon(
                    favorited ? Icons.favorite : Icons.favorite_border,
                    color:
                        favorited ? TaifaColors.danger : scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class WingaPipelineCard extends StatelessWidget {
  const WingaPipelineCard({
    super.key,
    required this.title,
    required this.stage,
    required this.subtitle,
    this.onTap,
  });

  final String title;
  final String stage;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TaifaRadii.lg),
      ),
      tileColor: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(alpha: 0.35),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Chip(
        label: Text(stage, style: const TextStyle(fontSize: 11)),
        visualDensity: VisualDensity.compact,
        backgroundColor: TaifaColors.ocean500.withValues(alpha: 0.12),
      ),
    );
  }
}

class WingaEmptyState extends StatelessWidget {
  const WingaEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });

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
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> wingaHaptic() => HapticFeedback.selectionClick();

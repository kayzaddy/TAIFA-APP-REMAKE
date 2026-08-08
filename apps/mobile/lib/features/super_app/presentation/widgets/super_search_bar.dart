import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/taifa_dimens.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Compact search entry used on Home — opens universal search.
class SuperSearchBar extends StatelessWidget {
  const SuperSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/search'),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TaifaSpacing.md,
            vertical: TaifaSpacing.md,
          ),
          child: Row(
            children: [
              Icon(LucideIcons.search, color: scheme.onSurfaceVariant),
              const SizedBox(width: TaifaSpacing.sm),
              Expanded(
                child: Text(
                  'Search Taifa — rides, pay, hotels, Winga…',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ),
              Icon(LucideIcons.mic, color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

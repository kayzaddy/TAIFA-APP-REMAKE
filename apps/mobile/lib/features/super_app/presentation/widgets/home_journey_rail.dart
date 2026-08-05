import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/taifa_dimens.dart';
import '../../application/super_app_providers.dart';

class HomeJourneyRail extends ConsumerWidget {
  const HomeJourneyRail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(homeJourneyProvider);
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('For you', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: TaifaSpacing.sm),
        SizedBox(
          height: 108,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: TaifaSpacing.sm),
            itemBuilder: (context, i) {
              final item = items[i];
              return SizedBox(
                width: 148,
                child: Material(
                  color: item.tint.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => context.push(item.route),
                    child: Padding(
                      padding: const EdgeInsets.all(TaifaSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(item.icon, color: item.tint),
                          const Spacer(),
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            item.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.labelSmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

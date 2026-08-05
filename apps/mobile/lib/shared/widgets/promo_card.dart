import 'package:flutter/material.dart';

import '../../app/theme/taifa_colors.dart';
import '../../app/theme/taifa_dimens.dart';
import '../../app/theme/taifa_theme.dart';
import 'taifa_pill.dart';

/// Merchandising / offer card (e.g. "Zanzibar Weekend -30%").
/// Matches the mockup `.card-promo`.
class PromoCard extends StatelessWidget {
  const PromoCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.badge,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(TaifaRadii.xl),
      child: Container(
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.symmetric(
          horizontal: TaifaSpacing.lg,
          vertical: TaifaSpacing.md,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              TaifaColors.ocean500.withValues(alpha: 0.18),
              TaifaColors.emerald600.withValues(alpha: 0.18),
            ],
          ),
          borderRadius: BorderRadius.circular(TaifaRadii.xl),
          border: Border.all(
            color: TaifaColors.ocean500.withValues(alpha: 0.30),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: TaifaSpacing.sm),
            TaifaPill(badge),
          ],
        ),
      ),
    );
  }
}

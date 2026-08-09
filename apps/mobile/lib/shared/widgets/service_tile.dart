import 'package:flutter/material.dart';

import '../../app/theme/taifa_dimens.dart';
import '../../app/theme/taifa_theme.dart';

/// A service launcher tile in the Home services grid. Matches the mockup `.svc`
/// component: a tinted rounded-square icon with a label below.
class ServiceTile extends StatelessWidget {
  const ServiceTile({
    super.key,
    required this.icon,
    required this.label,
    required this.tint,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color tint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(TaifaRadii.lg),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: TaifaSpacing.sm,
          horizontal: TaifaSpacing.xxs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    tint.withValues(alpha: palette.isDark ? 0.30 : 0.24),
                    tint.withValues(alpha: palette.isDark ? 0.10 : 0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(TaifaRadii.xl),
                border: Border.all(color: tint.withValues(alpha: 0.26)),
                // A tint-coloured glow in both themes, not just a flat black
                // shadow in light mode only — this is what turns "a square
                // with a small icon" into something that reads as lit.
                boxShadow: [
                  BoxShadow(
                    color: tint.withValues(alpha: palette.isDark ? 0.22 : 0.14),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, size: 26, color: tint),
            ),
            const SizedBox(height: TaifaSpacing.xs),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
                color: palette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

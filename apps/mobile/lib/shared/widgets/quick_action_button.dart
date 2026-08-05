import 'package:flutter/material.dart';

import '../../app/theme/taifa_colors.dart';
import '../../app/theme/taifa_dimens.dart';
import '../../app/theme/taifa_theme.dart';

/// One of the four primary wallet actions (Send · Scan QR · Top Up · Bills).
/// Matches the mockup `.qa` tile.
class QuickActionButton extends StatelessWidget {
  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(TaifaRadii.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: TaifaSpacing.md,
          horizontal: TaifaSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(TaifaRadii.lg),
          border: Border.all(color: palette.border),
          boxShadow: palette.isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    TaifaColors.emerald600.withValues(alpha: 0.20),
                    TaifaColors.emerald700.withValues(alpha: 0.40),
                  ],
                ),
                borderRadius: BorderRadius.circular(TaifaRadii.sm),
              ),
              child: Icon(icon, size: 16, color: palette.accent),
            ),
            const SizedBox(height: TaifaSpacing.xs),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                height: 1.2,
                color: palette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

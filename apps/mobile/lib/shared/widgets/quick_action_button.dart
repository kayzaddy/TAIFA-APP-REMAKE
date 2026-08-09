import 'package:flutter/material.dart';

import '../../app/theme/taifa_dimens.dart';
import '../../app/theme/taifa_icons.dart';
import '../../app/theme/taifa_theme.dart';
import 'taifa_icon_tile.dart';

/// One of the four primary wallet actions (Send · Scan QR · Top Up · Bills).
/// Matches the mockup `.qa` tile.
class QuickActionButton extends StatelessWidget {
  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    this.hue = TaifaIconHue.gold,
    this.onTap,
  });

  final IconData icon;
  final String label;

  /// Which of the four semantic hues the badge takes — gold for things you
  /// *do*, emerald for money arriving, ocean for scan/info. Defaults to gold
  /// since most quick actions are "do something" rather than "money in".
  final TaifaIconHue hue;
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
            // Was a flat 32px single-hue square with a 16px glyph (a 50%
            // fill ratio reads as a small icon lost in a box); the shared
            // tile brings it to the same size and duotone-glow language as
            // every other icon badge in the app, and 44px happens to also
            // clear the touch-target minimum this row previously missed.
            TaifaIconTile(icon: icon, hue: hue, size: 44, iconSize: TaifaIconSize.lg),
            const SizedBox(height: TaifaSpacing.xs),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
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

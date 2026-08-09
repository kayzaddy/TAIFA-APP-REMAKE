import 'package:flutter/material.dart';

import '../../app/theme/taifa_colors.dart';
import '../../app/theme/taifa_dimens.dart';
import '../../app/theme/taifa_icons.dart';
import '../../app/theme/taifa_theme.dart';
import 'taifa_pressable.dart';

/// Semantic hue for an icon tile. Colour carries meaning here — gold for
/// things you *do*, emerald for money arriving, ocean for information,
/// violet for AI — but it is never the *only* signal: every tile is labelled.
enum TaifaIconHue { gold, emerald, ocean, violet }

extension _HueColors on TaifaIconHue {
  Color get tint => switch (this) {
    TaifaIconHue.gold => TaifaColors.gold500,
    TaifaIconHue.emerald => TaifaColors.emerald500,
    TaifaIconHue.ocean => TaifaColors.ocean400,
    TaifaIconHue.violet => TaifaColors.violet,
  };

  Color get tintDeep => switch (this) {
    TaifaIconHue.gold => TaifaColors.goldDeep,
    TaifaIconHue.emerald => TaifaColors.emerald700,
    TaifaIconHue.ocean => TaifaColors.ocean500,
    TaifaIconHue.violet => TaifaColors.violetSoft,
  };
}

/// A duotone glyph in a tinted, rounded container — the app's standard
/// "feature affordance". Generalises the treatment that used to live only
/// inside `QuickActionButton`.
///
/// Ships in two shapes:
/// - [TaifaIconTile] — the badge alone, for list leading slots.
/// - [TaifaIconTile.labelled] via [TaifaFeatureTile] — badge + caption,
///   with a guaranteed ≥44px touch target.
class TaifaIconTile extends StatelessWidget {
  const TaifaIconTile({
    super.key,
    required this.icon,
    this.hue = TaifaIconHue.gold,
    this.color,
    this.size = 48,
    this.iconSize = TaifaIconSize.lg,
  });

  final IconData icon;
  final TaifaIconHue hue;

  /// Overrides [hue] with an exact brand colour, for callers that already
  /// carry a specific tint (e.g. the home journey rail's per-shortcut
  /// colour) rather than one of the four semantic hues. The "deep" shade
  /// used for gradients/glyphs is derived by mixing toward black.
  final Color? color;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final base = color ?? hue.tint;
    final deep = color != null ? Color.lerp(color, Colors.black, 0.32)! : hue.tintDeep;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          // Punchier stop than the old flat tint: the badge should read as
          // a small lit surface, not a translucent smear.
          colors: [
            base.withValues(alpha: palette.isDark ? 0.32 : 0.22),
            deep.withValues(alpha: palette.isDark ? 0.55 : 0.34),
          ],
        ),
        // Radius scales with size so a 44px chip and a 52px chip both read
        // as the same "squircle", rather than the bigger one looking boxier.
        borderRadius: BorderRadius.circular(size * 0.32),
        border: Border.all(color: base.withValues(alpha: 0.30)),
        boxShadow: [
          // A tinted glow (not a generic black drop shadow) is what makes a
          // duotone badge feel lit rather than pasted on — it picks up the
          // hue instead of muddying it, and it's the one part of this look
          // that a screenshot on a black background *needs* to read as
          // "polished" rather than "flat".
          BoxShadow(
            color: base.withValues(alpha: palette.isDark ? 0.28 : 0.18),
            blurRadius: size * 0.42,
            offset: Offset(0, size * 0.10),
          ),
        ],
      ),
      child: Icon(
        icon,
        size: iconSize,
        // Deepen the glyph in light mode so it clears the 3:1 non-text
        // contrast bar against the tinted fill.
        color: palette.isDark ? base : deep,
      ),
    );
  }
}

/// Icon tile + caption, sized as a real touch target. Used for the wallet's
/// Money Tools grid and any other "grid of features" surface.
class TaifaFeatureTile extends StatelessWidget {
  const TaifaFeatureTile({
    super.key,
    required this.icon,
    required this.label,
    this.hue = TaifaIconHue.gold,
    this.onTap,
    this.badgeCount,
  });

  final IconData icon;
  final String label;
  final TaifaIconHue hue;
  final VoidCallback? onTap;

  /// Optional unread/pending count rendered as a corner badge.
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final count = badgeCount ?? 0;

    return TaifaPressable(
      onTap: onTap,
      semanticLabel: count > 0 ? '$label, $count new' : label,
      child: ConstrainedBox(
        // Pro-rules: interactive area never below 44pt.
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: TaifaSpacing.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  TaifaIconTile(icon: icon, hue: hue, size: 52, iconSize: TaifaIconSize.xl),
                  if (count > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        constraints: const BoxConstraints(minWidth: 16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: TaifaColors.danger,
                          borderRadius: BorderRadius.circular(TaifaRadii.pill),
                          border: Border.all(color: palette.background, width: 1.5),
                        ),
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: TaifaSpacing.xs),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                  color: palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

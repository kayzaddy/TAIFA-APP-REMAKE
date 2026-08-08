import 'package:flutter/material.dart';

import '../../app/theme/taifa_colors.dart';
import '../../app/theme/taifa_dimens.dart';
import '../../app/theme/taifa_icons.dart';
import '../../app/theme/taifa_theme.dart';

/// The tone a status conveys, independent of which feature it came from.
enum TaifaStatusTone { pending, positive, negative, neutral }

/// One chip for every lifecycle status in the app.
///
/// Replaces three near-identical private implementations that had drifted
/// across the payment-links, money-requests and split-bills screens.
///
/// Pairs a glyph with the label rather than relying on colour alone, so the
/// state survives greyscale and colour-vision differences.
class TaifaStatusChip extends StatelessWidget {
  const TaifaStatusChip({
    super.key,
    required this.label,
    required this.tone,
    this.compact = false,
  });

  final String label;
  final TaifaStatusTone tone;

  /// Drops the glyph and tightens padding, for dense list rows.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;

    final (color, icon) = switch (tone) {
      TaifaStatusTone.pending => (TaifaColors.gold500, TaifaIcons.pending),
      TaifaStatusTone.positive => (
        palette.isDark ? TaifaColors.emerald500 : TaifaColors.emerald700,
        TaifaIcons.success,
      ),
      TaifaStatusTone.negative => (TaifaColors.danger, TaifaIcons.error),
      TaifaStatusTone.neutral => (palette.textMuted, TaifaIcons.info),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(TaifaRadii.pill),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!compact) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../app/theme/taifa_colors.dart';
import '../../app/theme/taifa_dimens.dart';

enum TaifaPillTone { gold, green, blue }

/// Compact status/label pill — matches the mockup `.pill` component.
class TaifaPill extends StatelessWidget {
  const TaifaPill(
    this.label, {
    super.key,
    this.tone = TaifaPillTone.gold,
    this.icon,
  });

  final String label;
  final TaifaPillTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (fg, bg, border) = switch (tone) {
      TaifaPillTone.gold => (
        TaifaColors.gold400,
        TaifaColors.gold500.withValues(alpha: 0.12),
        TaifaColors.gold500.withValues(alpha: 0.25),
      ),
      TaifaPillTone.green => (
        TaifaColors.emerald500,
        TaifaColors.emerald600.withValues(alpha: 0.12),
        TaifaColors.emerald600.withValues(alpha: 0.30),
      ),
      TaifaPillTone.blue => (
        TaifaColors.ocean400,
        TaifaColors.ocean500.withValues(alpha: 0.12),
        TaifaColors.ocean500.withValues(alpha: 0.30),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(TaifaRadii.pill),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

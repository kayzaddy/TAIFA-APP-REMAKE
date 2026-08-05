import 'package:flutter/material.dart';

import '../../../../app/theme/taifa_colors.dart';
import '../../../../app/theme/taifa_dimens.dart';
import '../../../../app/theme/taifa_theme.dart';
import '../../domain/currency.dart';

/// Horizontal currency selector (TSh · USD · EUR · KES · ₿). Matches the
/// mockup's currency switcher; drives the display conversion.
class CurrencySwitcher extends StatelessWidget {
  const CurrencySwitcher({
    super.key,
    required this.currencies,
    required this.selected,
    required this.onSelected,
  });

  final List<Currency> currencies;
  final Currency selected;
  final ValueChanged<Currency> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return Row(
      children: [
        for (final c in currencies) ...[
          if (c != currencies.first) const SizedBox(width: TaifaSpacing.xs),
          Expanded(
            child: GestureDetector(
              onTap: () => onSelected(c),
              child: AnimatedContainer(
                duration: TaifaMotion.fast,
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: c == selected
                      ? LinearGradient(
                          colors: [
                            TaifaColors.gold500.withValues(alpha: 0.20),
                            TaifaColors.gold500.withValues(alpha: 0.05),
                          ],
                        )
                      : null,
                  color: c == selected ? null : palette.surface,
                  borderRadius: BorderRadius.circular(TaifaRadii.sm),
                  border: Border.all(
                    color: c == selected ? palette.accent : palette.border,
                  ),
                ),
                child: Text(
                  c == Currency.tzs
                      ? 'TSh'
                      : (c == Currency.btc ? '₿' : c.code),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: c == selected
                        ? FontWeight.w700
                        : FontWeight.w600,
                    color: c == selected ? palette.accent : palette.textMuted,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

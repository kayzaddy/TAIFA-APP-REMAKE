import 'dart:ui';

import 'package:flutter/material.dart';

import '../../app/theme/taifa_colors.dart';
import '../../app/theme/taifa_dimens.dart';
import '../../app/theme/taifa_icons.dart';
import '../../app/theme/taifa_theme.dart';

class TaifaNavDestination {
  const TaifaNavDestination({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// Floating glass bottom navigation. Matches the mockup `.bottom-nav`:
/// Home · Mobility · AI · Wallet · Menu, with a gold active state.
class TaifaBottomNav extends StatelessWidget {
  const TaifaBottomNav({
    super.key,
    required this.destinations,
    required this.currentIndex,
    required this.onSelected,
  });

  final List<TaifaNavDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final radius = BorderRadius.circular(TaifaRadii.nav);

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: TaifaSpacing.xs),
          decoration: BoxDecoration(
            color: palette.navBackground,
            borderRadius: radius,
            border: Border.all(color: palette.navBorder),
            boxShadow: palette.isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 32,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < destinations.length; i++)
                _NavItem(
                  destination: destinations[i],
                  active: i == currentIndex,
                  onTap: () => onSelected(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.active,
    required this.onTap,
  });

  final TaifaNavDestination destination;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final activeColor = palette.isDark
        ? TaifaColors.gold400
        : TaifaColors.emerald700;
    final color = active ? activeColor : palette.textMuted;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TaifaRadii.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: TaifaMotion.fast,
              width: 42,
              height: 36,
              decoration: BoxDecoration(
                gradient: active
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          TaifaColors.gold500.withValues(alpha: 0.24),
                          TaifaColors.emerald600.withValues(alpha: 0.18),
                        ],
                      )
                    : null,
                borderRadius: BorderRadius.circular(TaifaRadii.sm),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.22),
                          blurRadius: 14,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              // Lucide is a single-weight family, so the selected state is
              // carried by the gold pill, the colour, a slightly larger glyph
              // and a bolder label rather than by swapping in a filled icon.
              // The scale happens inside the fixed-size pill, so nothing
              // around it reflows.
              child: AnimatedScale(
                scale: active ? 1.12 : 1,
                duration: TaifaMotion.fast,
                curve: TaifaMotion.standard,
                child: Icon(
                  destination.icon,
                  size: TaifaIconSize.lg,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              destination.label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

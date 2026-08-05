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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    tint.withValues(alpha: 0.20),
                    tint.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(TaifaRadii.lg),
                border: Border.all(
                  color: palette.borderStrong.withValues(alpha: 0.15),
                ),
                boxShadow: palette.isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Icon(icon, size: 20, color: tint),
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

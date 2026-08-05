import 'package:flutter/material.dart';

import '../../app/theme/taifa_colors.dart';
import '../../app/theme/taifa_dimens.dart';
import '../../app/theme/taifa_theme.dart';
import '../../app/theme/taifa_typography.dart';
import 'taifa_logo.dart';
import 'taifa_pill.dart';

/// Branded module-status surface for feature areas whose full build lands in a
/// later phase of the roadmap. Deliberately not a fake CRUD screen — it states
/// the module's intent and delivery status honestly, in the TAIFA design language.
class ModulePreviewScreen extends StatelessWidget {
  const ModulePreviewScreen({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.phaseLabel,
  });

  final IconData icon;
  final String title;
  final String description;
  final String phaseLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(TaifaSpacing.xxxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  const TaifaLogo(variant: TaifaLogoVariant.mark, size: 88),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: palette.surfaceAlt,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: TaifaColors.gold500.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Icon(icon, size: 16, color: palette.accent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TaifaSpacing.xxl),
              Text(
                title,
                style: TaifaTypography.sectionTitle(palette.textPrimary),
              ),
              const SizedBox(height: TaifaSpacing.md),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: palette.textSecondary,
                ),
              ),
              const SizedBox(height: TaifaSpacing.xxl),
              TaifaPill(phaseLabel, tone: TaifaPillTone.green),
            ],
          ),
        ),
      ),
    );
  }
}

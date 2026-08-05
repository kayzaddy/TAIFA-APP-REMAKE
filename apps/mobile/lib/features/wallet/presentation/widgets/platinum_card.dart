import 'package:flutter/material.dart';

import '../../../../app/theme/taifa_colors.dart';
import '../../../../app/theme/taifa_dimens.dart';
import '../../../../app/theme/taifa_typography.dart';
import '../../../../shared/widgets/taifa_logo.dart';

/// The TAIFA Platinum card — the fintech hero surface. Recreates the mockup's
/// premium card: basalt→emerald gradient, gold + ocean halos, a holographic
/// conic stripe, EMV/scheme marks, monospace PAN and serif balance.
class PlatinumCard extends StatelessWidget {
  const PlatinumCard({
    super.key,
    required this.cardholderName,
    required this.tier,
    required this.maskedPan,
    required this.balanceLabel,
  });

  final String cardholderName;
  final String tier;
  final String maskedPan;
  final String balanceLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            TaifaColors.black800,
            TaifaColors.black600,
            TaifaColors.emerald700,
          ],
          stops: [0.0, 0.4, 1.0],
        ),
        borderRadius: BorderRadius.circular(TaifaRadii.xxl + 2),
        border: Border.all(color: TaifaColors.gold500.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: TaifaColors.gold500.withValues(alpha: 0.15),
            blurRadius: 60,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -40,
            child: _Halo(
              color: TaifaColors.gold500.withValues(alpha: 0.40),
              size: 200,
            ),
          ),
          Positioned(
            bottom: -60,
            left: -20,
            child: _Halo(
              color: TaifaColors.ocean500.withValues(alpha: 0.30),
              size: 160,
            ),
          ),
          // Holographic stripe.
          Positioned(
            top: 84,
            right: 14,
            child: Container(
              width: 50,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                gradient: const SweepGradient(
                  startAngle: 0.6,
                  colors: [
                    TaifaColors.gold500,
                    TaifaColors.danger,
                    TaifaColors.ocean500,
                    TaifaColors.emerald600,
                    TaifaColors.gold500,
                  ],
                ),
              ),
              foregroundDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: TaifaColors.black900.withValues(alpha: 0.35),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tier,
                            style: TextStyle(
                              fontSize: 9,
                              letterSpacing: 2.4,
                              fontWeight: FontWeight.w700,
                              color: TaifaColors.gold400.withValues(alpha: 0.9),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            cardholderName,
                            style: TextStyle(
                              fontSize: 10,
                              color: TaifaColors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        const TaifaLogo(
                          variant: TaifaLogoVariant.mark,
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'TAIFA',
                          style: TaifaTypography.wordmark(TaifaColors.gold400),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 34),
                Text(
                  maskedPan,
                  style: TaifaTypography.mono(TaifaColors.white, size: 14),
                ),
                const SizedBox(height: TaifaSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BALANCE',
                            style: TextStyle(
                              fontSize: 8,
                              letterSpacing: 1.5,
                              color: TaifaColors.white.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            balanceLabel,
                            style: TaifaTypography.balance(
                              TaifaColors.white,
                            ).copyWith(fontSize: 24),
                          ),
                        ],
                      ),
                    ),
                    const _SchemeMark(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SchemeMark extends StatelessWidget {
  const _SchemeMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 18,
      child: Stack(
        children: [
          Container(
            width: 26,
            height: 18,
            decoration: BoxDecoration(
              color: TaifaColors.gold500.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Positioned(
            left: 14,
            child: Container(
              width: 26,
              height: 18,
              decoration: BoxDecoration(
                color: TaifaColors.white.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Halo extends StatelessWidget {
  const _Halo({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
          stops: const [0.0, 0.65],
        ),
      ),
    );
  }
}

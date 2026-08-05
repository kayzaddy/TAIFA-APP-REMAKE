import 'package:flutter/material.dart';

import '../../app/theme/taifa_colors.dart';
import '../../app/theme/taifa_dimens.dart';
import '../../app/theme/taifa_typography.dart';

/// Premium fintech wallet card — the hero surface of the Home screen.
///
/// Recreates the mockup `.wallet-card`: emerald→basalt gradient, a warm gold
/// halo top-right and an ocean halo bottom-left, EMV chip, masked PAN and the
/// TAIFA serif wordmark.
class WalletCard extends StatelessWidget {
  const WalletCard({
    super.key,
    required this.balance,
    required this.currencyLabel,
    required this.secondaryLabel,
    required this.maskedNumber,
    this.onTap,
  });

  final String balance;
  final String currencyLabel;
  final String secondaryLabel;
  final String maskedNumber;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: TaifaColors.walletCardGradient,
          borderRadius: BorderRadius.circular(TaifaRadii.xxl),
          border: Border.all(
            color: TaifaColors.gold500.withValues(alpha: 0.20),
          ),
          boxShadow: [
            BoxShadow(
              color: TaifaColors.emerald900.withValues(alpha: 0.5),
              blurRadius: 30,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Gold halo — top right.
            Positioned(
              top: -60,
              right: -40,
              child: _Halo(
                color: TaifaColors.gold500.withValues(alpha: 0.25),
                size: 200,
              ),
            ),
            // Ocean halo — bottom left.
            Positioned(
              bottom: -80,
              left: -20,
              child: _Halo(
                color: TaifaColors.ocean500.withValues(alpha: 0.20),
                size: 160,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(TaifaSpacing.xl),
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
                              'WALLET BALANCE',
                              style: TaifaTypography.eyebrow(
                                TaifaColors.white.withValues(alpha: 0.55),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              balance,
                              style: TaifaTypography.balance(TaifaColors.white),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              secondaryLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.6,
                                color: TaifaColors.gold400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const _EmvChip(),
                    ],
                  ),
                  const SizedBox(height: TaifaSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        maskedNumber,
                        style: TaifaTypography.mono(
                          TaifaColors.white.withValues(alpha: 0.6),
                        ),
                      ),
                      Text(
                        'TAIFA',
                        style: TaifaTypography.wordmark(TaifaColors.gold400),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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

class _EmvChip extends StatelessWidget {
  const _EmvChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 24,
      decoration: BoxDecoration(
        gradient: TaifaColors.goldGradient,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Container(
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: Colors.black.withValues(alpha: 0.4)),
        ),
      ),
    );
  }
}

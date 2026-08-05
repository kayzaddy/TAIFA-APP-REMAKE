import 'package:flutter/material.dart';

import '../../app/brand/taifa_brand_assets.dart';

/// Variants of the TAIFA mark for different surfaces.
enum TaifaLogoVariant {
  /// Gold T monogram in concentric rings (no wordmark).
  mark,

  /// Full lockup: mark + TAIFA wordmark.
  full,

  /// Squircle launcher icon.
  appIcon,
}

/// The official TAIFA logo, sized for the surface it's placed on.
class TaifaLogo extends StatelessWidget {
  const TaifaLogo({
    super.key,
    this.variant = TaifaLogoVariant.mark,
    this.size = 40,
    this.fit = BoxFit.contain,
  });

  final TaifaLogoVariant variant;
  final double size;
  final BoxFit fit;

  String get _asset => switch (variant) {
    TaifaLogoVariant.mark =>
      size <= 48 ? TaifaBrandAssets.markCompact : TaifaBrandAssets.mark,
    TaifaLogoVariant.full => TaifaBrandAssets.logoFull,
    TaifaLogoVariant.appIcon => TaifaBrandAssets.appIcon,
  };

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _asset,
      width: size,
      height: size,
      fit: fit,
      filterQuality: FilterQuality.high,
      semanticLabel: 'TAIFA',
    );
  }
}

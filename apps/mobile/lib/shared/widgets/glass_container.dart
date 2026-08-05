import 'dart:ui';

import 'package:flutter/material.dart';

import '../../app/theme/taifa_dimens.dart';
import '../../app/theme/taifa_theme.dart';

/// Frosted "glass" surface used across TAIFA (cards, nav, sheets).
///
/// Mirrors the mockup's `backdrop-filter: blur()` glass panels with a subtle
/// translucent fill and hairline border.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(TaifaSpacing.lg),
    this.borderRadius = TaifaRadii.xl,
    this.blur = 24,
    this.color,
    this.borderColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double blur;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final radius = BorderRadius.circular(borderRadius);

    Widget content = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color ?? palette.surface,
            borderRadius: radius,
            border: Border.all(color: borderColor ?? palette.border),
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(borderRadius: radius, onTap: onTap, child: content),
      );
    }
    return content;
  }
}

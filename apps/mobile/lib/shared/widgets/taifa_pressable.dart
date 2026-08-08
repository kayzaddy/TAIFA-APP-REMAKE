import 'package:flutter/material.dart';

import '../../app/theme/taifa_dimens.dart';

/// Press feedback for custom (non-Material) tappables.
///
/// Scales to 0.97 and dims slightly while held. The scale is a *paint-time*
/// transform, so surrounding content never reflows — the pro-rules call out
/// layout-shifting press states as a top cause of "cheap feeling" mobile UI.
///
/// Prefer `InkWell` where a ripple suits the surface; reach for this on
/// gradient buttons and tiles where a ripple would muddy the fill.
class TaifaPressable extends StatefulWidget {
  const TaifaPressable({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.scale = 0.97,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final double scale;

  @override
  State<TaifaPressable> createState() => _TaifaPressableState();
}

class _TaifaPressableState extends State<TaifaPressable> {
  bool _down = false;

  bool get _enabled => widget.onTap != null;

  void _setDown(bool value) {
    if (!_enabled || _down == value) return;
    setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    // Honour the OS "reduce motion" switch: keep the opacity cue, drop the scale.
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.semanticLabel,
      // When the caller names the control, that name is authoritative: a
      // screen reader should announce "Alerts, 3 new, button" as one node
      // rather than the parent label followed by the inner "Alerts" and "3"
      // fragments. Unnamed pressables keep their children's semantics.
      excludeSemantics: widget.semanticLabel != null,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => _setDown(true),
        onTapUp: (_) => _setDown(false),
        onTapCancel: () => _setDown(false),
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _down && !reduceMotion ? widget.scale : 1,
          duration: TaifaMotion.fast,
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: _enabled ? (_down ? 0.85 : 1) : 0.5,
            duration: TaifaMotion.fast,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

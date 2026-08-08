import 'package:flutter/material.dart';

import '../../app/theme/taifa_dimens.dart';

/// Fades and lifts a list item into place, offset by its index so a list
/// resolves as a quick cascade rather than snapping in all at once.
///
/// Deliberately capped: past [_maxStaggered] items the delay stops growing,
/// so a long list never makes the user wait on an animation queue.
///
/// Skipped entirely when the OS asks for reduced motion.
class TaifaStaggerIn extends StatelessWidget {
  const TaifaStaggerIn({
    super.key,
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  static const int _maxStaggered = 8;
  static const Duration _step = Duration(milliseconds: 40);

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return child;

    final delay = _step * (index.clamp(0, _maxStaggered));

    return TweenAnimationBuilder<double>(
      // The delay is folded into the curve via an Interval so this stays a
      // single throwaway animation with no timers to cancel.
      tween: Tween(begin: 0, end: 1),
      duration: TaifaMotion.base + delay,
      curve: Interval(
        delay.inMilliseconds / (TaifaMotion.base + delay).inMilliseconds,
        1,
        curve: TaifaMotion.standard,
      ),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 12 * (1 - t)), child: child),
      ),
      child: child,
    );
  }
}

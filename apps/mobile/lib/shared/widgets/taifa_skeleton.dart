import 'package:flutter/material.dart';

import '../../app/theme/taifa_dimens.dart';
import '../../app/theme/taifa_theme.dart';

/// Shimmering placeholder blocks shown while real content loads.
///
/// A skeleton that mirrors the shape of the incoming content reads as
/// "nearly there" where a bare spinner reads as "stuck", and it reserves the
/// layout so nothing jumps when data lands.
///
/// Hand-rolled (single [AnimationController] driving a gradient sweep) rather
/// than pulling in a shimmer package for ~40 lines. Falls back to a flat fill
/// when the OS asks for reduced motion.
class TaifaSkeleton extends StatefulWidget {
  const TaifaSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.radius = TaifaRadii.sm,
  });

  /// A full-width bar — the common case inside a column.
  const TaifaSkeleton.bar({
    Key? key,
    double height = 12,
    double radius = TaifaRadii.xs,
  }) : this(key: key, width: double.infinity, height: height, radius: radius);

  final double width;
  final double height;
  final double radius;

  @override
  State<TaifaSkeleton> createState() => _TaifaSkeletonState();
}

class _TaifaSkeletonState extends State<TaifaSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only burn a ticker when the shimmer is actually going to be painted —
    // a controller left repeating under reduced motion wastes frames forever
    // (and would hang any `pumpAndSettle` in tests).
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final base = palette.surfaceAlt;
    final highlight = palette.isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.04);
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    if (reduceMotion) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              // Sweep the highlight left→right across the block.
              begin: Alignment(-1 - 2 * (1 - t), 0),
              end: Alignment(1 - 2 * (1 - t) + 1, 0),
              colors: [base, highlight, base],
              stops: const [0.35, 0.5, 0.65],
            ),
          ),
        );
      },
    );
  }
}

/// A skeleton shaped like the app's standard list card (leading badge, two
/// text lines, trailing amount). Used by every social-payments list while it
/// waits on the API.
class TaifaSkeletonCard extends StatelessWidget {
  const TaifaSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return Container(
      padding: const EdgeInsets.all(TaifaSpacing.md),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(TaifaRadii.lg),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          const TaifaSkeleton(width: 40, height: 40, radius: TaifaRadii.md),
          const SizedBox(width: TaifaSpacing.sm),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TaifaSkeleton(width: 140, height: 12),
                SizedBox(height: TaifaSpacing.xs),
                TaifaSkeleton(width: 90, height: 10),
              ],
            ),
          ),
          const TaifaSkeleton(width: 56, height: 14),
        ],
      ),
    );
  }
}

/// Convenience: a column of [TaifaSkeletonCard]s for a loading list.
class TaifaSkeletonList extends StatelessWidget {
  const TaifaSkeletonList({super.key, this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      separatorBuilder: (_, _) => const SizedBox(height: TaifaSpacing.sm),
      itemBuilder: (_, _) => const TaifaSkeletonCard(),
    );
  }
}

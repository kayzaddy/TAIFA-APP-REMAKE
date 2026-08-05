import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../app/brand/taifa_brand_assets.dart';
import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../../../app/theme/taifa_typography.dart';

/// Animated brand splash shown once at cold start.
///
/// Sequence: ambient glow → mark scale/fade → wordmark rise → tagline →
/// soft hold → fade out → `/home`. Motions are intentional hierarchy, not noise.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _intro;
  late final AnimationController _pulse;
  late final AnimationController _exit;

  late final Animation<double> _markOpacity;
  late final Animation<double> _markScale;
  late final Animation<double> _wordOpacity;
  late final Animation<Offset> _wordSlide;
  late final Animation<double> _tagOpacity;
  late final Animation<double> _glow;
  late final Animation<double> _exitFade;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _exit = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );

    _markOpacity = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );
    _markScale = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(
        parent: _intro,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
      ),
    );
    _wordOpacity = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.35, 0.7, curve: Curves.easeOut),
    );
    _wordSlide = Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _intro,
            curve: const Interval(0.35, 0.75, curve: Curves.easeOutCubic),
          ),
        );
    _tagOpacity = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.55, 0.9, curve: Curves.easeOut),
    );
    _glow = Tween<double>(
      begin: 0.35,
      end: 0.85,
    ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
    _exitFade = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(CurvedAnimation(parent: _exit, curve: Curves.easeIn));

    _runSequence();
  }

  Future<void> _runSequence() async {
    await _intro.forward();
    if (!mounted) return;
    _pulse.repeat(reverse: true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    await _exit.forward();
    if (!mounted) return;
    context.go('/home');
  }

  @override
  void dispose() {
    _intro.dispose();
    _pulse.dispose();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: TaifaColors.black900,
        body: FadeTransition(
          opacity: _exitFade,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const _SplashBackdrop(),
              AnimatedBuilder(
                animation: Listenable.merge([_intro, _pulse]),
                builder: (context, _) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Soft gold aura behind the mark.
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 220,
                              height: 220,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: TaifaColors.gold500.withValues(
                                      alpha: 0.18 * _glow.value,
                                    ),
                                    blurRadius: 64,
                                    spreadRadius: 8,
                                  ),
                                  BoxShadow(
                                    color: TaifaColors.emerald600.withValues(
                                      alpha: 0.12 * _glow.value,
                                    ),
                                    blurRadius: 48,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            FadeTransition(
                              opacity: _markOpacity,
                              child: ScaleTransition(
                                scale: _markScale,
                                child: Image.asset(
                                  TaifaBrandAssets.mark,
                                  width: 168,
                                  height: 168,
                                  filterQuality: FilterQuality.high,
                                  semanticLabel: 'TAIFA',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: TaifaSpacing.xxl),
                        SlideTransition(
                          position: _wordSlide,
                          child: FadeTransition(
                            opacity: _wordOpacity,
                            child: Text(
                              'TAIFA',
                              style:
                                  TaifaTypography.display(
                                    TaifaColors.gold400,
                                  ).copyWith(
                                    fontSize: 42,
                                    letterSpacing: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(height: TaifaSpacing.md),
                        FadeTransition(
                          opacity: _tagOpacity,
                          child: Text(
                            'The Digital Operating System of Tanzania',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              letterSpacing: 0.4,
                              height: 1.4,
                              color: TaifaColors.gray300.withValues(
                                alpha: 0.85,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplashBackdrop extends StatelessWidget {
  const _SplashBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.15),
          radius: 1.15,
          colors: [Color(0xFF0E5A44), Color(0xFF062A20), Color(0xFF050505)],
          stops: [0.0, 0.45, 1.0],
        ),
      ),
      child: CustomPaint(painter: _RingPainter()),
    );
  }
}

/// Subtle concentric rings that echo the logo geometry.
class _RingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 24);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = TaifaColors.gold500.withValues(alpha: 0.08);
    for (final r in [120.0, 160.0, 210.0, 270.0]) {
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

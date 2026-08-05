import 'package:flutter/widgets.dart';

/// Spacing scale derived from the mockup's rhythm (gaps of 6/10/14/16/18/24px,
/// paddings of 12/14/18/20px, screen padding 20px). An 8pt-ish base with the
/// half steps the design actually uses.
class TaifaSpacing {
  const TaifaSpacing._();

  static const double xxs = 4;
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 16;
  static const double xl = 18;
  static const double xxl = 24;
  static const double xxxl = 32;

  /// Horizontal padding for a phone screen body (`.app` padding was 20px).
  static const double screenH = 20;
}

/// Corner radius scale. Mockup uses 10/12/14/16/20/24px radii and 100px pills.
class TaifaRadii {
  const TaifaRadii._();

  static const double xs = 8;
  static const double sm = 10;
  static const double md = 12;
  static const double lg = 14;
  static const double xl = 16;
  static const double xxl = 20;
  static const double nav = 24;
  static const double pill = 100;

  static const Radius pillRadius = Radius.circular(pill);
}

/// Common durations/curves so motion feels consistent and "premium".
class TaifaMotion {
  const TaifaMotion._();

  static const Duration fast = Duration(milliseconds: 180);
  static const Duration base = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 420);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeOutExpo;
}

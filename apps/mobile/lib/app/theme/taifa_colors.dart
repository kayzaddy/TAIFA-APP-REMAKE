import 'package:flutter/material.dart';

/// TAIFA canonical color system.
///
/// Source of truth: `TAIFA_Mockups.html` · Section P4 — Brand DNA / Design System.
/// Named palette: Sahara Emerald, Ceremonial Gold, Matte Basalt, Ocean Horizon,
/// Karatasi White. These tokens are theme-agnostic raw values; semantic mapping
/// lives in [TaifaTheme]. Never hardcode hex values in feature code — reference
/// these constants or the semantic [TaifaColorScheme] extension instead.
class TaifaColors {
  const TaifaColors._();

  // === Sahara Emerald (primary brand spine) ===
  static const Color emerald900 = Color(0xFF062A20); // Sahara Emerald
  static const Color emerald800 = Color(0xFF0A3D2E);
  static const Color emerald700 = Color(0xFF0E5A44); // Forest Mid
  static const Color emerald600 = Color(0xFF10B981);
  static const Color emerald500 = Color(0xFF34D399);

  // === Ceremonial Gold (accent · ceremony · value) ===
  static const Color gold500 = Color(0xFFD4AF37); // Ceremonial Gold
  static const Color gold400 = Color(0xFFE8C668);
  static const Color gold300 = Color(0xFFF4D03F);
  static const Color goldDeep = Color(0xFF8A6F1F);

  // === Matte Basalt (surfaces · depth) ===
  static const Color black900 = Color(0xFF050505);
  static const Color black800 = Color(0xFF0A0A0A); // Matte Basalt
  static const Color black700 = Color(0xFF141414);
  static const Color black600 = Color(0xFF1C1C1C);
  static const Color black500 = Color(0xFF2A2A2A);

  // === Karatasi White / neutrals ===
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF6F7F5); // Karatasi White
  static const Color gray100 = Color(0xFFF1F3F1);
  static const Color gray200 = Color(0xFFE3E6E3);
  static const Color gray300 = Color(0xFFC7CCC7);
  static const Color gray400 = Color(0xFF9AA19A);
  static const Color gray500 = Color(0xFF6B716B);
  static const Color gray600 = Color(0xFF4A4F4A);

  // === Ocean Horizon (secondary accent · info · maps) ===
  static const Color ocean500 = Color(0xFF0EA5E9); // Ocean Horizon
  static const Color ocean400 = Color(0xFF38BDF8);
  static const Color ocean300 = Color(0xFF7DD3FC);

  // === Functional / status ===
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerSoft = Color(0xFFF87171);
  static const Color success = emerald600;
  static const Color violet = Color(0xFFA855F7);
  static const Color violetSoft = Color(0xFFC084FC);

  // === Glow accents (used for shadows / halos) ===
  static const Color oceanGlow = Color(0x730EA5E9); // rgba(14,165,233,.45)
  static const Color emeraldGlow = Color(0x6610B981); // rgba(16,185,129,.4)
  static const Color goldGlow = Color(0x73D4AF37); // rgba(212,175,55,.45)

  // === Signature gradients ===
  static const LinearGradient walletCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [emerald700, emerald900, black800],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gold500, goldDeep],
  );

  static const LinearGradient wordmarkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [white, gold500, goldDeep],
    stops: [0.30, 0.75, 1.0],
  );

  static const LinearGradient heroBackgroundDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF040404), Color(0xFF0A1D15), emerald900],
    stops: [0.0, 0.6, 1.0],
  );
}

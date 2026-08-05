import 'package:flutter/material.dart';

import 'taifa_colors.dart';
import 'taifa_typography.dart';

/// Semantic color tokens that flip between dark and light. Widgets should read
/// these via `Theme.of(context).extension<TaifaPalette>()!` (or the
/// `context.taifa` extension) instead of touching raw [TaifaColors].
@immutable
class TaifaPalette extends ThemeExtension<TaifaPalette> {
  const TaifaPalette({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.surfaceGlass,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.brand,
    required this.accent,
    required this.info,
    required this.navBackground,
    required this.navBorder,
    required this.isDark,
  });

  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color surfaceGlass;
  final Color border;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color brand; // emerald
  final Color accent; // gold
  final Color info; // ocean
  final Color navBackground;
  final Color navBorder;
  final bool isDark;

  static const TaifaPalette dark = TaifaPalette(
    background: TaifaColors.black900,
    surface: Color(0x08FFFFFF), // rgba(255,255,255,0.03)
    surfaceAlt: Color(0x0DFFFFFF), // rgba(255,255,255,0.05)
    surfaceGlass: Color(0xC70A0A0A), // rgba(10,10,10,0.78)
    border: Color(0x0FFFFFFF), // rgba(255,255,255,0.06)
    borderStrong: Color(0x40D4AF37), // gold @ .25
    textPrimary: TaifaColors.white,
    textSecondary: TaifaColors.gray300,
    textMuted: TaifaColors.gray400,
    brand: TaifaColors.emerald500,
    accent: TaifaColors.gold400,
    info: TaifaColors.ocean400,
    navBackground: Color(0xC70A0A0A),
    navBorder: Color(0x14FFFFFF),
    isDark: true,
  );

  static const TaifaPalette light = TaifaPalette(
    background: TaifaColors.offWhite,
    surface: TaifaColors.white,
    surfaceAlt: TaifaColors.gray100,
    surfaceGlass: Color(0xD9FFFFFF), // rgba(255,255,255,0.85)
    border: Color(0x0F000000), // rgba(0,0,0,0.06)
    borderStrong: Color(0x33D4AF37),
    textPrimary: TaifaColors.black800,
    textSecondary: Color(0xFF444444),
    textMuted: Color(0xFF777777),
    brand: TaifaColors.emerald700,
    accent: TaifaColors.goldDeep,
    info: TaifaColors.ocean500,
    navBackground: Color(0xD9FFFFFF),
    navBorder: Color(0x0F000000),
    isDark: false,
  );

  @override
  TaifaPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? surfaceGlass,
    Color? border,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? brand,
    Color? accent,
    Color? info,
    Color? navBackground,
    Color? navBorder,
    bool? isDark,
  }) {
    return TaifaPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      surfaceGlass: surfaceGlass ?? this.surfaceGlass,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      brand: brand ?? this.brand,
      accent: accent ?? this.accent,
      info: info ?? this.info,
      navBackground: navBackground ?? this.navBackground,
      navBorder: navBorder ?? this.navBorder,
      isDark: isDark ?? this.isDark,
    );
  }

  @override
  TaifaPalette lerp(ThemeExtension<TaifaPalette>? other, double t) {
    if (other is! TaifaPalette) return this;
    return TaifaPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      surfaceGlass: Color.lerp(surfaceGlass, other.surfaceGlass, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      brand: Color.lerp(brand, other.brand, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      info: Color.lerp(info, other.info, t)!,
      navBackground: Color.lerp(navBackground, other.navBackground, t)!,
      navBorder: Color.lerp(navBorder, other.navBorder, t)!,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}

/// Convenience accessor: `context.taifa.accent`.
extension TaifaThemeX on BuildContext {
  TaifaPalette get taifa => Theme.of(this).extension<TaifaPalette>()!;
}

/// Assembles [ThemeData] for both brightness modes from TAIFA tokens.
class TaifaTheme {
  const TaifaTheme._();

  static ThemeData dark() => _build(TaifaPalette.dark, Brightness.dark);
  static ThemeData light() => _build(TaifaPalette.light, Brightness.light);

  static ThemeData _build(TaifaPalette p, Brightness brightness) {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: TaifaColors.emerald700,
          brightness: brightness,
        ).copyWith(
          primary: TaifaColors.emerald700,
          secondary: TaifaColors.gold500,
          tertiary: TaifaColors.ocean500,
          surface: p.surface,
          error: TaifaColors.danger,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: p.background,
      colorScheme: colorScheme,
      textTheme: TaifaTypography.textTheme(p.textPrimary, p.textMuted),
      splashFactory: InkSparkle.splashFactory,
      extensions: [p],
    );
  }
}

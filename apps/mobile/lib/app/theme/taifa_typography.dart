import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// TAIFA type system.
///
/// Source of truth: `TAIFA_Mockups.html` · Section P4 · 03 Typography.
/// - Playfair Display (400/700/900) → display / ceremony / balances.
/// - Inter (300..800) → body, UI, dense reading (Swahili + English).
/// - JetBrains Mono → numeric / card numbers / code.
class TaifaTypography {
  const TaifaTypography._();

  static TextStyle display(Color color) => GoogleFonts.playfairDisplay(
    fontSize: 60,
    fontWeight: FontWeight.w900,
    height: 0.95,
    letterSpacing: -1.2,
    color: color,
  );

  static TextStyle sectionTitle(Color color) => GoogleFonts.playfairDisplay(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    height: 1.0,
    letterSpacing: -0.4,
    color: color,
  );

  /// Wallet balance — serif, tight, premium.
  static TextStyle balance(Color color) => GoogleFonts.playfairDisplay(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
    color: color,
  );

  static TextStyle wordmark(Color color) => GoogleFonts.playfairDisplay(
    fontSize: 22,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.0,
    color: color,
  );

  /// Builds the Inter-based [TextTheme] for body/UI, tinted for a base color.
  static TextTheme textTheme(Color onSurface, Color muted) {
    return TextTheme(
      headlineSmall: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: onSurface,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.55,
        color: muted,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: muted,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: muted,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 9,
        fontWeight: FontWeight.w500,
        color: muted,
      ),
    );
  }

  static TextStyle mono(Color color, {double size = 10}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.2,
        color: color,
      );

  /// Uppercase eyebrow / section label styling.
  static TextStyle eyebrow(Color color) => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 3.5,
    color: color,
  );
}

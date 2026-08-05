/// Canonical brand asset paths. Prefer these constants over raw strings so a
/// rename of the logo files is a one-line change.
class TaifaBrandAssets {
  const TaifaBrandAssets._();

  /// Full logo (mark + wordmark) — splash, about, marketing surfaces.
  static const logoFull = 'assets/brand/taifa_logo_full.png';

  /// Icon mark alone (the gold T in rings) — headers, avatars, compact chrome.
  static const mark = 'assets/brand/taifa_mark.png';

  /// Smaller mark for dense UI (bottom chrome, list tiles).
  static const markCompact = 'assets/brand/taifa_mark_128.png';

  /// Squircle app icon — launcher / about.
  static const appIcon = 'assets/brand/taifa_app_icon.png';

  /// Vector source of truth (kept for export; prefer PNG at runtime).
  static const logoSvg = 'assets/brand/taifa_logo.svg';
}

# TAIFA Design System

**Source of truth:** `TAIFA_Mockups.html` → *P4 — Brand DNA / Design System*.
All values below are extracted verbatim and encoded in `apps/mobile/lib/app/theme/`.

> **Golden rule:** feature code never hardcodes hex, font, spacing or radius
> values. Reference the tokens (`TaifaColors`, `TaifaSpacing`, `TaifaRadii`,
> `TaifaTypography`) or the semantic palette via `context.taifa`.

---

## 1. Brand narrative

Sahara emerald, ceremonial gold, matte basalt, ocean horizon and the typography
of literature — a *nation's* brand, built for billboards in Dar, global app
stores and policy papers alike.

## 2. Color palette (`taifa_colors.dart`)

| Token | Hex | Role |
|-------|-----|------|
| Sahara Emerald | `#062A20` | Primary brand spine, deep surfaces |
| Forest Mid | `#0E5A44` | Brand mid, gradients |
| Ceremonial Gold | `#D4AF37` | Accent, value, ceremony |
| Matte Basalt | `#0A0A0A` | Dark surfaces / depth |
| Ocean Horizon | `#0EA5E9` | Secondary accent, info, maps |
| Karatasi White | `#F6F7F5` | Light background |

Support ramps (`emerald500`, `gold300`, `gray400`…), functional colors
(`danger`, `violet`), and glow tokens (`goldGlow`, `emeraldGlow`, `oceanGlow`)
for halos/shadows. Signature gradients: `walletCardGradient`, `goldGradient`,
`wordmarkGradient`, `heroBackgroundDark`.

### Semantic palette (`TaifaPalette` — `taifa_theme.dart`)

A `ThemeExtension` mapping raw colors to intent (`background`, `surface`,
`border`, `textPrimary/Secondary/Muted`, `brand`, `accent`, `info`,
`navBackground`…). Provides `.dark` and `.light` variants that lerp smoothly on
theme switch. Access with `context.taifa`.

## 3. Typography (`taifa_typography.dart`)

- **Playfair Display** (400 / 700 / 900) — display, section titles, wallet
  balance, wordmark. *For ceremony.*
- **Inter** (300–800) — body & UI, dense reading, Swahili + English.
- **JetBrains Mono** — numeric (card numbers, codes).

Loaded via `google_fonts`. Helpers: `display`, `sectionTitle`, `balance`,
`wordmark`, `eyebrow`, `mono`, and a full Inter `textTheme(onSurface, muted)`.

## 4. Spacing, radius, motion (`taifa_dimens.dart`)

- **Spacing** `xxs 4 · xs 6 · sm 10 · md 14 · lg 16 · xl 18 · xxl 24 · xxxl 32`;
  screen horizontal padding `20`.
- **Radii** `xs 8 · sm 10 · md 12 · lg 14 · xl 16 · xxl 20 · nav 24 · pill 100`.
- **Motion** `fast 180ms · base 260ms · slow 420ms`; curves `easeOutCubic`,
  `easeOutExpo`.

## 5. Component library (`apps/mobile/lib/shared/widgets/`)

| Component | Mockup source | Notes |
|-----------|---------------|-------|
| `GlassContainer` | glass panels (`backdrop-filter`) | frosted surface primitive |
| `WalletCard` | `.wallet-card` | gradient, gold + ocean halos, EMV chip, masked PAN, wordmark |
| `QuickActionButton` | `.qa` | Send / Scan QR / Top Up / Bills |
| `ServiceTile` | `.svc` | tinted rounded-square launcher |
| `PromoCard` | `.card-promo` | merchandising offer + pill |
| `TaifaPill` | `.pill` | gold / green / blue tones |
| `TaifaBottomNav` | `.bottom-nav` | floating glass nav, gold active state |
| `ModulePreviewScreen` | — | honest branded status surface for roadmap modules |

### Iconography

The mockup uses decorative Unicode glyphs for concepting. In the native app we
map them to **Material rounded icons** (crisper, accessible, consistent) while
preserving the color language — an intentional "expand where necessary while
preserving the design language" decision.

## 6. Theming

Both `ThemeData` variants are built in `TaifaTheme` from the same tokens.
`themeModeProvider` (Riverpod) drives `MaterialApp.themeMode`; the Home header
exposes a live toggle. Default is **Dark · Default** per the spec.

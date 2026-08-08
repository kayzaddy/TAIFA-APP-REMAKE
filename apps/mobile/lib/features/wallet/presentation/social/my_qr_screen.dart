import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../app/theme/taifa_colors.dart';
import '../../../../app/theme/taifa_dimens.dart';
import '../../../../app/theme/taifa_icons.dart';
import '../../../../app/theme/taifa_theme.dart';
import '../../../../shared/widgets/taifa_skeleton.dart';
import '../../application/social_providers.dart';
import 'social_widgets.dart';

/// My standing receive-QR: a real, scannable code for the owner's open-amount
/// payment link. Any TAIFA wallet can scan it and choose an amount to send.
class MyQrScreen extends ConsumerWidget {
  const MyQrScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.taifa;
    final asyncLink = ref.watch(myQrLinkProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: TaifaSpacing.screenH),
          child: Column(
            children: [
              const SizedBox(height: TaifaSpacing.sm),
              const SocialScreenHeader(title: 'My QR'),
              const SizedBox(height: TaifaSpacing.xxl),
              Expanded(
                child: asyncLink.when(
                  loading: () => const Center(
                    child: TaifaSkeleton(
                      width: 264,
                      height: 300,
                      radius: TaifaRadii.nav,
                    ),
                  ),
                  error: (e, _) => SocialEmptyState(
                    icon: TaifaIcons.error,
                    title: 'Could not load your QR',
                    message: '$e',
                    actionLabel: 'Try again',
                    onAction: () => ref.invalidate(myQrLinkProvider),
                  ),
                  data: (link) => _QrCard(slug: link.slug, palette: palette),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QrCard extends StatelessWidget {
  const _QrCard({required this.slug, required this.palette});

  final String slug;
  final TaifaPalette palette;

  /// What a scanning wallet resolves — matches the backend's `qr_payload`.
  String get _payload => 'taifa://pay/$slug';
  String get _shareUrl => 'taifa.app/pay/$slug';

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Scale-in on first paint so the code "arrives" instead of
            // blinking in. TweenAnimationBuilder means no controller to own.
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.94, end: 1),
              duration: TaifaMotion.base,
              curve: TaifaMotion.emphasized,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Container(
                padding: const EdgeInsets.all(TaifaSpacing.xl),
                decoration: BoxDecoration(
                  gradient: TaifaColors.walletCardGradient,
                  borderRadius: BorderRadius.circular(TaifaRadii.nav),
                  border: Border.all(
                    color: TaifaColors.gold500.withValues(alpha: 0.35),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: TaifaColors.gold500.withValues(alpha: 0.20),
                      blurRadius: 40,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Scanners need a light quiet zone, so this plate stays
                    // white in both themes rather than following the palette.
                    Container(
                      padding: const EdgeInsets.all(TaifaSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(TaifaRadii.xl),
                      ),
                      child: QrImageView(
                        data: _payload,
                        version: QrVersions.auto,
                        size: 196,
                        gapless: true,
                        backgroundColor: Colors.white,
                        // High correction so the embedded brand mark can never
                        // render the code unscannable.
                        errorCorrectionLevel: QrErrorCorrectLevel.H,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.circle,
                          color: TaifaColors.emerald900,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.circle,
                          color: TaifaColors.emerald900,
                        ),
                        embeddedImage: const AssetImage(
                          'assets/brand/taifa_mark_128.png',
                        ),
                        embeddedImageStyle: const QrEmbeddedImageStyle(
                          size: Size(38, 38),
                        ),
                      ),
                    ),
                    const SizedBox(height: TaifaSpacing.lg),
                    const Text(
                      'Scan to pay me',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _shareUrl,
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 0.4,
                        color: TaifaColors.gold400.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: TaifaSpacing.xl),
            Text(
              'Anyone with a TAIFA wallet can scan this\nand choose how much to send you.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                height: 1.5,
                color: palette.textMuted,
              ),
            ),
            const SizedBox(height: TaifaSpacing.md),
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _shareUrl));
                showSocialSuccess(context, 'Link copied.');
              },
              icon: Icon(
                TaifaIcons.copy,
                size: TaifaIconSize.sm,
                color: palette.accent,
              ),
              label: Text('Copy link', style: TextStyle(color: palette.accent)),
            ),
          ],
        ),
      ),
    );
  }
}

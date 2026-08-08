import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/taifa_colors.dart';
import '../../../../app/theme/taifa_dimens.dart';
import '../../../../app/theme/taifa_theme.dart';
import '../../application/social_providers.dart';
import 'social_widgets.dart';

/// My standing receive-QR. No `qr_flutter` dependency added for this pass —
/// the payload is rendered as a copyable code/link; swap in a real QR image
/// widget here later without touching the data layer.
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
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Could not load your QR.\n$e', textAlign: TextAlign.center)),
                  data: (link) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 220,
                          height: 220,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: palette.surface,
                            borderRadius: BorderRadius.circular(TaifaRadii.xxl),
                            border: Border.all(color: palette.border, width: 2),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.qr_code_2_rounded, size: 96),
                              const SizedBox(height: TaifaSpacing.sm),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: TaifaSpacing.sm),
                                child: Text(
                                  'taifa://pay/${link.slug}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 9, color: palette.textMuted, fontFamily: 'monospace'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: TaifaSpacing.xl),
                        Text('Scan to pay me', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.textPrimary)),
                        const SizedBox(height: TaifaSpacing.xs),
                        Text('Anyone can pay any amount to this code.', style: TextStyle(fontSize: 11, color: palette.textMuted)),
                        const SizedBox(height: TaifaSpacing.lg),
                        TextButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: 'taifa.app/pay/${link.slug}'));
                            showSocialSuccess(context, 'Link copied.');
                          },
                          icon: const Icon(Icons.copy_rounded, size: 16, color: TaifaColors.gold500),
                          label: Text('Copy link', style: TextStyle(color: palette.accent)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

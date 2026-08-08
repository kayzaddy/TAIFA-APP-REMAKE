import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../../../app/theme/taifa_theme.dart';
import '../../../app/theme/taifa_typography.dart';
import '../../../shared/widgets/taifa_logo.dart';
import '../application/nfc_providers.dart';
import '../domain/nfc_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// NFC Tap-to-Translate — Demo Complete mock (no hardware).
class NfcScreen extends ConsumerWidget {
  const NfcScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(nfcControllerProvider);
    final ctrl = ref.read(nfcControllerProvider.notifier);
    final palette = context.taifa;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (state.phase == NfcPhase.home) {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/home');
                        }
                      } else {
                        ctrl.backHome();
                      }
                    },
                    icon: Icon(
                      LucideIcons.arrowLeft,
                      color: palette.textPrimary,
                    ),
                  ),
                  const TaifaLogo(variant: TaifaLogoVariant.mark, size: 32),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tap to Translate',
                      style: TaifaTypography.sectionTitle(
                        palette.textPrimary,
                      ).copyWith(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: TaifaMotion.base,
                child: switch (state.phase) {
                  NfcPhase.home => _Home(
                    key: const ValueKey('h'),
                    state: state,
                    ctrl: ctrl,
                  ),
                  NfcPhase.scanning => const _Scanning(key: ValueKey('s')),
                  NfcPhase.result => _Result(
                    key: const ValueKey('r'),
                    pack: state.selected,
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Home extends StatelessWidget {
  const _Home({super.key, required this.state, required this.ctrl});
  final NfcUiState state;
  final NfcController ctrl;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          'Hold your phone near a TAIFA tag',
          style: TaifaTypography.sectionTitle(
            palette.textPrimary,
          ).copyWith(fontSize: 22),
        ),
        const SizedBox(height: 8),
        Text(
          'Demo Mode simulates NFC packs for markets, travel and clinics. Real NFC arrives after Demo Complete.',
          style: TextStyle(color: palette.textMuted, height: 1.4),
        ),
        const SizedBox(height: 20),
        ...state.packs.map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: palette.surface,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () => ctrl.simulateTap(p),
                borderRadius: BorderRadius.circular(16),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: TaifaColors.ocean400.withValues(
                      alpha: 0.2,
                    ),
                    child: const Icon(
                      LucideIcons.wifi,
                      color: TaifaColors.ocean400,
                    ),
                  ),
                  title: Text(
                    p.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: palette.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    p.subtitle,
                    style: TextStyle(color: palette.textMuted),
                  ),
                  trailing: Icon(
                    LucideIcons.wifi,
                    color: palette.textMuted,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Scanning extends StatelessWidget {
  const _Scanning({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(color: TaifaColors.emerald500),
          ),
          const SizedBox(height: 16),
          Text(
            'Reading tag…',
            style: TextStyle(
              color: palette.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({super.key, required this.pack});
  final NfcPack? pack;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    if (pack == null) return const SizedBox.shrink();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          pack!.title,
          style: TaifaTypography.sectionTitle(
            palette.textPrimary,
          ).copyWith(fontSize: 22),
        ),
        Text(
          'Translation pack unlocked',
          style: TextStyle(color: palette.textMuted),
        ),
        const SizedBox(height: 16),
        ...pack!.phrases.map(
          (p) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${p.sourceLang} · ${p.source}',
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${p.targetLang} · ${p.target}',
                  style: TextStyle(color: palette.textMuted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

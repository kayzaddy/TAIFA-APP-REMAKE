import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../../../app/theme/taifa_theme.dart';
import '../../../app/theme/taifa_typography.dart';
import '../../../shared/widgets/taifa_logo.dart';
import '../application/wealth_providers.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class WealthScreen extends ConsumerStatefulWidget {
  const WealthScreen({super.key});

  @override
  ConsumerState<WealthScreen> createState() => _WealthScreenState();
}

class _WealthScreenState extends ConsumerState<WealthScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(wealthControllerProvider.notifier).bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wealthControllerProvider);
    final ctrl = ref.read(wealthControllerProvider.notifier);
    final palette = context.taifa;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      switch (state.phase) {
                        case WealthPhase.home:
                          context.canPop()
                              ? context.pop()
                              : context.go('/home');
                        case WealthPhase.detail:
                          ctrl.backHome();
                        case WealthPhase.confirm:
                          if (state.selected != null) {
                            ctrl.open(state.selected!);
                          }
                        case WealthPhase.history:
                          ctrl.backHome();
                        default:
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
                      switch (state.phase) {
                        WealthPhase.home => 'TAIFA Wealth',
                        WealthPhase.detail =>
                          state.selected?.name ?? 'Harambee',
                        WealthPhase.confirm => 'Contribute',
                        WealthPhase.receipt => 'Receipt',
                        WealthPhase.history => 'Contributions',
                      },
                      style: TaifaTypography.sectionTitle(
                        palette.textPrimary,
                      ).copyWith(fontSize: 18),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: ctrl.openHistory,
                    icon: Icon(
                      LucideIcons.receipt,
                      color: palette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: TaifaMotion.base,
                child: switch (state.phase) {
                  WealthPhase.home => ListView(
                    key: const ValueKey('h'),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      Text(
                        'Harambee & Vault',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...state.circles.map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Material(
                            color: palette.surface,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              onTap: () => ctrl.open(c),
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: palette.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      c.purpose,
                                      style: TextStyle(
                                        color: palette.textMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    LinearProgressIndicator(
                                      value: c.progress.clamp(0, 1),
                                      color: TaifaColors.emerald500,
                                      backgroundColor: palette.border,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${c.raised.format()} / ${c.target.format()} · ${c.members} members',
                                      style: TextStyle(
                                        color: palette.textMuted,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  WealthPhase.detail => ListView(
                    key: const ValueKey('d'),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      if (state.selected != null) ...[
                        Text(
                          state.selected!.name,
                          style: TaifaTypography.sectionTitle(
                            palette.textPrimary,
                          ).copyWith(fontSize: 22),
                        ),
                        Text(
                          state.selected!.purpose,
                          style: TextStyle(color: palette.textMuted),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${state.selected!.raised.format()} raised',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: palette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: ctrl.goConfirm,
                          style: FilledButton.styleFrom(
                            backgroundColor: TaifaColors.emerald700,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: const Text('Contribute'),
                        ),
                      ],
                    ],
                  ),
                  WealthPhase.confirm => ListView(
                    key: const ValueKey('c'),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      Text(
                        'Amount',
                        style: TextStyle(color: palette.textMuted),
                      ),
                      Text(
                        state.amount.format(),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: palette.textPrimary,
                          fontSize: 24,
                        ),
                      ),
                      Slider(
                        value: state.amountMajor.toDouble(),
                        min: 5000,
                        max: 200000,
                        divisions: 39,
                        activeColor: TaifaColors.emerald500,
                        onChanged: (v) => ctrl.setAmount(v.round()),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: state.isBusy ? null : ctrl.contribute,
                        style: FilledButton.styleFrom(
                          backgroundColor: TaifaColors.emerald700,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: Text(
                          state.isBusy
                              ? 'Paying…'
                              : 'Pay with wallet · ${state.amount.format()}',
                        ),
                      ),
                    ],
                  ),
                  WealthPhase.receipt => ListView(
                    key: const ValueKey('r'),
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        'Contribution sent',
                        style: TaifaTypography.sectionTitle(
                          palette.textPrimary,
                        ).copyWith(fontSize: 22),
                      ),
                      Text(
                        '${state.contribution?.circle.name}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: palette.textPrimary,
                        ),
                      ),
                      Text(
                        '${state.contribution?.amount.format()} · ${state.contribution?.paymentRef}',
                        style: TextStyle(color: palette.textMuted),
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton(
                        onPressed: () => context.go('/home'),
                        child: const Text('Back to Home'),
                      ),
                    ],
                  ),
                  WealthPhase.history =>
                    state.history.isEmpty
                        ? Center(
                            child: Text(
                              'No contributions yet.',
                              style: TextStyle(color: palette.textMuted),
                            ),
                          )
                        : ListView.separated(
                            key: const ValueKey('hist'),
                            padding: const EdgeInsets.all(16),
                            itemCount: state.history.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final c = state.history[i];
                              return Material(
                                color: palette.surface,
                                borderRadius: BorderRadius.circular(14),
                                child: ListTile(
                                  title: Text(
                                    c.circle.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: palette.textPrimary,
                                    ),
                                  ),
                                  trailing: Text(
                                    c.amount.format(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: palette.textPrimary,
                                    ),
                                  ),
                                ),
                              );
                            },
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

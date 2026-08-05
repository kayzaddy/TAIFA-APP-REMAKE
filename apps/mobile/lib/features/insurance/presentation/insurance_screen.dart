import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../../../app/theme/taifa_theme.dart';
import '../../../app/theme/taifa_typography.dart';
import '../../../shared/widgets/taifa_logo.dart';
import '../application/insurance_providers.dart';
import '../domain/insurance_models.dart';

class InsuranceScreen extends ConsumerStatefulWidget {
  const InsuranceScreen({super.key});

  @override
  ConsumerState<InsuranceScreen> createState() => _InsuranceScreenState();
}

class _InsuranceScreenState extends ConsumerState<InsuranceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(insuranceControllerProvider.notifier).bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(insuranceControllerProvider);
    final ctrl = ref.read(insuranceControllerProvider.notifier);
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
                        case InsurancePhase.home:
                          context.canPop()
                              ? context.pop()
                              : context.go('/home');
                        case InsurancePhase.detail:
                          ctrl.backHome();
                        case InsurancePhase.confirm:
                          if (state.selected != null) {
                            ctrl.open(state.selected!);
                          }
                        case InsurancePhase.history:
                          ctrl.backHome();
                        default:
                          ctrl.backHome();
                      }
                    },
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: palette.textPrimary,
                    ),
                  ),
                  const TaifaLogo(variant: TaifaLogoVariant.mark, size: 32),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      switch (state.phase) {
                        InsurancePhase.home => 'TAIFA Insurance',
                        InsurancePhase.detail => state.selected?.name ?? 'Plan',
                        InsurancePhase.confirm => 'Pay premium',
                        InsurancePhase.receipt => 'Policy active',
                        InsurancePhase.history => 'My policies',
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
                      Icons.receipt_long_rounded,
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
                  InsurancePhase.home => ListView(
                    key: const ValueKey('ins-h'),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      Text(
                        'Cover for life in Tanzania',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Health · motor · travel · life — demo plans',
                        style: TextStyle(
                          color: palette.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...state.plans.map(
                        (p) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Material(
                            color: palette.surface,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              onTap: () => ctrl.open(p),
                              borderRadius: BorderRadius.circular(16),
                              child: ListTile(
                                title: Text(
                                  p.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: palette.textPrimary,
                                  ),
                                ),
                                subtitle: Text(
                                  '${p.category} · ${p.provider}\nPremium ${p.premium.format()}/mo',
                                  style: TextStyle(
                                    color: palette.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                                isThreeLine: true,
                                trailing: Text(
                                  p.coverage.format(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: TaifaColors.emerald500,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  InsurancePhase.detail => ListView(
                    key: const ValueKey('ins-d'),
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
                          '${state.selected!.provider} · ${state.selected!.category}',
                          style: TextStyle(color: palette.textMuted),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Coverage ${state.selected!.coverage.format()}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: palette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...state.selected!.highlights.map(
                          (h) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 18,
                                  color: TaifaColors.emerald500,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    h,
                                    style: TextStyle(
                                      color: palette.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: ctrl.goConfirm,
                          style: FilledButton.styleFrom(
                            backgroundColor: TaifaColors.emerald700,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: Text(
                            'Continue · ${state.selected!.premium.format()}',
                          ),
                        ),
                      ],
                    ],
                  ),
                  InsurancePhase.confirm => ListView(
                    key: const ValueKey('ins-c'),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      Text(
                        state.selected?.name ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: palette.textPrimary,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'First month premium',
                        style: TextStyle(color: palette.textMuted),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.selected?.premium.format() ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: palette.textPrimary,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: state.isBusy ? null : ctrl.buy,
                        style: FilledButton.styleFrom(
                          backgroundColor: TaifaColors.emerald700,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: Text(
                          state.isBusy ? 'Activating…' : 'Pay with wallet',
                        ),
                      ),
                    ],
                  ),
                  InsurancePhase.receipt => ListView(
                    key: const ValueKey('ins-r'),
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        'Policy activated',
                        style: TaifaTypography.sectionTitle(
                          palette.textPrimary,
                        ).copyWith(fontSize: 22),
                      ),
                      Text(
                        state.policy?.plan.name ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: palette.textPrimary,
                        ),
                      ),
                      Text(
                        '${state.policy?.policyRef} · ${state.policy?.plan.premium.format()}',
                        style: TextStyle(color: palette.textMuted),
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton(
                        onPressed: () => context.go('/home'),
                        child: const Text('Back to Home'),
                      ),
                    ],
                  ),
                  InsurancePhase.history =>
                    state.history.isEmpty
                        ? Center(
                            child: Text(
                              'No policies yet.',
                              style: TextStyle(color: palette.textMuted),
                            ),
                          )
                        : ListView.separated(
                            key: const ValueKey('ins-hist'),
                            padding: const EdgeInsets.all(16),
                            itemCount: state.history.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final p = state.history[i];
                              return Material(
                                color: palette.surface,
                                borderRadius: BorderRadius.circular(14),
                                child: ListTile(
                                  title: Text(
                                    p.plan.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: palette.textPrimary,
                                    ),
                                  ),
                                  subtitle: Text(
                                    p.policyRef ?? '',
                                    style: TextStyle(color: palette.textMuted),
                                  ),
                                  trailing: Text(
                                    p.status.label,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: TaifaColors.emerald500,
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../../../app/theme/taifa_theme.dart';
import '../../../app/theme/taifa_typography.dart';
import '../../../shared/widgets/taifa_logo.dart';
import '../application/huduma_providers.dart';
import '../data/huduma_catalog.dart';

class HudumaScreen extends ConsumerStatefulWidget {
  const HudumaScreen({super.key});

  @override
  ConsumerState<HudumaScreen> createState() => _HudumaScreenState();
}

class _HudumaScreenState extends ConsumerState<HudumaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(hudumaControllerProvider.notifier).bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hudumaControllerProvider);
    final ctrl = ref.read(hudumaControllerProvider.notifier);
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
                        case HudumaPhase.home:
                          context.canPop()
                              ? context.pop()
                              : context.go('/home');
                        case HudumaPhase.detail:
                          ctrl.backHome();
                        case HudumaPhase.confirm:
                          if (state.selected != null) {
                            ctrl.open(state.selected!);
                          }
                        case HudumaPhase.history:
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
                        HudumaPhase.home => 'Huduma',
                        HudumaPhase.detail =>
                          state.selected?.title ?? 'Service',
                        HudumaPhase.confirm => 'Book & pay',
                        HudumaPhase.receipt => 'Booked',
                        HudumaPhase.history => 'Bookings',
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
                  HudumaPhase.home => ListView(
                    key: const ValueKey('hd-h'),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      Text(
                        'Home services',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Plumbing · cleaning · AC · laundry',
                        style: TextStyle(
                          color: palette.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...state.services.map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Material(
                            color: palette.surface,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              onTap: () => ctrl.open(s),
                              borderRadius: BorderRadius.circular(16),
                              child: ListTile(
                                title: Text(
                                  s.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: palette.textPrimary,
                                  ),
                                ),
                                subtitle: Text(
                                  '${s.category} · ${s.provider}\n${s.etaLabel} · ★ ${s.rating}',
                                  style: TextStyle(
                                    color: palette.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                                isThreeLine: true,
                                trailing: Text(
                                  s.price.format(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: palette.textPrimary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  HudumaPhase.detail => ListView(
                    key: const ValueKey('hd-d'),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      if (state.selected != null) ...[
                        Text(
                          state.selected!.title,
                          style: TaifaTypography.sectionTitle(
                            palette.textPrimary,
                          ).copyWith(fontSize: 22),
                        ),
                        Text(
                          state.selected!.provider,
                          style: TextStyle(color: palette.textMuted),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          state.selected!.price.format(),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: palette.textPrimary,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: ctrl.goConfirm,
                          style: FilledButton.styleFrom(
                            backgroundColor: TaifaColors.emerald700,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: const Text('Choose slot'),
                        ),
                      ],
                    ],
                  ),
                  HudumaPhase.confirm => ListView(
                    key: const ValueKey('hd-c'),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      Text(
                        'When should we come?',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...HudumaCatalog.slots.map(
                        (slot) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: state.slotLabel == slot
                                ? TaifaColors.emerald500.withValues(alpha: 0.15)
                                : palette.surface,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              onTap: () => ctrl.setSlot(slot),
                              borderRadius: BorderRadius.circular(14),
                              child: ListTile(
                                title: Text(
                                  slot,
                                  style: TextStyle(color: palette.textPrimary),
                                ),
                                trailing: state.slotLabel == slot
                                    ? Icon(
                                        Icons.check_circle_rounded,
                                        color: TaifaColors.emerald500,
                                      )
                                    : Icon(
                                        Icons.circle_outlined,
                                        color: palette.textMuted,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: state.isBusy ? null : ctrl.book,
                        style: FilledButton.styleFrom(
                          backgroundColor: TaifaColors.emerald700,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: Text(
                          state.isBusy
                              ? 'Booking…'
                              : 'Pay with wallet · ${state.selected?.price.format() ?? ''}',
                        ),
                      ),
                    ],
                  ),
                  HudumaPhase.receipt => ListView(
                    key: const ValueKey('hd-r'),
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        'Service booked',
                        style: TaifaTypography.sectionTitle(
                          palette.textPrimary,
                        ).copyWith(fontSize: 22),
                      ),
                      Text(
                        state.booking?.service.title ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: palette.textPrimary,
                        ),
                      ),
                      Text(
                        '${state.booking?.slotLabel} · ${state.booking?.paymentRef}',
                        style: TextStyle(color: palette.textMuted),
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton(
                        onPressed: () => context.go('/home'),
                        child: const Text('Back to Home'),
                      ),
                    ],
                  ),
                  HudumaPhase.history =>
                    state.history.isEmpty
                        ? Center(
                            child: Text(
                              'No bookings yet.',
                              style: TextStyle(color: palette.textMuted),
                            ),
                          )
                        : ListView.separated(
                            key: const ValueKey('hd-hist'),
                            padding: const EdgeInsets.all(16),
                            itemCount: state.history.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final b = state.history[i];
                              return Material(
                                color: palette.surface,
                                borderRadius: BorderRadius.circular(14),
                                child: ListTile(
                                  title: Text(
                                    b.service.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: palette.textPrimary,
                                    ),
                                  ),
                                  subtitle: Text(
                                    b.slotLabel,
                                    style: TextStyle(color: palette.textMuted),
                                  ),
                                  trailing: Text(
                                    b.service.price.format(),
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

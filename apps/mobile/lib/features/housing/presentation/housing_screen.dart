import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../../../app/theme/taifa_theme.dart';
import '../../../app/theme/taifa_typography.dart';
import '../../../shared/widgets/taifa_logo.dart';
import '../application/housing_providers.dart';
import '../domain/housing_models.dart';

class HousingScreen extends ConsumerStatefulWidget {
  const HousingScreen({super.key});

  @override
  ConsumerState<HousingScreen> createState() => _HousingScreenState();
}

class _HousingScreenState extends ConsumerState<HousingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(housingControllerProvider.notifier).bootstrap();
    });
  }

  String _fmt(DateTime? d) {
    if (d == null) return '—';
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${m[d.month - 1]} · ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(housingControllerProvider);
    final ctrl = ref.read(housingControllerProvider.notifier);
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
                        case HousingPhase.home:
                          context.canPop()
                              ? context.pop()
                              : context.go('/home');
                        case HousingPhase.detail:
                          ctrl.backHome();
                        case HousingPhase.history:
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
                        HousingPhase.home => 'Housing',
                        HousingPhase.detail =>
                          state.selected?.title ?? 'Listing',
                        HousingPhase.scheduled => 'Viewing',
                        HousingPhase.receipt => 'Receipt',
                        HousingPhase.history => 'Inquiries',
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
                    icon: Icon(Icons.history_rounded, color: palette.textMuted),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: TaifaMotion.base,
                child: switch (state.phase) {
                  HousingPhase.home => ListView(
                    key: const ValueKey('h'),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      TextField(
                        onChanged: ctrl.search,
                        decoration: InputDecoration(
                          hintText: 'Search Mikocheni, Masaki…',
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: palette.textMuted,
                          ),
                          filled: true,
                          fillColor: palette.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      ...state.listings.map(
                        (l) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Material(
                            color: palette.surface,
                            borderRadius: BorderRadius.circular(16),
                            child: ListTile(
                              onTap: () => ctrl.open(l),
                              title: Text(
                                l.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: palette.textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                '${l.area} · ${l.beds}bd · ${l.monthlyRent.format()}/mo',
                                style: TextStyle(
                                  color: palette.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  HousingPhase.detail => ListView(
                    key: const ValueKey('d'),
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
                          '${state.selected!.area} · ${state.selected!.tagline}',
                          style: TextStyle(color: palette.textMuted),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Rent ${state.selected!.monthlyRent.format()} · Deposit ${state.selected!.deposit.format()}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: palette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: state.isBusy ? null : ctrl.requestViewing,
                          style: FilledButton.styleFrom(
                            backgroundColor: TaifaColors.emerald700,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: Text(
                            state.isBusy ? 'Scheduling…' : 'Request viewing',
                          ),
                        ),
                      ],
                    ],
                  ),
                  HousingPhase.scheduled => Padding(
                    key: const ValueKey('s'),
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.event_available_rounded,
                          color: TaifaColors.emerald500,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          state.inquiry?.status.label ?? 'Scheduled',
                          style: TaifaTypography.sectionTitle(
                            palette.textPrimary,
                          ).copyWith(fontSize: 22),
                        ),
                        Text(
                          '${state.inquiry?.listing.title}',
                          style: TextStyle(color: palette.textMuted),
                        ),
                        Text(
                          _fmt(state.inquiry?.viewingAt),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: palette.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: state.isBusy ? null : ctrl.payDeposit,
                          style: FilledButton.styleFrom(
                            backgroundColor: TaifaColors.emerald700,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: Text(
                            state.isBusy
                                ? 'Paying…'
                                : 'Pay deposit · ${state.inquiry?.listing.deposit.format() ?? ''}',
                          ),
                        ),
                      ],
                    ),
                  ),
                  HousingPhase.receipt => ListView(
                    key: const ValueKey('r'),
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        'Deposit received',
                        style: TaifaTypography.sectionTitle(
                          palette.textPrimary,
                        ).copyWith(fontSize: 22),
                      ),
                      Text(
                        '${state.inquiry?.listing.title}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: palette.textPrimary,
                        ),
                      ),
                      Text(
                        'Ref ${state.inquiry?.paymentRef}',
                        style: TextStyle(color: palette.textMuted),
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton(
                        onPressed: () => context.go('/home'),
                        child: const Text('Back to Home'),
                      ),
                    ],
                  ),
                  HousingPhase.history =>
                    state.history.isEmpty
                        ? Center(
                            child: Text(
                              'No inquiries yet.',
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
                              final q = state.history[i];
                              return Material(
                                color: palette.surface,
                                borderRadius: BorderRadius.circular(14),
                                child: ListTile(
                                  title: Text(
                                    q.listing.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: palette.textPrimary,
                                    ),
                                  ),
                                  subtitle: Text(
                                    q.status.label,
                                    style: TextStyle(
                                      color: palette.textMuted,
                                      fontSize: 12,
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

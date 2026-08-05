import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../../../app/theme/taifa_theme.dart';
import '../../../app/theme/taifa_typography.dart';
import '../../../shared/widgets/taifa_logo.dart';
import '../application/jobs_providers.dart';
import '../domain/jobs_models.dart';

class JobsScreen extends ConsumerStatefulWidget {
  const JobsScreen({super.key});

  @override
  ConsumerState<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends ConsumerState<JobsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(jobsControllerProvider.notifier).bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(jobsControllerProvider);
    final ctrl = ref.read(jobsControllerProvider.notifier);
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
                        case JobsPhase.home:
                          context.canPop()
                              ? context.pop()
                              : context.go('/home');
                        case JobsPhase.detail:
                          ctrl.backHome();
                        case JobsPhase.history:
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
                        JobsPhase.home => 'Jobs & Logistics',
                        JobsPhase.detail => 'Job detail',
                        JobsPhase.active => 'Active job',
                        JobsPhase.receipt => 'Payout',
                        JobsPhase.history => 'History',
                      },
                      style: TaifaTypography.sectionTitle(
                        palette.textPrimary,
                      ).copyWith(fontSize: 18),
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
                  JobsPhase.home => ListView(
                    key: const ValueKey('h'),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      TextField(
                        onChanged: ctrl.search,
                        decoration: InputDecoration(
                          hintText: 'Search gigs & parcel runs…',
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
                      ...state.jobs.map(
                        (j) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Material(
                            color: palette.surface,
                            borderRadius: BorderRadius.circular(16),
                            child: ListTile(
                              onTap: () => ctrl.open(j),
                              leading: Icon(
                                j.kind == JobKind.logistics
                                    ? Icons.local_shipping_rounded
                                    : Icons.handyman_rounded,
                                color: TaifaColors.ocean400,
                              ),
                              title: Text(
                                j.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: palette.textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                '${j.area} · ${j.pay.format()}',
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
                  JobsPhase.detail => ListView(
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
                          state.selected!.summary,
                          style: TextStyle(
                            color: palette.textMuted,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          state.selected!.pay.format(),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: palette.textPrimary,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: state.isBusy ? null : ctrl.accept,
                          style: FilledButton.styleFrom(
                            backgroundColor: TaifaColors.emerald700,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: Text(
                            state.isBusy ? 'Accepting…' : 'Accept job',
                          ),
                        ),
                      ],
                    ],
                  ),
                  JobsPhase.active => Padding(
                    key: const ValueKey('a'),
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.assignment?.status.label ?? '',
                          style: const TextStyle(
                            color: TaifaColors.emerald700,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.assignment?.job.title ?? '',
                          style: TaifaTypography.sectionTitle(
                            palette.textPrimary,
                          ).copyWith(fontSize: 22),
                        ),
                        Text(
                          state.assignment?.job.pay.format() ?? '',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: palette.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: state.isBusy ? null : ctrl.advance,
                          style: FilledButton.styleFrom(
                            backgroundColor: TaifaColors.emerald700,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: Text(
                            state.isBusy
                                ? '…'
                                : switch (state.assignment?.status) {
                                    JobAssignmentStatus.accepted => 'Start job',
                                    JobAssignmentStatus.inProgress =>
                                      'Mark complete',
                                    JobAssignmentStatus.completed =>
                                      'Collect payout',
                                    _ => 'Continue',
                                  },
                          ),
                        ),
                      ],
                    ),
                  ),
                  JobsPhase.receipt => ListView(
                    key: const ValueKey('r'),
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        'Payout confirmed',
                        style: TaifaTypography.sectionTitle(
                          palette.textPrimary,
                        ).copyWith(fontSize: 22),
                      ),
                      Text(
                        '${state.assignment?.job.title}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: palette.textPrimary,
                        ),
                      ),
                      Text(
                        '${state.assignment?.job.pay.format()} · ${state.assignment?.paymentRef}',
                        style: TextStyle(color: palette.textMuted),
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton(
                        onPressed: () => context.go('/home'),
                        child: const Text('Back to Home'),
                      ),
                    ],
                  ),
                  JobsPhase.history =>
                    state.history.isEmpty
                        ? Center(
                            child: Text(
                              'No jobs yet.',
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
                              final a = state.history[i];
                              return Material(
                                color: palette.surface,
                                borderRadius: BorderRadius.circular(14),
                                child: ListTile(
                                  title: Text(
                                    a.job.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: palette.textPrimary,
                                    ),
                                  ),
                                  subtitle: Text(
                                    a.status.label,
                                    style: TextStyle(
                                      color: palette.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: Text(
                                    a.job.pay.format(),
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

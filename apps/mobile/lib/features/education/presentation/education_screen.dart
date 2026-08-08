import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../../../app/theme/taifa_theme.dart';
import '../../../app/theme/taifa_typography.dart';
import '../../../shared/widgets/taifa_logo.dart';
import '../application/education_providers.dart';
import '../domain/education_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class EducationScreen extends ConsumerStatefulWidget {
  const EducationScreen({super.key});

  @override
  ConsumerState<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends ConsumerState<EducationScreen> {
  final _student = TextEditingController(text: 'Neema Juma');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(educationControllerProvider.notifier).bootstrap();
    });
  }

  @override
  void dispose() {
    _student.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(educationControllerProvider);
    final ctrl = ref.read(educationControllerProvider.notifier);
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
                        case EducationPhase.home:
                          context.canPop()
                              ? context.pop()
                              : context.go('/home');
                        case EducationPhase.detail:
                          ctrl.backHome();
                        case EducationPhase.checkout:
                          if (state.selected != null) {
                            ctrl.open(state.selected!);
                          }
                        case EducationPhase.history:
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
                        EducationPhase.home => 'TAIFA Education',
                        EducationPhase.detail =>
                          state.selected?.name ?? 'School',
                        EducationPhase.checkout => 'School fees',
                        EducationPhase.invoiced => 'Invoice',
                        EducationPhase.receipt => 'Receipt',
                        EducationPhase.history => 'Payments',
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
                  EducationPhase.home => ListView(
                    key: const ValueKey('h'),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      TextField(
                        onChanged: ctrl.search,
                        decoration: InputDecoration(
                          hintText: 'Search schools & courses…',
                          prefixIcon: Icon(
                            LucideIcons.search,
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
                      ...state.schools.map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Material(
                            color: palette.surface,
                            borderRadius: BorderRadius.circular(16),
                            child: ListTile(
                              onTap: () => ctrl.open(s),
                              title: Text(
                                s.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: palette.textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                '${s.level} · ${s.area} · ${s.termFee.format()}',
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
                  EducationPhase.detail => ListView(
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
                          '${state.selected!.level} · ${state.selected!.area}',
                          style: TextStyle(color: palette.textMuted),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Term fee ${state.selected!.termFee.format()}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: palette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: ctrl.goCheckout,
                          style: FilledButton.styleFrom(
                            backgroundColor: TaifaColors.emerald700,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: const Text('Pay school fees'),
                        ),
                      ],
                    ],
                  ),
                  EducationPhase.checkout => ListView(
                    key: const ValueKey('c'),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      TextField(
                        controller: _student,
                        onChanged: ctrl.setStudent,
                        decoration: const InputDecoration(
                          labelText: 'Student name',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Amount ${state.selected?.termFee.format() ?? '—'}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: state.isBusy ? null : ctrl.createInvoice,
                        style: FilledButton.styleFrom(
                          backgroundColor: TaifaColors.emerald700,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: Text(
                          state.isBusy
                              ? 'Creating invoice…'
                              : 'Generate invoice',
                        ),
                      ),
                    ],
                  ),
                  EducationPhase.invoiced => Padding(
                    key: const ValueKey('inv'),
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Invoice ready',
                          style: TaifaTypography.sectionTitle(
                            palette.textPrimary,
                          ).copyWith(fontSize: 22),
                        ),
                        Text(
                          '${state.payment?.invoiceNo} · ${state.payment?.studentName}',
                          style: TextStyle(color: palette.textMuted),
                        ),
                        Text(
                          state.payment?.amount.format() ?? '',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: palette.textPrimary,
                            fontSize: 20,
                          ),
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: state.isBusy ? null : ctrl.pay,
                          style: FilledButton.styleFrom(
                            backgroundColor: TaifaColors.emerald700,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: Text(
                            state.isBusy ? 'Paying…' : 'Pay with wallet',
                          ),
                        ),
                      ],
                    ),
                  ),
                  EducationPhase.receipt => ListView(
                    key: const ValueKey('rx'),
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        'Fees paid',
                        style: TaifaTypography.sectionTitle(
                          palette.textPrimary,
                        ).copyWith(fontSize: 22),
                      ),
                      Text(
                        '${state.payment?.school.name}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: palette.textPrimary,
                        ),
                      ),
                      Text(
                        'Ref ${state.payment?.paymentRef}',
                        style: TextStyle(color: palette.textMuted),
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton(
                        onPressed: () => context.go('/home'),
                        child: const Text('Back to Home'),
                      ),
                    ],
                  ),
                  EducationPhase.history =>
                    state.history.isEmpty
                        ? Center(
                            child: Text(
                              'No fee payments yet.',
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
                              final p = state.history[i];
                              return Material(
                                color: palette.surface,
                                borderRadius: BorderRadius.circular(14),
                                child: ListTile(
                                  title: Text(
                                    p.school.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: palette.textPrimary,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${p.status.label} · ${p.studentName}',
                                    style: TextStyle(
                                      color: palette.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: Text(
                                    p.amount.format(),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../../../app/theme/taifa_theme.dart';
import '../../../app/theme/taifa_typography.dart';
import '../../../shared/widgets/taifa_logo.dart';
import '../application/health_providers.dart';
import '../domain/health_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class HealthScreen extends ConsumerStatefulWidget {
  const HealthScreen({super.key});

  @override
  ConsumerState<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends ConsumerState<HealthScreen> {
  final _patient = TextEditingController(text: 'Amani Juma');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(healthControllerProvider.notifier).bootstrap();
    });
  }

  @override
  void dispose() {
    _patient.dispose();
    super.dispose();
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
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${m[d.month - 1]} · $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(healthControllerProvider);
    final ctrl = ref.read(healthControllerProvider.notifier);
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
                        case HealthPhase.home:
                          context.canPop()
                              ? context.pop()
                              : context.go('/home');
                        case HealthPhase.detail:
                          ctrl.backHome();
                        case HealthPhase.checkout:
                          if (state.selected != null) {
                            ctrl.open(state.selected!);
                          }
                        case HealthPhase.history:
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
                        HealthPhase.home => 'TAIFA Health',
                        HealthPhase.detail => state.selected?.name ?? 'Clinic',
                        HealthPhase.checkout => 'Book visit',
                        HealthPhase.confirmed => 'Confirmed',
                        HealthPhase.receipt => 'Receipt',
                        HealthPhase.history => 'Appointments',
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
                      LucideIcons.calendar,
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
                  HealthPhase.home => ListView(
                    key: const ValueKey('h'),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      TextField(
                        onChanged: ctrl.search,
                        decoration: InputDecoration(
                          hintText: 'Search hospitals & specialties…',
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
                      ...state.facilities.map(
                        (f) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Material(
                            color: palette.surface,
                            borderRadius: BorderRadius.circular(16),
                            child: ListTile(
                              onTap: () => ctrl.open(f),
                              title: Text(
                                f.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: palette.textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                '${f.specialty} · ${f.area} · ${f.consultFee.format()}',
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
                  HealthPhase.detail => ListView(
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
                          '${state.selected!.specialty} · ★ ${state.selected!.rating}',
                          style: TextStyle(color: palette.textMuted),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Consultation ${state.selected!.consultFee.format()}',
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
                          child: const Text('Book appointment'),
                        ),
                      ],
                    ],
                  ),
                  HealthPhase.checkout => ListView(
                    key: const ValueKey('c'),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      TextField(
                        controller: _patient,
                        onChanged: ctrl.setPatient,
                        decoration: const InputDecoration(
                          labelText: 'Patient name',
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Slot',
                          style: TextStyle(
                            color: palette.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        subtitle: Text(
                          _fmt(state.slot),
                          style: TextStyle(
                            color: palette.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        trailing: TextButton(
                          onPressed: () async {
                            final now = DateTime.now();
                            final d = await showDatePicker(
                              context: context,
                              initialDate:
                                  state.slot ??
                                  now.add(const Duration(days: 1)),
                              firstDate: now,
                              lastDate: now.add(const Duration(days: 60)),
                            );
                            if (d != null) {
                              ctrl.setSlot(
                                DateTime(d.year, d.month, d.day, 10, 0),
                              );
                            }
                          },
                          child: const Text('Change'),
                        ),
                      ),
                      Text(
                        'Total ${state.selected?.consultFee.format() ?? '—'}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: state.isBusy ? null : ctrl.book,
                        style: FilledButton.styleFrom(
                          backgroundColor: TaifaColors.emerald700,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: Text(
                          state.isBusy ? 'Booking…' : 'Confirm booking',
                        ),
                      ),
                    ],
                  ),
                  HealthPhase.confirmed => Padding(
                    key: const ValueKey('ok'),
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          LucideIcons.circleCheckBig,
                          color: TaifaColors.emerald500,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Appointment held',
                          style: TaifaTypography.sectionTitle(
                            palette.textPrimary,
                          ).copyWith(fontSize: 22),
                        ),
                        Text(
                          '${state.appointment?.facility.name} · ${state.appointment?.confirmationCode}',
                          style: TextStyle(color: palette.textMuted),
                        ),
                        Text(
                          _fmt(state.appointment?.slot),
                          style: TextStyle(
                            color: palette.textPrimary,
                            fontWeight: FontWeight.w600,
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
                            state.isBusy
                                ? 'Paying…'
                                : 'Pay consult · ${state.appointment?.fee.format() ?? ''}',
                          ),
                        ),
                      ],
                    ),
                  ),
                  HealthPhase.receipt => ListView(
                    key: const ValueKey('rx'),
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        'Payment confirmed',
                        style: TaifaTypography.sectionTitle(
                          palette.textPrimary,
                        ).copyWith(fontSize: 22),
                      ),
                      Text(
                        '${state.appointment?.facility.name}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: palette.textPrimary,
                        ),
                      ),
                      Text(
                        'Ref ${state.appointment?.paymentRef}',
                        style: TextStyle(color: palette.textMuted),
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton(
                        onPressed: () => context.go('/home'),
                        child: const Text('Back to Home'),
                      ),
                    ],
                  ),
                  HealthPhase.history =>
                    state.history.isEmpty
                        ? Center(
                            key: const ValueKey('empty'),
                            child: Text(
                              'No appointments yet.',
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
                                    a.facility.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: palette.textPrimary,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${a.status.label} · ${_fmt(a.slot)}',
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

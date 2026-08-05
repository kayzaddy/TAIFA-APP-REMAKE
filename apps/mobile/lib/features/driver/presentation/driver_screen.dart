import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../../../app/theme/taifa_theme.dart';
import '../../../app/theme/taifa_typography.dart';
import '../../../shared/widgets/taifa_logo.dart';
import '../application/driver_providers.dart';
import '../domain/driver_models.dart';

class DriverScreen extends ConsumerStatefulWidget {
  const DriverScreen({super.key});

  @override
  ConsumerState<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends ConsumerState<DriverScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(driverControllerProvider.notifier).bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(driverControllerProvider);
    final ctrl = ref.read(driverControllerProvider.notifier);
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
                      if (state.phase == DriverPhase.job) {
                        ctrl.backHome();
                      } else if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/menu');
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
                      state.phase == DriverPhase.job ? 'Job' : 'Driver',
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
                child: state.phase == DriverPhase.job
                    ? _Job(key: const ValueKey('j'), state: state, ctrl: ctrl)
                    : _Home(key: const ValueKey('h'), state: state, ctrl: ctrl),
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
  final DriverUiState state;
  final DriverController ctrl;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Online',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
            ),
          ),
          subtitle: Text(
            state.online ? 'Receiving ride offers' : 'You are offline',
            style: TextStyle(color: palette.textMuted, fontSize: 12),
          ),
          value: state.online,
          activeThumbColor: TaifaColors.emerald500,
          onChanged: ctrl.setOnline,
        ),
        const SizedBox(height: 8),
        Text(
          'Today ${state.earnings?.format() ?? 'TSh 0'}',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Offers',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        if (!state.online)
          Text(
            'Go online to see jobs.',
            style: TextStyle(color: palette.textMuted),
          )
        else if (state.jobs.isEmpty)
          Text(
            'No offers right now.',
            style: TextStyle(color: palette.textMuted),
          )
        else
          ...state.jobs.map(
            (j) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: palette.surface,
                borderRadius: BorderRadius.circular(14),
                child: ListTile(
                  onTap: () => ctrl.open(j),
                  title: Text(
                    '${j.pickup} → ${j.dropoff}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: palette.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    '${j.riderName} · ${j.etaMinutes} min · ${j.status.label}',
                    style: TextStyle(color: palette.textMuted, fontSize: 12),
                  ),
                  trailing: Text(
                    j.fare.format(),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: palette.textPrimary,
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

class _Job extends StatelessWidget {
  const _Job({super.key, required this.state, required this.ctrl});
  final DriverUiState state;
  final DriverController ctrl;

  @override
  Widget build(BuildContext context) {
    final j = state.active;
    if (j == null) return const SizedBox.shrink();
    final palette = context.taifa;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            j.status.label,
            style: const TextStyle(
              color: TaifaColors.emerald700,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${j.pickup} → ${j.dropoff}',
            style: TaifaTypography.sectionTitle(
              palette.textPrimary,
            ).copyWith(fontSize: 22),
          ),
          Text(
            '${j.riderName} · ETA ${j.etaMinutes} min',
            style: TextStyle(color: palette.textMuted),
          ),
          const SizedBox(height: 8),
          Text(
            j.fare.format(),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
              fontSize: 20,
            ),
          ),
          const Spacer(),
          if (j.status == DriverJobStatus.offered) ...[
            FilledButton(
              onPressed: state.isBusy ? null : ctrl.accept,
              style: FilledButton.styleFrom(
                backgroundColor: TaifaColors.emerald700,
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(state.isBusy ? '…' : 'Accept job'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: state.isBusy ? null : ctrl.decline,
              child: const Text('Decline'),
            ),
          ] else if (j.status != DriverJobStatus.completed)
            FilledButton(
              onPressed: state.isBusy ? null : ctrl.advance,
              style: FilledButton.styleFrom(
                backgroundColor: TaifaColors.emerald700,
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(
                state.isBusy
                    ? '…'
                    : switch (j.status) {
                        DriverJobStatus.accepted => 'Start to pickup',
                        DriverJobStatus.enRoute => 'Arrived',
                        DriverJobStatus.arrived => 'Start trip',
                        DriverJobStatus.inTrip => 'Complete trip',
                        _ => 'Continue',
                      },
              ),
            ),
        ],
      ),
    );
  }
}

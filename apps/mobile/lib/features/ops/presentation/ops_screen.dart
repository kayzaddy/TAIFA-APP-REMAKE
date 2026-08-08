import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../../../app/theme/taifa_theme.dart';
import '../../../app/theme/taifa_typography.dart';
import '../../../shared/widgets/taifa_logo.dart';
import '../application/ops_providers.dart';
import '../domain/ops_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class OpsScreen extends ConsumerStatefulWidget {
  const OpsScreen({super.key});

  @override
  ConsumerState<OpsScreen> createState() => _OpsScreenState();
}

class _OpsScreenState extends ConsumerState<OpsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(opsControllerProvider.notifier).bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(opsControllerProvider);
    final ctrl = ref.read(opsControllerProvider.notifier);
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
                      if (state.phase == OpsPhase.detail) {
                        ctrl.back();
                      } else if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/menu');
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
                      state.phase == OpsPhase.detail
                          ? 'Incident'
                          : 'Operations',
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
                child: state.phase == OpsPhase.detail
                    ? _Detail(
                        key: const ValueKey('d'),
                        state: state,
                        ctrl: ctrl,
                      )
                    : _Dash(key: const ValueKey('h'), state: state, ctrl: ctrl),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dash extends StatelessWidget {
  const _Dash({super.key, required this.state, required this.ctrl});
  final OpsUiState state;
  final OpsController ctrl;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final stats = state.stats;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text('Live ops · Tanzania', style: TextStyle(color: palette.textMuted)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _Stat(
                label: 'Rides',
                value: '${stats?.activeRides ?? '—'}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Stat(
                label: 'Food',
                value: '${stats?.openFoodOrders ?? 0}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _Stat(
                label: 'Pay queue',
                value: '${stats?.paymentQueue ?? '—'}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Stat(
                label: 'Incidents',
                value: '${stats?.openIncidents ?? 0}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Incidents',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        if (state.isBusy && state.incidents.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          ...state.incidents.map(
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: palette.surface,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () => ctrl.open(i),
                  borderRadius: BorderRadius.circular(14),
                  child: ListTile(
                    title: Text(
                      i.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      '${i.severity} · ${i.region} · ${i.status.label}',
                      style: TextStyle(color: palette.textMuted, fontSize: 12),
                    ),
                    trailing: Icon(
                      LucideIcons.chevronRight,
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

class _Detail extends StatelessWidget {
  const _Detail({super.key, required this.state, required this.ctrl});
  final OpsUiState state;
  final OpsController ctrl;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final i = state.selected!;
    final action = switch (i.status) {
      OpsIncidentStatus.open => 'Acknowledge',
      OpsIncidentStatus.acknowledged => 'Mark resolved',
      OpsIncidentStatus.resolved => 'Resolved',
    };
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          i.title,
          style: TaifaTypography.sectionTitle(
            palette.textPrimary,
          ).copyWith(fontSize: 22),
        ),
        Text(
          '${i.severity} · ${i.region}',
          style: TextStyle(color: palette.textMuted),
        ),
        const SizedBox(height: 12),
        Text(
          i.detail,
          style: TextStyle(color: palette.textPrimary, height: 1.4),
        ),
        const SizedBox(height: 8),
        Text(
          'Status · ${i.status.label}',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: TaifaColors.emerald500,
          ),
        ),
        const SizedBox(height: 24),
        if (i.status != OpsIncidentStatus.resolved)
          FilledButton(
            onPressed: state.isBusy ? null : ctrl.advanceSelected,
            style: FilledButton.styleFrom(
              backgroundColor: TaifaColors.emerald700,
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(state.isBusy ? 'Working…' : action),
          ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: palette.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: palette.textPrimary,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

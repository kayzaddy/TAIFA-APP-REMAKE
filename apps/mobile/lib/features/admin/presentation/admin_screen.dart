import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../../../app/theme/taifa_theme.dart';
import '../../../app/theme/taifa_typography.dart';
import '../../../shared/widgets/taifa_logo.dart';
import '../application/admin_providers.dart';
import '../domain/admin_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminControllerProvider.notifier).bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminControllerProvider);
    final ctrl = ref.read(adminControllerProvider.notifier);
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
                      if (state.phase == AdminPhase.detail) {
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
                      state.phase == AdminPhase.detail ? 'Case' : 'Admin',
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
                child: state.phase == AdminPhase.detail
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
  final AdminUiState state;
  final AdminController ctrl;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final stats = state.stats;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          'Platform control · TAIFA HQ',
          style: TextStyle(color: palette.textMuted),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _Stat(
                label: 'Users',
                value: '${stats?.activeUsers ?? '—'}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Stat(label: 'Open', value: '${stats?.openCases ?? 0}'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _Stat(
                label: 'Merchants',
                value: '${stats?.merchants ?? '—'}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Stat(
                label: 'Flagged',
                value: '${stats?.flaggedWallets ?? 0}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Queue',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        if (state.isBusy && state.cases.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          ...state.cases.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: palette.surface,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () => ctrl.open(c),
                  borderRadius: BorderRadius.circular(14),
                  child: ListTile(
                    title: Text(
                      c.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      '${c.subject} · ${c.status.label}',
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
  final AdminUiState state;
  final AdminController ctrl;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final c = state.selected!;
    final action = switch (c.status) {
      AdminCaseStatus.open => 'Start review',
      AdminCaseStatus.reviewing => 'Resolve case',
      AdminCaseStatus.resolved => 'Resolved',
    };
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          c.title,
          style: TaifaTypography.sectionTitle(
            palette.textPrimary,
          ).copyWith(fontSize: 22),
        ),
        Text(c.subject, style: TextStyle(color: palette.textMuted)),
        const SizedBox(height: 12),
        Text(
          c.detail,
          style: TextStyle(color: palette.textPrimary, height: 1.4),
        ),
        const SizedBox(height: 8),
        Text(
          'Status · ${c.status.label}',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: TaifaColors.emerald500,
          ),
        ),
        const SizedBox(height: 24),
        if (c.status != AdminCaseStatus.resolved)
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

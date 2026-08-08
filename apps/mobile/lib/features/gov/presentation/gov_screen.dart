import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../../../app/theme/taifa_theme.dart';
import '../../../app/theme/taifa_typography.dart';
import '../../../shared/widgets/taifa_logo.dart';
import '../application/gov_providers.dart';
import '../domain/gov_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class GovScreen extends ConsumerStatefulWidget {
  const GovScreen({super.key});

  @override
  ConsumerState<GovScreen> createState() => _GovScreenState();
}

class _GovScreenState extends ConsumerState<GovScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(govControllerProvider.notifier).bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(govControllerProvider);
    final ctrl = ref.read(govControllerProvider.notifier);
    final palette = context.taifa;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          children: [
            _bar(
              context,
              palette,
              title: switch (state.phase) {
                GovPhase.home => 'TAIFA Gov',
                GovPhase.detail => state.selected?.title ?? 'Service',
                GovPhase.confirm => 'Confirm request',
                GovPhase.tracking => 'Tracking',
                GovPhase.receipt => 'Receipt',
                GovPhase.history => 'My requests',
              },
              onBack: () {
                switch (state.phase) {
                  case GovPhase.home:
                    context.canPop() ? context.pop() : context.go('/home');
                  case GovPhase.detail:
                    ctrl.backHome();
                  case GovPhase.confirm:
                    if (state.selected != null) ctrl.open(state.selected!);
                  case GovPhase.history:
                    ctrl.backHome();
                  default:
                    ctrl.backHome();
                }
              },
              onHistory: ctrl.openHistory,
            ),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  state.error!,
                  style: const TextStyle(
                    color: Color(0xFFFF8A80),
                    fontSize: 12,
                  ),
                ),
              ),
            Expanded(
              child: AnimatedSwitcher(
                duration: TaifaMotion.base,
                child: switch (state.phase) {
                  GovPhase.home => _Home(
                    key: const ValueKey('h'),
                    state: state,
                    ctrl: ctrl,
                  ),
                  GovPhase.detail => _Detail(
                    key: const ValueKey('d'),
                    state: state,
                    ctrl: ctrl,
                  ),
                  GovPhase.confirm => _Confirm(
                    key: const ValueKey('c'),
                    state: state,
                    ctrl: ctrl,
                  ),
                  GovPhase.tracking => _Track(
                    key: const ValueKey('t'),
                    state: state,
                    ctrl: ctrl,
                  ),
                  GovPhase.receipt => _Receipt(
                    key: const ValueKey('r'),
                    state: state,
                  ),
                  GovPhase.history => _History(
                    key: const ValueKey('x'),
                    state: state,
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bar(
    BuildContext context,
    TaifaPalette palette, {
    required String title,
    required VoidCallback onBack,
    required VoidCallback onHistory,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(LucideIcons.arrowLeft, color: palette.textPrimary),
          ),
          const TaifaLogo(variant: TaifaLogoVariant.mark, size: 32),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TaifaTypography.sectionTitle(
                palette.textPrimary,
              ).copyWith(fontSize: 18),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: onHistory,
            icon: Icon(LucideIcons.history, color: palette.textMuted),
          ),
        ],
      ),
    );
  }
}

class _Home extends StatelessWidget {
  const _Home({super.key, required this.state, required this.ctrl});
  final GovUiState state;
  final GovController ctrl;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        TextField(
          onChanged: ctrl.search,
          decoration: InputDecoration(
            hintText: 'Search NIDA, TRA, passport…',
            prefixIcon: Icon(LucideIcons.search, color: palette.textMuted),
            filled: true,
            fillColor: palette.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Huduma services',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        ...state.services.map(
          (s) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: palette.surface,
              borderRadius: BorderRadius.circular(16),
              child: ListTile(
                onTap: () => ctrl.open(s),
                title: Text(
                  s.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                ),
                subtitle: Text(
                  '${s.agency} · ${s.category} · ${s.fee.format()}',
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
      ],
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({super.key, required this.state, required this.ctrl});
  final GovUiState state;
  final GovController ctrl;

  @override
  Widget build(BuildContext context) {
    final s = state.selected;
    if (s == null) return const SizedBox.shrink();
    final palette = context.taifa;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          s.title,
          style: TaifaTypography.sectionTitle(
            palette.textPrimary,
          ).copyWith(fontSize: 22),
        ),
        Text(
          '${s.agency} · ~${s.etaDays} days',
          style: TextStyle(color: palette.textMuted),
        ),
        const SizedBox(height: 12),
        Text(
          s.description,
          style: TextStyle(color: palette.textPrimary, height: 1.4),
        ),
        const SizedBox(height: 12),
        Text(
          'Fee ${s.fee.format()}',
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
          child: const Text('Start request'),
        ),
      ],
    );
  }
}

class _Confirm extends StatelessWidget {
  const _Confirm({super.key, required this.state, required this.ctrl});
  final GovUiState state;
  final GovController ctrl;

  @override
  Widget build(BuildContext context) {
    final s = state.selected;
    if (s == null) return const SizedBox.shrink();
    final palette = context.taifa;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          s.title,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: state.applicantName,
          onChanged: ctrl.setApplicant,
          decoration: const InputDecoration(labelText: 'Applicant full name'),
        ),
        const SizedBox(height: 12),
        Text(
          'No real NIDA/Immigration APIs yet — this submits a demo request.',
          style: TextStyle(color: palette.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: state.isBusy ? null : ctrl.submit,
          style: FilledButton.styleFrom(
            backgroundColor: TaifaColors.emerald700,
            minimumSize: const Size.fromHeight(48),
          ),
          child: Text(state.isBusy ? 'Submitting…' : 'Submit request'),
        ),
      ],
    );
  }
}

class _Track extends StatelessWidget {
  const _Track({super.key, required this.state, required this.ctrl});
  final GovUiState state;
  final GovController ctrl;

  @override
  Widget build(BuildContext context) {
    final r = state.request;
    if (r == null) return const SizedBox.shrink();
    final palette = context.taifa;
    final needsPay = r.service.fee.minorUnits > 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            LucideIcons.hourglass,
            color: TaifaColors.gold400,
            size: 44,
          ),
          const SizedBox(height: 12),
          Text(
            r.status.label,
            style: TaifaTypography.sectionTitle(
              palette.textPrimary,
            ).copyWith(fontSize: 22),
          ),
          Text(
            'Ref ${r.reference}',
            style: TextStyle(color: palette.textMuted),
          ),
          Text(
            r.service.title,
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
                  ? 'Processing…'
                  : needsPay
                  ? 'Pay fee · ${r.service.fee.format()}'
                  : 'Mark complete',
            ),
          ),
        ],
      ),
    );
  }
}

class _Receipt extends StatelessWidget {
  const _Receipt({super.key, required this.state});
  final GovUiState state;

  @override
  Widget build(BuildContext context) {
    final r = state.request;
    if (r == null) return const SizedBox.shrink();
    final palette = context.taifa;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text(
          'Request complete',
          style: TaifaTypography.sectionTitle(
            palette.textPrimary,
          ).copyWith(fontSize: 22),
        ),
        const SizedBox(height: 12),
        Text(
          r.service.title,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
          ),
        ),
        Text(
          'Ref ${r.reference} · ${r.paymentRef ?? 'No fee'}',
          style: TextStyle(color: palette.textMuted),
        ),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: () => context.go('/home'),
          child: const Text('Back to Home'),
        ),
      ],
    );
  }
}

class _History extends StatelessWidget {
  const _History({super.key, required this.state});
  final GovUiState state;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    if (state.history.isEmpty) {
      return Center(
        child: Text(
          'No requests yet.',
          style: TextStyle(color: palette.textMuted),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: state.history.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final r = state.history[i];
        return Material(
          color: palette.surface,
          borderRadius: BorderRadius.circular(14),
          child: ListTile(
            title: Text(
              r.service.title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
            ),
            subtitle: Text(
              '${r.status.label} · ${r.reference}',
              style: TextStyle(color: palette.textMuted, fontSize: 12),
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../../../app/theme/taifa_theme.dart';
import '../../../app/theme/taifa_typography.dart';
import '../../../shared/widgets/taifa_logo.dart';
import '../application/family_providers.dart';
import '../domain/family_models.dart';

class FamilyScreen extends ConsumerStatefulWidget {
  const FamilyScreen({super.key});

  @override
  ConsumerState<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends ConsumerState<FamilyScreen> {
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    _note = TextEditingController(text: 'Monthly allowance');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(familyControllerProvider.notifier).bootstrap();
    });
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(familyControllerProvider);
    final ctrl = ref.read(familyControllerProvider.notifier);
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
                        case FamilyPhase.home:
                          context.canPop()
                              ? context.pop()
                              : context.go('/home');
                        case FamilyPhase.detail:
                          ctrl.backHome();
                        case FamilyPhase.confirm:
                          if (state.selected != null) {
                            ctrl.open(state.selected!);
                          }
                        case FamilyPhase.history:
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
                        FamilyPhase.home => 'Family Wallet',
                        FamilyPhase.detail => state.selected?.name ?? 'Member',
                        FamilyPhase.confirm => 'Send / request',
                        FamilyPhase.receipt => 'Done',
                        FamilyPhase.history => 'Activity',
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
                  FamilyPhase.home => ListView(
                    key: const ValueKey('fam-h'),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      Text(
                        'Shared pot · Kibaki household',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Send allowance or request from family',
                        style: TextStyle(
                          color: palette.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...state.members.map(
                        (m) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Material(
                            color: palette.surface,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              onTap: () => ctrl.open(m),
                              borderRadius: BorderRadius.circular(16),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: TaifaColors.emerald500
                                      .withValues(alpha: 0.18),
                                  child: Text(
                                    m.name.isEmpty ? '?' : m.name[0],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: TaifaColors.emerald700,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  m.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: palette.textPrimary,
                                  ),
                                ),
                                subtitle: Text(
                                  '${m.role}\n${m.phone}',
                                  style: TextStyle(
                                    color: palette.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                                isThreeLine: true,
                                trailing: m.allowance.isZero
                                    ? null
                                    : Text(
                                        m.allowance.format(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: palette.textPrimary,
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
                  FamilyPhase.detail => ListView(
                    key: const ValueKey('fam-d'),
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
                          state.selected!.role,
                          style: TextStyle(color: palette.textMuted),
                        ),
                        const SizedBox(height: 16),
                        SegmentedButton<FamilyTxKind>(
                          segments: const [
                            ButtonSegment(
                              value: FamilyTxKind.send,
                              label: Text('Send'),
                              icon: Icon(Icons.north_east),
                            ),
                            ButtonSegment(
                              value: FamilyTxKind.request,
                              label: Text('Request'),
                              icon: Icon(Icons.south_west),
                            ),
                          ],
                          selected: {state.kind},
                          onSelectionChanged: (s) => ctrl.setKind(s.first),
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: ctrl.goConfirm,
                          style: FilledButton.styleFrom(
                            backgroundColor: TaifaColors.emerald700,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: Text(
                            state.kind == FamilyTxKind.send
                                ? 'Send money'
                                : 'Request money',
                          ),
                        ),
                      ],
                    ],
                  ),
                  FamilyPhase.confirm => ListView(
                    key: const ValueKey('fam-c'),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      Text(
                        state.kind == FamilyTxKind.send
                            ? 'Send to ${state.selected?.name}'
                            : 'Request from ${state.selected?.name}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.amount.format(),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: palette.textPrimary,
                          fontSize: 24,
                        ),
                      ),
                      Slider(
                        value: state.amountMajor.toDouble(),
                        min: 5000,
                        max: 200000,
                        divisions: 39,
                        activeColor: TaifaColors.emerald500,
                        onChanged: (v) => ctrl.setAmount(v.round()),
                      ),
                      TextField(
                        decoration: const InputDecoration(labelText: 'Note'),
                        controller: _note,
                        onChanged: ctrl.setNote,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: state.isBusy ? null : ctrl.submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: TaifaColors.emerald700,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: Text(
                          state.isBusy
                              ? 'Processing…'
                              : 'Pay with wallet · ${state.amount.format()}',
                        ),
                      ),
                    ],
                  ),
                  FamilyPhase.receipt => ListView(
                    key: const ValueKey('fam-r'),
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        state.transfer?.kind == FamilyTxKind.send
                            ? 'Sent to family'
                            : 'Request logged',
                        style: TaifaTypography.sectionTitle(
                          palette.textPrimary,
                        ).copyWith(fontSize: 22),
                      ),
                      Text(
                        '${state.transfer?.member.name}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: palette.textPrimary,
                        ),
                      ),
                      Text(
                        '${state.transfer?.amount.format()} · ${state.transfer?.paymentRef}',
                        style: TextStyle(color: palette.textMuted),
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton(
                        onPressed: () => context.go('/home'),
                        child: const Text('Back to Home'),
                      ),
                    ],
                  ),
                  FamilyPhase.history =>
                    state.history.isEmpty
                        ? Center(
                            child: Text(
                              'No family activity yet.',
                              style: TextStyle(color: palette.textMuted),
                            ),
                          )
                        : ListView.separated(
                            key: const ValueKey('fam-hist'),
                            padding: const EdgeInsets.all(16),
                            itemCount: state.history.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final t = state.history[i];
                              return Material(
                                color: palette.surface,
                                borderRadius: BorderRadius.circular(14),
                                child: ListTile(
                                  title: Text(
                                    '${t.kind == FamilyTxKind.send ? 'To' : 'From'} ${t.member.name}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: palette.textPrimary,
                                    ),
                                  ),
                                  trailing: Text(
                                    t.amount.format(),
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

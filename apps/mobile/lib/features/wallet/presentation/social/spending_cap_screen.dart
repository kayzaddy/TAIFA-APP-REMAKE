import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/taifa_colors.dart';
import '../../../../app/theme/taifa_dimens.dart';
import '../../../../app/theme/taifa_theme.dart';
import '../../../../data/dto/social_dto.dart';
import '../../application/social_providers.dart';
import '../../domain/currency.dart';
import '../../domain/money.dart';
import 'social_widgets.dart';

class SpendingCapScreen extends ConsumerStatefulWidget {
  const SpendingCapScreen({super.key});

  @override
  ConsumerState<SpendingCapScreen> createState() => _SpendingCapScreenState();
}

class _SpendingCapScreenState extends ConsumerState<SpendingCapScreen> {
  final _limitController = TextEditingController();
  SpendingCapPeriod _period = SpendingCapPeriod.monthly;
  bool _saving = false;

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final capAsync = ref.watch(spendingCapProvider);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: TaifaSpacing.screenH),
          child: Column(
            children: [
              const SizedBox(height: TaifaSpacing.sm),
              const SocialScreenHeader(title: 'Spending Cap'),
              const SizedBox(height: TaifaSpacing.lg),
              Expanded(
                child: capAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Could not load spending cap.\n$e', textAlign: TextAlign.center)),
                  data: (cap) => ListView(
                    children: [
                      if (cap != null) ...[
                        _CurrentCapCard(cap: cap),
                        const SizedBox(height: TaifaSpacing.lg),
                        Center(
                          child: TextButton(
                            onPressed: _clearing ? null : _clear,
                            child: const Text('Remove spending cap', style: TextStyle(color: TaifaColors.danger)),
                          ),
                        ),
                        const SizedBox(height: TaifaSpacing.xl),
                        Divider(color: palette.border),
                        const SizedBox(height: TaifaSpacing.lg),
                      ],
                      Text(
                        cap == null ? 'Set a spending cap' : 'Change your spending cap',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.textPrimary),
                      ),
                      Text(
                        'Applies to transfers and withdrawals — top-ups are never capped.',
                        style: TextStyle(fontSize: 10, color: palette.textMuted),
                      ),
                      const SizedBox(height: TaifaSpacing.md),
                      SegmentedButton<SpendingCapPeriod>(
                        segments: const [
                          ButtonSegment(value: SpendingCapPeriod.daily, label: Text('Daily')),
                          ButtonSegment(value: SpendingCapPeriod.weekly, label: Text('Weekly')),
                          ButtonSegment(value: SpendingCapPeriod.monthly, label: Text('Monthly')),
                        ],
                        selected: {_period},
                        onSelectionChanged: (s) => setState(() => _period = s.first),
                      ),
                      const SizedBox(height: TaifaSpacing.sm),
                      TextField(
                        controller: _limitController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: TextStyle(color: palette.textPrimary),
                        decoration: const InputDecoration(labelText: 'Limit (TSh)'),
                      ),
                      const SizedBox(height: TaifaSpacing.md),
                      SocialPrimaryButton(label: 'Save cap', loading: _saving, onTap: _submit),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _clearing = false;

  Future<void> _clear() async {
    setState(() => _clearing = true);
    try {
      await ref.read(socialRepositoryProvider).clearSpendingCap();
      ref.invalidate(spendingCapProvider);
    } catch (e) {
      if (mounted) showSocialError(context, e);
    } finally {
      if (mounted) setState(() => _clearing = false);
    }
  }

  Future<void> _submit() async {
    final major = int.tryParse(_limitController.text);
    if (major == null || major <= 0) {
      showSocialError(context, Exception('Enter a valid limit.'));
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(socialRepositoryProvider).setSpendingCap(
        period: _period,
        limit: Money.major(major, Currency.tzs),
      );
      ref.invalidate(spendingCapProvider);
      if (mounted) {
        setState(() => _saving = false);
        showSocialSuccess(context, 'Spending cap saved.');
        _limitController.clear();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showSocialError(context, e);
      }
    }
  }
}

class _CurrentCapCard extends StatelessWidget {
  const _CurrentCapCard({required this.cap});
  final SpendingCap cap;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final progress = cap.limit.minorUnits == 0 ? 0.0 : cap.spent.minorUnits / cap.limit.minorUnits;
    final over = progress >= 1.0;
    return SocialCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${_periodLabel(cap.period).toUpperCase()} CAP', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: palette.textMuted)),
          const SizedBox(height: TaifaSpacing.xs),
          Text(cap.limit.format(), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: palette.textPrimary)),
          const SizedBox(height: TaifaSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(TaifaRadii.pill),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 8,
              backgroundColor: palette.surfaceAlt,
              color: over ? TaifaColors.danger : TaifaColors.emerald500,
            ),
          ),
          const SizedBox(height: TaifaSpacing.xs),
          Text(
            '${cap.spent.format()} spent · ${cap.remaining.format()} remaining',
            style: TextStyle(fontSize: 10, color: over ? TaifaColors.danger : palette.textMuted),
          ),
        ],
      ),
    );
  }

  String _periodLabel(SpendingCapPeriod p) => switch (p) {
    SpendingCapPeriod.daily => 'Daily',
    SpendingCapPeriod.weekly => 'Weekly',
    SpendingCapPeriod.monthly => 'Monthly',
  };
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/taifa_colors.dart';
import '../../../../app/theme/taifa_dimens.dart';
import '../../../../app/theme/taifa_theme.dart';
import '../../../../data/dto/social_dto.dart';
import '../../application/social_providers.dart';
import '../../domain/money.dart';
import 'social_widgets.dart';

class SpendingAnalyticsScreen extends ConsumerWidget {
  const SpendingAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.taifa;
    final asyncData = ref.watch(spendingAnalyticsProvider(6));
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: TaifaSpacing.screenH),
          child: Column(
            children: [
              const SizedBox(height: TaifaSpacing.sm),
              const SocialScreenHeader(title: 'Spending Analytics'),
              const SizedBox(height: TaifaSpacing.lg),
              Expanded(
                child: asyncData.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Could not load analytics.\n$e', textAlign: TextAlign.center)),
                  data: (analytics) {
                    if (analytics.months.every((m) => m.totalIn.isZero && m.totalOut.isZero)) {
                      return const SocialEmptyState(icon: Icons.insights_rounded, message: 'No transaction activity in this window yet.');
                    }
                    final maxValue = analytics.months.fold<int>(
                      1,
                      (max, m) => [max, m.totalIn.minorUnits, m.totalOut.minorUnits].reduce((a, b) => a > b ? a : b),
                    );
                    final latest = analytics.months.last;
                    return ListView(
                      children: [
                        _SummaryRow(month: latest),
                        const SizedBox(height: TaifaSpacing.xl),
                        Text('LAST ${analytics.months.length} MONTHS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1, color: palette.textMuted)),
                        const SizedBox(height: TaifaSpacing.md),
                        SizedBox(
                          height: 160,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              for (final m in analytics.months)
                                Expanded(child: _MonthBar(month: m, maxValue: maxValue)),
                            ],
                          ),
                        ),
                        const SizedBox(height: TaifaSpacing.xl),
                        Text('THIS MONTH BY TYPE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1, color: palette.textMuted)),
                        const SizedBox(height: TaifaSpacing.sm),
                        if (latest.byType.isEmpty)
                          Text('No spending this month.', style: TextStyle(fontSize: 11, color: palette.textMuted))
                        else
                          for (final entry in (latest.byType.entries.toList()..sort((a, b) => b.value.compareTo(a.value))))
                            Padding(
                              padding: const EdgeInsets.only(bottom: TaifaSpacing.xs),
                              child: SocialCard(
                                child: Row(
                                  children: [
                                    Expanded(child: Text(_typeLabel(entry.key), style: TextStyle(fontSize: 12, color: palette.textPrimary))),
                                    Text(
                                      Money(entry.value, analytics.currency).format(),
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: palette.textPrimary),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _typeLabel(String type) => type.split('_').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.month});
  final SpendingMonth month;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return Row(
      children: [
        Expanded(
          child: SocialCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('IN THIS MONTH', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: palette.textMuted)),
                const SizedBox(height: 4),
                Text(month.totalIn.format(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: TaifaColors.emerald500)),
              ],
            ),
          ),
        ),
        const SizedBox(width: TaifaSpacing.sm),
        Expanded(
          child: SocialCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('OUT THIS MONTH', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: palette.textMuted)),
                const SizedBox(height: 4),
                Text(month.totalOut.format(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: TaifaColors.danger)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MonthBar extends StatelessWidget {
  const _MonthBar({required this.month, required this.maxValue});
  final SpendingMonth month;
  final int maxValue;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final inHeight = 110 * (month.totalIn.minorUnits / maxValue).clamp(0.02, 1.0);
    final outHeight = 110 * (month.totalOut.minorUnits / maxValue).clamp(0.02, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(width: 6, height: inHeight, decoration: BoxDecoration(color: TaifaColors.emerald500, borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 3),
              Container(width: 6, height: outHeight, decoration: BoxDecoration(color: TaifaColors.danger, borderRadius: BorderRadius.circular(3))),
            ],
          ),
          const SizedBox(height: TaifaSpacing.xs),
          Text(
            month.month.length >= 7 ? month.month.substring(5) : month.month,
            style: TextStyle(fontSize: 8, color: palette.textMuted),
          ),
        ],
      ),
    );
  }
}

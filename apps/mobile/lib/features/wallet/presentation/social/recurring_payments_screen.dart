import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/taifa_colors.dart';
import '../../../../app/theme/taifa_dimens.dart';
import '../../../../app/theme/taifa_icons.dart';
import '../../../../app/theme/taifa_theme.dart';
import '../../../../data/dto/social_dto.dart';
import '../../application/social_providers.dart';
import '../../domain/currency.dart';
import '../../domain/money.dart';
import '../../../../shared/widgets/taifa_skeleton.dart';
import '../../../../shared/widgets/taifa_stagger.dart';
import 'social_widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class RecurringPaymentsScreen extends ConsumerWidget {
  const RecurringPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(recurringPaymentsProvider);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: TaifaSpacing.screenH),
          child: Column(
            children: [
              const SizedBox(height: TaifaSpacing.sm),
              SocialScreenHeader(
                title: 'Standing Orders',
                trailing: IconButton(
                  icon: const Icon(LucideIcons.circlePlus),
                  onPressed: () async {
                    final result = await showModalBottomSheet<bool>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: context.taifa.background,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(TaifaRadii.nav))),
                      builder: (_) => const _CreateRecurringSheet(),
                    );
                    if (result == true) ref.invalidate(recurringPaymentsProvider);
                  },
                ),
              ),
              const SizedBox(height: TaifaSpacing.lg),
              Expanded(
                child: asyncList.when(
                  loading: () => const TaifaSkeletonList(),
                  error: (e, _) => Center(child: Text('Could not load standing orders.\n$e', textAlign: TextAlign.center)),
                  data: (items) => items.isEmpty
                      ? const SocialEmptyState(
                          icon: TaifaIcons.standingOrder,
                          title: 'No standing orders',
                          message:
                              'Put rent, allowances or subscriptions on '
                              'autopilot — they run on schedule and pause '
                              'themselves if a payment keeps failing.',
                        )
                      : RefreshIndicator(
                          onRefresh: () async => ref.invalidate(recurringPaymentsProvider),
                          child: ListView.separated(
                            itemCount: items.length,
                            separatorBuilder: (_, _) => const SizedBox(height: TaifaSpacing.sm),
                            itemBuilder: (_, i) =>
                                TaifaStaggerIn(index: i, child: _RecurringTile(item: items[i])),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecurringTile extends ConsumerStatefulWidget {
  const _RecurringTile({required this.item});
  final RecurringPayment item;

  @override
  ConsumerState<_RecurringTile> createState() => _RecurringTileState();
}

class _RecurringTileState extends ConsumerState<_RecurringTile> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final r = widget.item;
    final paused = r.status == RecurringStatus.paused;
    final cancelled = r.status == RecurringStatus.cancelled;
    return SocialCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(r.emoji.isEmpty ? '🔁' : r.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: TaifaSpacing.sm),
              Expanded(child: Text(r.payeeName.isEmpty ? r.payee : r.payeeName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.textPrimary))),
              Text(r.amount.format(), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.textPrimary)),
            ],
          ),
          const SizedBox(height: TaifaSpacing.xxs),
          Text('${_intervalLabel(r.interval)} · next ${_formatDate(r.nextRunAt)}', style: TextStyle(fontSize: 10, color: palette.textMuted)),
          if (r.consecutiveFailures > 0) ...[
            const SizedBox(height: TaifaSpacing.xxs),
            Row(
              children: [
                const Icon(LucideIcons.triangleAlert, size: 12, color: TaifaColors.danger),
                const SizedBox(width: 4),
                Text('${r.consecutiveFailures} failed attempt${r.consecutiveFailures == 1 ? '' : 's'}', style: const TextStyle(fontSize: 10, color: TaifaColors.danger)),
              ],
            ),
          ],
          const SizedBox(height: TaifaSpacing.sm),
          Row(
            children: [
              Text(r.status.name, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: cancelled ? palette.textMuted : (paused ? TaifaColors.gold500 : TaifaColors.emerald500))),
              const Spacer(),
              if (!cancelled) ...[
                TextButton(
                  onPressed: _busy ? null : (paused ? _resume : _pause),
                  child: Text(paused ? 'Resume' : 'Pause', style: TextStyle(fontSize: 11, color: palette.accent)),
                ),
                TextButton(
                  onPressed: _busy ? null : _cancel,
                  child: const Text('Cancel', style: TextStyle(fontSize: 11, color: TaifaColors.danger)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _formatDate(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}';

  String _intervalLabel(RecurringInterval i) => switch (i) {
    RecurringInterval.daily => 'Daily',
    RecurringInterval.weekly => 'Weekly',
    RecurringInterval.monthly => 'Monthly',
  };

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(recurringPaymentsProvider);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showSocialError(context, e);
      }
    }
  }

  Future<void> _pause() => _run(() => ref.read(socialRepositoryProvider).pauseRecurring(widget.item.id));
  Future<void> _resume() => _run(() => ref.read(socialRepositoryProvider).resumeRecurring(widget.item.id));
  Future<void> _cancel() => _run(() => ref.read(socialRepositoryProvider).cancelRecurring(widget.item.id));
}

class _CreateRecurringSheet extends ConsumerStatefulWidget {
  const _CreateRecurringSheet();

  @override
  ConsumerState<_CreateRecurringSheet> createState() => _CreateRecurringSheetState();
}

class _CreateRecurringSheetState extends ConsumerState<_CreateRecurringSheet> {
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  RecurringInterval _interval = RecurringInterval.monthly;
  bool _saving = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return Padding(
      padding: EdgeInsets.only(
        left: TaifaSpacing.screenH,
        right: TaifaSpacing.screenH,
        top: TaifaSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + TaifaSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('New standing order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: palette.textPrimary)),
          const SizedBox(height: TaifaSpacing.lg),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: TextStyle(color: palette.textPrimary),
            decoration: const InputDecoration(labelText: 'Pay to (phone number)', hintText: '+255...'),
          ),
          const SizedBox(height: TaifaSpacing.sm),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(color: palette.textPrimary),
            decoration: const InputDecoration(labelText: 'Amount (TSh)'),
          ),
          const SizedBox(height: TaifaSpacing.sm),
          SegmentedButton<RecurringInterval>(
            segments: const [
              ButtonSegment(value: RecurringInterval.daily, label: Text('Daily')),
              ButtonSegment(value: RecurringInterval.weekly, label: Text('Weekly')),
              ButtonSegment(value: RecurringInterval.monthly, label: Text('Monthly')),
            ],
            selected: {_interval},
            onSelectionChanged: (s) => setState(() => _interval = s.first),
          ),
          const SizedBox(height: TaifaSpacing.sm),
          TextField(
            controller: _noteController,
            style: TextStyle(color: palette.textPrimary),
            decoration: const InputDecoration(labelText: 'Note (optional)', hintText: 'Rent'),
          ),
          const SizedBox(height: TaifaSpacing.md),
          SocialPrimaryButton(label: 'Create standing order', loading: _saving, onTap: _submit),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final phone = _phoneController.text.trim();
    final major = int.tryParse(_amountController.text);
    if (phone.isEmpty || major == null || major <= 0) {
      showSocialError(context, Exception('Enter a phone number and a valid amount.'));
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(socialRepositoryProvider).createRecurring(
        payeePhone: phone,
        amount: Money.major(major, Currency.tzs),
        interval: _interval,
        note: _noteController.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showSocialError(context, e);
      }
    }
  }
}

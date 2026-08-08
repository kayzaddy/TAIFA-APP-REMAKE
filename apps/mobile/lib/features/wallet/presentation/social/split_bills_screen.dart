import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/taifa_colors.dart';
import '../../../../app/theme/taifa_dimens.dart';
import '../../../../app/theme/taifa_theme.dart';
import '../../../../data/dto/social_dto.dart';
import '../../application/social_providers.dart';
import '../../domain/currency.dart';
import '../../domain/money.dart';
import 'social_widgets.dart';

class SplitBillsScreen extends ConsumerWidget {
  const SplitBillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsAsync = ref.watch(billsProvider);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: TaifaSpacing.screenH),
          child: Column(
            children: [
              const SizedBox(height: TaifaSpacing.sm),
              SocialScreenHeader(
                title: 'Split Bills',
                trailing: IconButton(
                  icon: const Icon(Icons.add_circle_rounded),
                  onPressed: () async {
                    final created = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(builder: (_) => const _CreateBillScreen()),
                    );
                    if (created == true) ref.invalidate(billsProvider);
                  },
                ),
              ),
              const SizedBox(height: TaifaSpacing.lg),
              Expanded(
                child: billsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Could not load bills.\n$e', textAlign: TextAlign.center)),
                  data: (data) {
                    final all = [...data.organized, ...data.owing];
                    if (all.isEmpty) {
                      return const SocialEmptyState(icon: Icons.receipt_long_rounded, message: 'No split bills yet.');
                    }
                    return RefreshIndicator(
                      onRefresh: () async => ref.invalidate(billsProvider),
                      child: ListView(
                        children: [
                          if (data.organized.isNotEmpty) ...[
                            _SectionLabel('You organized'),
                            for (final b in data.organized) _BillTile(bill: b),
                            const SizedBox(height: TaifaSpacing.md),
                          ],
                          if (data.owing.isNotEmpty) ...[
                            _SectionLabel('You owe'),
                            for (final b in data.owing) _BillTile(bill: b),
                          ],
                        ],
                      ),
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
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: TaifaSpacing.xs),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1, color: context.taifa.textMuted),
    ),
  );
}

class _BillTile extends StatelessWidget {
  const _BillTile({required this.bill});
  final BillSplit bill;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final progress = bill.totalAmount.minorUnits == 0 ? 0.0 : bill.paidAmount.minorUnits / bill.totalAmount.minorUnits;
    return Padding(
      padding: const EdgeInsets.only(bottom: TaifaSpacing.sm),
      child: SocialCard(
        onTap: () => context.push('/wallet/bills/${bill.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(bill.emoji.isEmpty ? '🧾' : bill.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: TaifaSpacing.sm),
                Expanded(child: Text(bill.title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.textPrimary))),
                Text(bill.totalAmount.format(), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.textPrimary)),
              ],
            ),
            const SizedBox(height: TaifaSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(TaifaRadii.pill),
              child: LinearProgressIndicator(
                value: progress.clamp(0, 1),
                minHeight: 6,
                backgroundColor: palette.surfaceAlt,
                color: bill.status == BillSplitStatus.settled ? TaifaColors.emerald500 : palette.accent,
              ),
            ),
            const SizedBox(height: TaifaSpacing.xxs),
            Text(
              '${bill.paidAmount.format()} of ${bill.totalAmount.format()} · ${bill.shares.length} people',
              style: TextStyle(fontSize: 10, color: palette.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class BillDetailScreen extends ConsumerWidget {
  const BillDetailScreen({super.key, required this.billId});
  final String billId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.taifa;
    final billAsync = ref.watch(billDetailProvider(billId));
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: TaifaSpacing.screenH),
          child: Column(
            children: [
              const SizedBox(height: TaifaSpacing.sm),
              const SocialScreenHeader(title: 'Bill details'),
              const SizedBox(height: TaifaSpacing.lg),
              Expanded(
                child: billAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Could not load bill.\n$e')),
                  data: (bill) => ListView(
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Text(bill.emoji.isEmpty ? '🧾' : bill.emoji, style: const TextStyle(fontSize: 40)),
                            const SizedBox(height: TaifaSpacing.sm),
                            Text(bill.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: palette.textPrimary)),
                            Text('Organized by ${bill.organizerName}', style: TextStyle(fontSize: 11, color: palette.textMuted)),
                            const SizedBox(height: TaifaSpacing.xs),
                            Text(bill.totalAmount.format(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: palette.textPrimary)),
                          ],
                        ),
                      ),
                      const SizedBox(height: TaifaSpacing.xl),
                      _SectionLabel('Shares'),
                      for (final share in bill.shares)
                        Padding(
                          padding: const EdgeInsets.only(bottom: TaifaSpacing.xs),
                          child: SocialCard(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(share.payerName.isEmpty ? share.payer : share.payerName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: palette.textPrimary)),
                                      Text(share.amount.format(), style: TextStyle(fontSize: 11, color: palette.textMuted)),
                                    ],
                                  ),
                                ),
                                _StatusPill(status: share.status),
                              ],
                            ),
                          ),
                        ),
                      if (bill.status == BillSplitStatus.open) ...[
                        const SizedBox(height: TaifaSpacing.lg),
                        TextButton(
                          onPressed: () async {
                            try {
                              await ref.read(socialRepositoryProvider).cancelBill(bill.id);
                              ref.invalidate(billDetailProvider(billId));
                              ref.invalidate(billsProvider);
                            } catch (e) {
                              if (context.mounted) showSocialError(context, e);
                            }
                          },
                          child: const Text('Cancel this bill', style: TextStyle(color: TaifaColors.danger)),
                        ),
                      ],
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
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final MoneyRequestStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      MoneyRequestStatus.pending => ('Pending', TaifaColors.gold500),
      MoneyRequestStatus.paid => ('Paid', TaifaColors.emerald500),
      _ => (status.name, context.taifa.textMuted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(TaifaRadii.pill)),
      child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _CreateBillScreen extends ConsumerStatefulWidget {
  const _CreateBillScreen();

  @override
  ConsumerState<_CreateBillScreen> createState() => _CreateBillScreenState();
}

class _CreateBillScreenState extends ConsumerState<_CreateBillScreen> {
  final _titleController = TextEditingController();
  final _totalController = TextEditingController();
  final List<TextEditingController> _phoneControllers = [TextEditingController()];
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _totalController.dispose();
    for (final c in _phoneControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: TaifaSpacing.screenH),
          child: Column(
            children: [
              const SizedBox(height: TaifaSpacing.sm),
              const SocialScreenHeader(title: 'Split a bill'),
              const SizedBox(height: TaifaSpacing.lg),
              Expanded(
                child: ListView(
                  children: [
                    TextField(
                      controller: _titleController,
                      style: TextStyle(color: palette.textPrimary),
                      decoration: const InputDecoration(labelText: 'What is this for?', hintText: 'Dinner at Slipway'),
                    ),
                    const SizedBox(height: TaifaSpacing.sm),
                    TextField(
                      controller: _totalController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: TextStyle(color: palette.textPrimary),
                      decoration: const InputDecoration(labelText: 'Total amount (TSh)'),
                    ),
                    const SizedBox(height: TaifaSpacing.lg),
                    Text('Split evenly with', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: palette.textPrimary)),
                    Text('You are automatically included in the split.', style: TextStyle(fontSize: 10, color: palette.textMuted)),
                    const SizedBox(height: TaifaSpacing.sm),
                    for (var i = 0; i < _phoneControllers.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: TaifaSpacing.xs),
                        child: TextField(
                          controller: _phoneControllers[i],
                          keyboardType: TextInputType.phone,
                          style: TextStyle(color: palette.textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Phone number',
                            suffixIcon: _phoneControllers.length > 1
                                ? IconButton(
                                    icon: const Icon(Icons.close_rounded, size: 16),
                                    onPressed: () => setState(() => _phoneControllers.removeAt(i).dispose()),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    TextButton.icon(
                      onPressed: () => setState(() => _phoneControllers.add(TextEditingController())),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Add participant'),
                    ),
                  ],
                ),
              ),
              SocialPrimaryButton(label: 'Split the bill', loading: _saving, onTap: _submit),
              const SizedBox(height: TaifaSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final total = int.tryParse(_totalController.text);
    final phones = _phoneControllers.map((c) => c.text.trim()).where((p) => p.isNotEmpty).toList();
    if (title.isEmpty || total == null || total <= 0 || phones.isEmpty) {
      showSocialError(context, Exception('Add a title, a total amount, and at least one participant.'));
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(socialRepositoryProvider).createBill(
        title: title,
        currency: Currency.tzs,
        totalAmount: Money.major(total, Currency.tzs),
        evenSplit: true,
        participants: [for (final p in phones) (payer: null, phone: p, amount: null)],
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

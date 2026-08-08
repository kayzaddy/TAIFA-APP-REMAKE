import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/taifa_colors.dart';
import '../../../../app/theme/taifa_dimens.dart';
import '../../../../app/theme/taifa_theme.dart';
import '../../../../data/dto/social_dto.dart';
import '../../application/social_providers.dart';
import '../../application/wallet_providers.dart';
import '../../domain/currency.dart';
import '../../domain/money.dart';
import 'social_widgets.dart';

class PaymentLinksScreen extends ConsumerWidget {
  const PaymentLinksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksAsync = ref.watch(paymentLinksProvider);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: TaifaSpacing.screenH),
          child: Column(
            children: [
              const SizedBox(height: TaifaSpacing.sm),
              SocialScreenHeader(
                title: 'Payment Links',
                trailing: IconButton(
                  icon: const Icon(Icons.add_circle_rounded),
                  onPressed: () => _createLink(context, ref),
                ),
              ),
              const SizedBox(height: TaifaSpacing.lg),
              Expanded(
                child: linksAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Could not load links.\n$e', textAlign: TextAlign.center)),
                  data: (links) => links.isEmpty
                      ? const SocialEmptyState(
                          icon: Icons.link_rounded,
                          message: 'No payment links yet.\nCreate one to start collecting money.',
                        )
                      : RefreshIndicator(
                          onRefresh: () async => ref.invalidate(paymentLinksProvider),
                          child: ListView.separated(
                            itemCount: links.length,
                            separatorBuilder: (_, _) => const SizedBox(height: TaifaSpacing.sm),
                            itemBuilder: (_, i) => _LinkTile(link: links[i]),
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

  Future<void> _createLink(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.taifa.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(TaifaRadii.nav)),
      ),
      builder: (_) => const _CreateLinkSheet(),
    );
    if (result == true) ref.invalidate(paymentLinksProvider);
  }
}

class _LinkTile extends ConsumerWidget {
  const _LinkTile({required this.link});
  final PaymentLink link;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.taifa;
    final paused = link.status == PaymentLinkStatus.paused;
    return SocialCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(link.emoji.isEmpty ? '🔗' : link.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: TaifaSpacing.sm),
              Expanded(
                child: Text(
                  link.note.isEmpty ? (link.amount?.format() ?? 'Any amount') : link.note,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.textPrimary),
                ),
              ),
              _StatusChip(status: link.status),
            ],
          ),
          const SizedBox(height: TaifaSpacing.xs),
          Text(
            link.amount?.format() ?? 'Open amount',
            style: TextStyle(fontSize: 11, color: palette.textMuted),
          ),
          const SizedBox(height: TaifaSpacing.xs),
          Text(
            'taifa.app/pay/${link.slug}',
            style: TextStyle(fontSize: 10, color: palette.textSecondary, fontFamily: 'monospace'),
          ),
          const SizedBox(height: TaifaSpacing.sm),
          Row(
            children: [
              Text(
                'Collected ${link.totalPaid.format()} · ${link.paymentCount} payment${link.paymentCount == 1 ? '' : 's'}',
                style: TextStyle(fontSize: 10, color: palette.textMuted),
              ),
              const Spacer(),
              if (link.status == PaymentLinkStatus.active || paused)
                TextButton(
                  onPressed: () => _toggle(context, ref, paused),
                  child: Text(paused ? 'Resume' : 'Pause', style: TextStyle(fontSize: 11, color: palette.accent)),
                ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 16),
                tooltip: 'Copy link',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: 'taifa.app/pay/${link.slug}'));
                  showSocialSuccess(context, 'Link copied.');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _toggle(BuildContext context, WidgetRef ref, bool paused) async {
    final repo = ref.read(socialRepositoryProvider);
    try {
      await (paused ? repo.resumeLink(link.id) : repo.pauseLink(link.id));
      ref.invalidate(paymentLinksProvider);
    } catch (e) {
      if (context.mounted) showSocialError(context, e);
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final PaymentLinkStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      PaymentLinkStatus.active => ('Active', TaifaColors.emerald500),
      PaymentLinkStatus.paused => ('Paused', TaifaColors.gold500),
      PaymentLinkStatus.completed => ('Completed', context.taifa.textMuted),
      PaymentLinkStatus.expired => ('Expired', TaifaColors.danger),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(TaifaRadii.pill)),
      child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _CreateLinkSheet extends ConsumerStatefulWidget {
  const _CreateLinkSheet();

  @override
  ConsumerState<_CreateLinkSheet> createState() => _CreateLinkSheetState();
}

class _CreateLinkSheetState extends ConsumerState<_CreateLinkSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  bool _openAmount = false;
  bool _singleUse = false;
  bool _saving = false;

  @override
  void dispose() {
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
          Text('New payment link', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: palette.textPrimary)),
          const SizedBox(height: TaifaSpacing.lg),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _openAmount,
            onChanged: (v) => setState(() => _openAmount = v),
            title: Text('Open amount', style: TextStyle(fontSize: 12, color: palette.textPrimary)),
            subtitle: Text('Payer chooses how much to pay', style: TextStyle(fontSize: 10, color: palette.textMuted)),
          ),
          if (!_openAmount)
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(color: palette.textPrimary),
              decoration: const InputDecoration(labelText: 'Amount (TSh)'),
            ),
          const SizedBox(height: TaifaSpacing.sm),
          TextField(
            controller: _noteController,
            style: TextStyle(color: palette.textPrimary),
            decoration: const InputDecoration(labelText: 'Note (optional)'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _singleUse,
            onChanged: (v) => setState(() => _singleUse = v),
            title: Text('Single use', style: TextStyle(fontSize: 12, color: palette.textPrimary)),
            subtitle: Text('Link deactivates after one payment', style: TextStyle(fontSize: 10, color: palette.textMuted)),
          ),
          const SizedBox(height: TaifaSpacing.md),
          SocialPrimaryButton(label: 'Create link', loading: _saving, onTap: _submit),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final major = int.tryParse(_amountController.text);
    if (!_openAmount && (major == null || major <= 0)) {
      showSocialError(context, Exception('Enter a valid amount.'));
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(socialRepositoryProvider).createLink(
        amount: _openAmount ? null : Money.major(major!, Currency.tzs),
        currency: Currency.tzs,
        note: _noteController.text.trim(),
        singleUse: _singleUse,
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

/// The public "pay a link" screen — reachable via `/wallet/pay/:slug`, works
/// whether or not the current user owns the link (matches
/// `GET /payments/pay/{slug}` being unauthenticated).
class PayLinkScreen extends ConsumerStatefulWidget {
  const PayLinkScreen({super.key, required this.slug});
  final String slug;

  @override
  ConsumerState<PayLinkScreen> createState() => _PayLinkScreenState();
}

class _PayLinkScreenState extends ConsumerState<PayLinkScreen> {
  PaymentLinkPreview? _preview;
  Object? _error;
  bool _paying = false;
  final _customAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final preview = await ref.read(socialRepositoryProvider).previewLink(widget.slug);
      if (mounted) setState(() => _preview = preview);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  void dispose() {
    _customAmountController.dispose();
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
              const SocialScreenHeader(title: 'Pay'),
              const SizedBox(height: TaifaSpacing.xxl),
              if (_error != null)
                Expanded(child: Center(child: Text('This link is not available.\n$_error', textAlign: TextAlign.center)))
              else if (_preview == null)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else
                Expanded(
                  child: Column(
                    children: [
                      Text(_preview!.emoji.isEmpty ? '💸' : _preview!.emoji, style: const TextStyle(fontSize: 48)),
                      const SizedBox(height: TaifaSpacing.md),
                      Text('Pay ${_preview!.payee}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: palette.textPrimary)),
                      if (_preview!.note.isNotEmpty) ...[
                        const SizedBox(height: TaifaSpacing.xs),
                        Text(_preview!.note, style: TextStyle(fontSize: 12, color: palette.textMuted)),
                      ],
                      const SizedBox(height: TaifaSpacing.xl),
                      if (_preview!.amount != null)
                        Text(_preview!.amount!.format(), style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: palette.textPrimary))
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: TaifaSpacing.xxl),
                          child: TextField(
                            controller: _customAmountController,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            style: TextStyle(fontSize: 24, color: palette.textPrimary),
                            decoration: const InputDecoration(prefixText: 'TSh ', hintText: 'Amount'),
                          ),
                        ),
                      const Spacer(),
                      SocialPrimaryButton(
                        label: 'Pay now',
                        loading: _paying,
                        enabled: _preview!.status == PaymentLinkStatus.active,
                        onTap: _pay,
                      ),
                      const SizedBox(height: TaifaSpacing.md),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pay() async {
    Money? amount;
    if (_preview!.amount == null) {
      final major = int.tryParse(_customAmountController.text);
      if (major == null || major <= 0) {
        showSocialError(context, Exception('Enter a valid amount.'));
        return;
      }
      amount = Money.major(major, _preview!.currency);
    }
    setState(() => _paying = true);
    try {
      final txn = await ref.read(socialRepositoryProvider).payLink(widget.slug, amount: amount);
      ref.invalidate(walletControllerProvider);
      if (mounted) {
        showSocialSuccess(context, 'Paid ${txn.amount.format()}.');
        Navigator.of(context).maybePop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _paying = false);
        showSocialError(context, e);
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../../../app/theme/taifa_theme.dart';
import '../../../app/theme/taifa_typography.dart';
import '../application/wallet_providers.dart';
import '../domain/currency.dart';
import '../domain/money.dart';
import '../domain/recipient.dart';

class SendMoneyScreen extends ConsumerStatefulWidget {
  const SendMoneyScreen({super.key});

  @override
  ConsumerState<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends ConsumerState<SendMoneyScreen> {
  static const _quickAmounts = [10000, 50000, 100000, 250000, 500000];

  Recipient? _recipient;
  int _amountMajor = 250000; // TZS, matches the mockup default
  bool _sending = false;
  final _noteController = TextEditingController(
    text: 'For school fees · January term',
  );

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Money get _amount => Money.major(_amountMajor, Currency.tzs);

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final walletState = ref.watch(walletControllerProvider).value;
    final recipients = walletState?.snapshot?.recipients ?? const <Recipient>[];
    _recipient ??= recipients.isNotEmpty ? recipients.first : null;
    final engine = ref.watch(currencyEngineProvider);
    final usdEstimate = engine.convert(_amount, Currency.usd);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: TaifaSpacing.screenH),
          child: Column(
            children: [
              const SizedBox(height: TaifaSpacing.sm),
              Row(
                children: [
                  _CircleButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => context.go('/wallet'),
                  ),
                  const SizedBox(width: TaifaSpacing.md),
                  Text(
                    'Send Money',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: palette.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TaifaSpacing.xl),
              Expanded(
                child: ListView(
                  children: [
                    _RecipientHeader(
                      recipient: _recipient,
                      onTap: recipients.length > 1
                          ? () => _pickRecipient(recipients)
                          : null,
                    ),
                    const SizedBox(height: TaifaSpacing.xl),
                    _AmountDisplay(amount: _amount, usdEstimate: usdEstimate),
                    const SizedBox(height: TaifaSpacing.lg),
                    _QuickAmounts(
                      values: _quickAmounts,
                      selected: _amountMajor,
                      onSelected: (v) => setState(() => _amountMajor = v),
                      onCustom: _promptCustomAmount,
                    ),
                    const SizedBox(height: TaifaSpacing.md),
                    _SourceRow(walletState: walletState),
                    const SizedBox(height: TaifaSpacing.sm),
                    _NoteField(controller: _noteController),
                  ],
                ),
              ),
              _ConfirmButton(
                sending: _sending,
                enabled: _recipient != null && !_sending,
                onTap: _confirmSend,
              ),
              const SizedBox(height: TaifaSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickRecipient(List<Recipient> recipients) async {
    final palette = context.taifa;
    final chosen = await showModalBottomSheet<Recipient>(
      context: context,
      backgroundColor: palette.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(TaifaRadii.nav),
        ),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: TaifaSpacing.md),
            Text(
              'Send to',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: TaifaSpacing.sm),
            for (final r in recipients)
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: TaifaColors.gold500.withValues(alpha: 0.2),
                  child: Text(
                    r.initial,
                    style: const TextStyle(
                      color: TaifaColors.gold400,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                title: Text(
                  r.name,
                  style: TextStyle(color: palette.textPrimary),
                ),
                subtitle: Text(
                  r.method.subtitle,
                  style: TextStyle(color: palette.textMuted, fontSize: 11),
                ),
                trailing: r.verified
                    ? const Icon(
                        Icons.verified_rounded,
                        size: 16,
                        color: TaifaColors.emerald500,
                      )
                    : null,
                onTap: () => Navigator.of(context).pop(r),
              ),
          ],
        ),
      ),
    );
    if (chosen != null) setState(() => _recipient = chosen);
  }

  Future<void> _promptCustomAmount() async {
    final palette = context.taifa;
    final controller = TextEditingController(text: '$_amountMajor');
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: palette.background,
        title: Text(
          'Custom amount (TSh)',
          style: TextStyle(color: palette.textPrimary, fontSize: 16),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(color: palette.textPrimary),
          decoration: const InputDecoration(prefixText: 'TSh '),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(
              context,
              int.tryParse(controller.text) ?? _amountMajor,
            ),
            child: const Text('Set'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null && result > 0) setState(() => _amountMajor = result);
  }

  Future<void> _confirmSend() async {
    final recipient = _recipient;
    if (recipient == null) return;
    setState(() => _sending = true);

    final result = await ref
        .read(walletControllerProvider.notifier)
        .sendMoney(
          recipient: recipient,
          amount: _amount,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _sending = false);

    switch (result) {
      case SendSuccess(:final transaction):
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              backgroundColor: TaifaColors.emerald700,
              content: Text(
                'Sent ${transaction.amount.format()} to ${transaction.counterparty}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        context.go('/wallet');
      case SendFailure(:final message):
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              backgroundColor: TaifaColors.danger,
              content: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
    }
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: palette.surface,
          border: Border.all(color: palette.border),
        ),
        child: Icon(icon, size: 18, color: palette.textPrimary),
      ),
    );
  }
}

class _RecipientHeader extends StatelessWidget {
  const _RecipientHeader({required this.recipient, this.onTap});
  final Recipient? recipient;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final r = recipient;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: TaifaColors.goldGradient,
              border: Border.all(
                color: TaifaColors.gold500.withValues(alpha: 0.3),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: TaifaColors.gold500.withValues(alpha: 0.3),
                  blurRadius: 30,
                ),
              ],
            ),
            child: Text(
              r?.initial ?? '?',
              style: TaifaTypography.balance(
                TaifaColors.black900,
              ).copyWith(fontSize: 30),
            ),
          ),
          const SizedBox(height: TaifaSpacing.sm),
          Text(
            r?.name ?? 'Select recipient',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            r == null ? '' : '${r.handle}${r.verified ? ' · Verified ✓' : ''}',
            style: TextStyle(fontSize: 10, color: palette.textMuted),
          ),
          if (onTap != null) ...[
            const SizedBox(height: 4),
            Text(
              'Change ▾',
              style: TextStyle(fontSize: 10, color: palette.accent),
            ),
          ],
        ],
      ),
    );
  }
}

class _AmountDisplay extends StatelessWidget {
  const _AmountDisplay({required this.amount, required this.usdEstimate});
  final Money amount;
  final Money usdEstimate;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return Column(
      children: [
        Text('YOU SEND', style: TaifaTypography.eyebrow(palette.textMuted)),
        const SizedBox(height: TaifaSpacing.sm),
        ShaderMask(
          shaderCallback: (bounds) =>
              TaifaColors.wordmarkGradient.createShader(bounds),
          child: Text(
            amount.format(),
            style: TaifaTypography.balance(Colors.white).copyWith(fontSize: 44),
          ),
        ),
        const SizedBox(height: TaifaSpacing.xs),
        Text(
          '≈ ${usdEstimate.format()} · Fee: ${Money.zero(amount.currency).format()}',
          style: TextStyle(fontSize: 11, color: palette.textMuted),
        ),
      ],
    );
  }
}

class _QuickAmounts extends StatelessWidget {
  const _QuickAmounts({
    required this.values,
    required this.selected,
    required this.onSelected,
    required this.onCustom,
  });
  final List<int> values;
  final int selected;
  final ValueChanged<int> onSelected;
  final VoidCallback onCustom;

  String _label(int v) => v >= 1000 ? '${v ~/ 1000}K' : '$v';

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final items = [...values.map((v) => (_label(v), v)), ('Custom', -1)];
    return Container(
      padding: const EdgeInsets.all(TaifaSpacing.md),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(TaifaRadii.xl),
        border: Border.all(color: palette.border),
      ),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: TaifaSpacing.xs,
        crossAxisSpacing: TaifaSpacing.xs,
        childAspectRatio: 2.6,
        children: [
          for (final (label, value) in items)
            GestureDetector(
              onTap: () => value == -1 ? onCustom() : onSelected(value),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: value == selected
                      ? TaifaColors.gold500.withValues(alpha: 0.12)
                      : palette.surfaceAlt,
                  borderRadius: BorderRadius.circular(TaifaRadii.sm),
                  border: Border.all(
                    color: value == selected
                        ? TaifaColors.gold500.withValues(alpha: 0.3)
                        : Colors.transparent,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: value == selected
                        ? FontWeight.w700
                        : FontWeight.w600,
                    color: value == selected
                        ? palette.accent
                        : palette.textMuted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({required this.walletState});
  final WalletState? walletState;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final source = walletState?.snapshot?.sources.first;
    final balance = walletState?.snapshot?.balance;
    return Container(
      padding: const EdgeInsets.all(TaifaSpacing.md),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(TaifaRadii.lg),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 24,
            decoration: BoxDecoration(
              gradient: TaifaColors.goldGradient,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: TaifaSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  source?.label ?? 'Source',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                ),
                Text(
                  balance == null ? '' : 'Balance ${balance.format()}',
                  style: TextStyle(fontSize: 9, color: palette.textMuted),
                ),
              ],
            ),
          ),
          Text(
            'Change ▾',
            style: TextStyle(fontSize: 10, color: palette.accent),
          ),
        ],
      ),
    );
  }
}

class _NoteField extends StatelessWidget {
  const _NoteField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TaifaSpacing.md,
        vertical: TaifaSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(TaifaRadii.md),
        border: Border.all(color: palette.border, style: BorderStyle.solid),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NOTE',
            style: TaifaTypography.eyebrow(
              palette.textMuted,
            ).copyWith(letterSpacing: 1.2),
          ),
          TextField(
            controller: controller,
            maxLines: 1,
            style: TextStyle(fontSize: 11, color: palette.textSecondary),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 4),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({
    required this.sending,
    required this.enabled,
    required this.onTap,
  });
  final bool sending;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: TaifaMotion.fast,
        opacity: enabled ? 1 : 0.5,
        child: Container(
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: TaifaColors.goldGradient,
            borderRadius: BorderRadius.circular(TaifaRadii.xl),
            boxShadow: [
              BoxShadow(
                color: TaifaColors.gold500.withValues(alpha: 0.35),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: sending
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
              : const Text(
                  'Confirm with Face ID · Send →',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: Colors.black,
                  ),
                ),
        ),
      ),
    );
  }
}

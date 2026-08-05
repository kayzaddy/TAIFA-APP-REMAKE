import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../../../app/theme/taifa_theme.dart';
import '../application/wallet_providers.dart';
import '../domain/currency.dart';
import '../domain/money.dart';
import '../domain/payment_method.dart';
import '../domain/transaction.dart';

/// Top-up via M-Pesa STK — additive Wallet flow. Seed auto-settles; remote
/// returns `processing` until the Daraja webhook credits the ledger.
class TopUpScreen extends ConsumerStatefulWidget {
  const TopUpScreen({super.key});

  @override
  ConsumerState<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends ConsumerState<TopUpScreen> {
  static const _quickAmounts = [10000, 50000, 100000, 250000, 500000];

  MobileMoneyMethod? _source;
  int _amountMajor = 50000;
  bool _busy = false;
  TopUpSuccess? _done;
  String? _error;
  final _note = TextEditingController(text: 'Wallet top-up');

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Money get _amount => Money.major(_amountMajor, Currency.tzs);

  List<MobileMoneyMethod> _sources(WalletState? wallet) {
    final methods = wallet?.snapshot?.sources ?? const <PaymentMethod>[];
    return methods.whereType<MobileMoneyMethod>().toList();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final walletState = ref.watch(walletControllerProvider).value;
    final sources = _sources(walletState);
    _source ??= sources.isNotEmpty ? sources.first : null;
    final engine = ref.watch(currencyEngineProvider);
    final usdEstimate = engine.convert(_amount, Currency.usd);

    if (_done != null) {
      return _ResultView(
        success: _done!,
        onRefresh: () async {
          await ref.read(walletControllerProvider.notifier).refresh();
          if (!context.mounted) return;
          context.go('/wallet');
        },
        onHome: () => context.go('/wallet'),
        onPollStatus: () async {
          final result = await ref
              .read(walletControllerProvider.notifier)
              .pollTopUpStatus(_done!.transaction.id);
          if (!mounted) return;
          switch (result) {
            case TopUpSuccess():
              setState(() => _done = result);
              if (!result.settled) {
                throw Exception('Still waiting for M-Pesa PIN confirmation.');
              }
            case TopUpFailure(:final message):
              throw Exception(message);
          }
        },
        onDemoComplete: () async {
          final result = await ref
              .read(walletControllerProvider.notifier)
              .completeDemoTopUp(_done!.transaction.id);
          if (!mounted) return;
          switch (result) {
            case TopUpSuccess():
              setState(() => _done = result);
            case TopUpFailure(:final message):
              throw Exception(message);
          }
        },
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: TaifaSpacing.screenH),
          child: Column(
            children: [
              const SizedBox(height: TaifaSpacing.sm),
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/wallet'),
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: palette.textPrimary,
                    ),
                  ),
                  Text(
                    'Top Up',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: palette.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TaifaSpacing.md),
              Expanded(
                child: ListView(
                  children: [
                    Text(
                      'Fund from mobile money',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'STK push to your phone · settles into TAIFA Wallet',
                      style: TextStyle(color: palette.textMuted, fontSize: 12),
                    ),
                    const SizedBox(height: TaifaSpacing.lg),
                    Text(
                      _amount.format(),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                        fontSize: 32,
                      ),
                    ),
                    Text(
                      '≈ ${usdEstimate.format()}',
                      style: TextStyle(color: palette.textMuted, fontSize: 12),
                    ),
                    const SizedBox(height: TaifaSpacing.md),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _quickAmounts
                          .map(
                            (v) => ChoiceChip(
                              label: Text(
                                Money.major(v, Currency.tzs).format(),
                              ),
                              selected: _amountMajor == v,
                              onSelected: (_) =>
                                  setState(() => _amountMajor = v),
                            ),
                          )
                          .toList(),
                    ),
                    TextButton(
                      onPressed: _promptCustom,
                      child: const Text('Custom amount'),
                    ),
                    const SizedBox(height: TaifaSpacing.md),
                    Text(
                      'From',
                      style: TextStyle(color: palette.textMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    ...sources.map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: _source?.id == s.id
                              ? TaifaColors.emerald500.withValues(alpha: 0.15)
                              : palette.surface,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            onTap: () => setState(() => _source = s),
                            borderRadius: BorderRadius.circular(14),
                            child: ListTile(
                              title: Text(
                                s.label,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: palette.textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                '${s.operator.displayName} · ${s.msisdn}',
                                style: TextStyle(
                                  color: palette.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                              trailing: Icon(
                                _source?.id == s.id
                                    ? Icons.check_circle_rounded
                                    : Icons.circle_outlined,
                                color: _source?.id == s.id
                                    ? TaifaColors.emerald500
                                    : palette.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (sources.isEmpty)
                      Text(
                        'No mobile-money source on this profile.',
                        style: TextStyle(color: palette.textMuted),
                      ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _note,
                      decoration: const InputDecoration(labelText: 'Note'),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: TaifaColors.danger,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              FilledButton(
                onPressed: _busy || _source == null ? null : _confirm,
                style: FilledButton.styleFrom(
                  backgroundColor: TaifaColors.emerald700,
                  minimumSize: const Size.fromHeight(52),
                ),
                child: Text(
                  _busy ? 'Sending STK…' : 'Top up ${_amount.format()}',
                ),
              ),
              const SizedBox(height: TaifaSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _promptCustom() async {
    final controller = TextEditingController(text: '$_amountMajor');
    final value = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Amount (TZS)'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, int.tryParse(controller.text)),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (value != null && value > 0) setState(() => _amountMajor = value);
  }

  Future<void> _confirm() async {
    final source = _source;
    if (source == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref
        .read(walletControllerProvider.notifier)
        .topUp(
          amount: _amount,
          source: source,
          note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        );
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case TopUpSuccess():
        setState(() => _done = result);
      case TopUpFailure(:final message):
        setState(() => _error = message);
    }
  }
}

class _ResultView extends StatefulWidget {
  const _ResultView({
    required this.success,
    required this.onRefresh,
    required this.onHome,
    required this.onPollStatus,
    required this.onDemoComplete,
  });

  final TopUpSuccess success;
  final VoidCallback onRefresh;
  final VoidCallback onHome;
  final Future<void> Function() onPollStatus;
  final Future<void> Function() onDemoComplete;

  @override
  State<_ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends State<_ResultView> {
  bool _busy = false;
  String? _error;

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final success = widget.success;
    final pending =
        success.transaction.status == TransactionStatus.processing ||
        !success.settled;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pending ? 'STK sent' : 'Top-up complete',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: palette.textPrimary,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                pending
                    ? 'Enter your M-Pesa PIN on the phone, then check status. '
                          'Demo settle remains available when Daraja is offline.'
                    : '${success.transaction.amount.format()} added to your wallet.',
                style: TextStyle(color: palette.textMuted, height: 1.4),
              ),
              const SizedBox(height: 12),
              Text(
                success.transaction.counterparty,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
              ),
              if (success.transaction.providerRef != null)
                Text(
                  'Ref · ${success.transaction.providerRef}',
                  style: TextStyle(color: palette.textMuted, fontSize: 12),
                ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: TaifaColors.danger,
                    fontSize: 13,
                  ),
                ),
              ],
              const Spacer(),
              if (pending) ...[
                FilledButton(
                  onPressed: _busy ? null : () => _run(widget.onPollStatus),
                  style: FilledButton.styleFrom(
                    backgroundColor: TaifaColors.emerald700,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(_busy ? 'Checking…' : "I've entered my PIN"),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: _busy ? null : () => _run(widget.onDemoComplete),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('Confirm PIN (demo)'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: widget.onRefresh,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('Refresh wallet'),
                ),
              ] else
                FilledButton(
                  onPressed: widget.onHome,
                  style: FilledButton.styleFrom(
                    backgroundColor: TaifaColors.emerald700,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('Back to Wallet'),
                ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: widget.onHome,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

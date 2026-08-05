import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../application/tap_providers.dart';

/// Tap & Pay — NFC interaction layer over MAP + Payments.
class TapPayScreen extends ConsumerStatefulWidget {
  const TapPayScreen({super.key});

  @override
  ConsumerState<TapPayScreen> createState() => _TapPayScreenState();
}

class _TapPayScreenState extends ConsumerState<TapPayScreen> {
  final _amount = TextEditingController(text: '2500');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tapPayControllerProvider.notifier).loadPrefs();
    });
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tapPayControllerProvider);
    final ctrl = ref.read(tapPayControllerProvider.notifier);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final session = state.session;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tap & Pay'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => context.push('/tap/funding'),
            child: const Text('Funding'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(TaifaSpacing.screenH),
        children: [
          Text(
            'One tap. One confirmation. Done.',
            style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: TaifaSpacing.sm),
          Text(
            'Contactless payments via Taifa Wallet — ledger-backed by Taifa Payments. No second payment engine.',
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: TaifaSpacing.xl),
          _NfcPad(phase: state.phase),
          const SizedBox(height: TaifaSpacing.lg),
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Amount (minor units)',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => ctrl.setAmount(int.tryParse(v) ?? 0),
          ),
          const SizedBox(height: TaifaSpacing.md),
          if (state.prefs != null) ...[
            Text('Preferred source', style: text.titleSmall),
            Text(
              state.prefs!.priority.isEmpty
                  ? '—'
                  : state.prefs!.priority.first.label,
              style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: TaifaSpacing.md),
          ],
          if (state.phase == TapPhase.ready || state.phase == TapPhase.failed) ...[
            FilledButton.icon(
              onPressed: state.isBusy
                  ? null
                  : () {
                      ctrl.setAmount(int.tryParse(_amount.text) ?? 2500);
                      HapticFeedback.mediumImpact();
                      ctrl.simulateTap();
                    },
              icon: const Icon(Icons.contactless),
              label: Text(state.isBusy ? 'Working…' : 'Simulate NFC tap'),
            ),
          ],
          if (state.phase == TapPhase.auth) ...[
            Text(
              'Authenticate',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text('${session?.merchantDisplay} · ${session?.amountMinor} ${session?.currency}'),
            const SizedBox(height: TaifaSpacing.sm),
            FilledButton.icon(
              onPressed: state.isBusy
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      ctrl.authenticate(method: 'biometric');
                    },
              icon: const Icon(Icons.fingerprint),
              label: const Text('Use biometric'),
            ),
            OutlinedButton(
              onPressed: state.isBusy ? null : () => ctrl.authenticate(method: 'pin'),
              child: const Text('Use wallet PIN'),
            ),
          ],
          if (state.phase == TapPhase.success && session != null) ...[
            Container(
              padding: const EdgeInsets.all(TaifaSpacing.lg),
              decoration: BoxDecoration(
                color: TaifaColors.emerald700.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Paid', style: text.headlineSmall?.copyWith(color: TaifaColors.emerald700)),
                  Text('${session.amountMinor} ${session.currency}'),
                  Text(session.merchantDisplay),
                  Text('Via ${session.selectedFunding?.label ?? 'Wallet'}'),
                  Text('Ref ${session.paymentRef}', style: text.bodySmall),
                  if (session.receiptCode.isNotEmpty)
                    Text('Receipt ${session.receiptCode}', style: text.labelSmall),
                ],
              ),
            ),
            const SizedBox(height: TaifaSpacing.md),
            OutlinedButton(onPressed: ctrl.reset, child: const Text('New tap')),
            TextButton(
              onPressed: () => context.push('/wallet'),
              child: const Text('Open wallet'),
            ),
          ],
          if (state.phase == TapPhase.fallback) ...[
            Text(
              'Choose another funding source',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(state.message ?? state.error ?? 'Insufficient wallet balance'),
            const SizedBox(height: TaifaSpacing.sm),
            FilledButton(
              onPressed: () => context.push('/wallet/topup'),
              child: const Text('Top up wallet'),
            ),
            OutlinedButton(onPressed: ctrl.reset, child: const Text('Try again')),
          ],
          if (state.error != null && state.phase == TapPhase.failed) ...[
            const SizedBox(height: TaifaSpacing.md),
            Text(state.error!, style: TextStyle(color: scheme.error)),
            OutlinedButton(onPressed: ctrl.reset, child: const Text('Reset')),
          ],
          if (state.message != null && state.phase == TapPhase.detecting) ...[
            const SizedBox(height: TaifaSpacing.md),
            Text(state.message!),
          ],
          const SizedBox(height: TaifaSpacing.xl),
          Text(
            'Hardware NFC / SoftPOS attestation is future-ready. Capture always uses MAP pay_intent → Taifa Payments.',
            style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _NfcPad extends StatelessWidget {
  const _NfcPad({required this.phase});

  final TapPhase phase;

  @override
  Widget build(BuildContext context) {
    final color = switch (phase) {
      TapPhase.success => TaifaColors.emerald600,
      TapPhase.auth || TapPhase.detecting => TaifaColors.ocean500,
      TapPhase.fallback || TapPhase.failed => TaifaColors.dangerSoft,
      _ => TaifaColors.ocean400,
    };
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 2),
        color: color.withValues(alpha: 0.08),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.contactless, size: 72, color: color),
            const SizedBox(height: 8),
            Text(
              switch (phase) {
                TapPhase.ready => 'Hold near terminal',
                TapPhase.detecting => 'Reading…',
                TapPhase.auth => 'Confirm it\'s you',
                TapPhase.success => 'Done',
                TapPhase.fallback => 'Need funding',
                TapPhase.failed => 'Try again',
              },
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

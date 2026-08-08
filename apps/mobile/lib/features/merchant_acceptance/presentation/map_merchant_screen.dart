import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../application/map_providers.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MapMerchantScreen extends ConsumerStatefulWidget {
  const MapMerchantScreen({super.key});

  @override
  ConsumerState<MapMerchantScreen> createState() => _MapMerchantScreenState();
}

class _MapMerchantScreenState extends ConsumerState<MapMerchantScreen> {
  final _amount = TextEditingController(text: '2500');
  final _invoiceNo = TextEditingController(text: 'INV-1');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mapControllerProvider.notifier).bootstrap();
    });
  }

  @override
  void dispose() {
    _amount.dispose();
    _invoiceNo.dispose();
    super.dispose();
  }

  int get _minor => int.tryParse(_amount.text.trim()) ?? 0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mapControllerProvider);
    final ctrl = ref.read(mapControllerProvider.notifier);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final a = state.analytics;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MAP Merchant'),
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft), onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(TaifaSpacing.screenH),
        children: [
          Text(
            state.profile?.displayName ?? 'Acceptance profile',
            style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(
            state.profile?.qrIdentity ?? 'Bootstrapping…',
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: TaifaSpacing.lg),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _stat('Paid', '${a.intentsPaid}'),
              _stat('GMV', '${a.gmvMinor}'),
              _stat('QR', '${a.qrCount}'),
              _stat('Links', '${a.linksCount}'),
            ],
          ),
          const SizedBox(height: TaifaSpacing.lg),
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Amount (minor units)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: TaifaSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: state.isBusy ? null : () => ctrl.issueDynamicQr(_minor, description: 'Counter sale'),
                child: const Text('Dynamic QR'),
              ),
              OutlinedButton(
                onPressed: state.isBusy ? null : ctrl.issueStaticQr,
                child: const Text('Static QR'),
              ),
              OutlinedButton(
                onPressed: state.isBusy ? null : () => ctrl.createLink(_minor),
                child: const Text('Payment link'),
              ),
            ],
          ),
          const SizedBox(height: TaifaSpacing.md),
          TextField(
            controller: _invoiceNo,
            decoration: const InputDecoration(
              labelText: 'Invoice number',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: TaifaSpacing.sm),
          OutlinedButton(
            onPressed: state.isBusy
                ? null
                : () => ctrl.createInvoice(_invoiceNo.text.trim(), _minor),
            child: const Text('Create invoice'),
          ),
          if (state.lastQr != null) ...[
            const SizedBox(height: TaifaSpacing.lg),
            Text('Last QR payload', style: text.titleSmall),
            SelectableText(state.lastQr!.payload, style: text.bodySmall),
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: state.lastQr!.payload));
              },
              child: const Text('Copy QR payload'),
            ),
            if (state.lastQr!.intentCode.isNotEmpty)
              Text('Intent: ${state.lastQr!.intentCode}', style: text.labelMedium),
          ],
          if (state.lastLink != null) ...[
            const SizedBox(height: TaifaSpacing.md),
            Text('Link path: ${state.lastLink!.payPath}', style: text.titleSmall),
            Text('Token: ${state.lastLink!.pathToken}', style: text.bodySmall),
          ],
          if (state.lastInvoice != null) ...[
            const SizedBox(height: TaifaSpacing.md),
            Text(
              'Invoice ${state.lastInvoice!.invoiceNumber} · ${state.lastInvoice!.amountMinor} ${state.lastInvoice!.currency}',
              style: text.titleSmall,
            ),
          ],
          if (state.message != null) ...[
            const SizedBox(height: TaifaSpacing.md),
            Text(state.message!, style: text.bodyMedium?.copyWith(color: TaifaColors.emerald700)),
          ],
          if (state.error != null) ...[
            const SizedBox(height: TaifaSpacing.sm),
            Text(state.error!, style: text.bodyMedium?.copyWith(color: scheme.error)),
          ],
          const SizedBox(height: TaifaSpacing.xl),
          Text(
            'Capture uses enterprise.capture_merchant_payment → payments ledger. MAP has no balances.',
            style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: TaifaColors.ocean500.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../application/map_providers.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MapCustomerPayScreen extends ConsumerStatefulWidget {
  const MapCustomerPayScreen({super.key, this.initialCode});

  final String? initialCode;

  @override
  ConsumerState<MapCustomerPayScreen> createState() => _MapCustomerPayScreenState();
}

class _MapCustomerPayScreenState extends ConsumerState<MapCustomerPayScreen> {
  late final TextEditingController _code;

  @override
  void initState() {
    super.initState();
    _code = TextEditingController(text: widget.initialCode ?? '');
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mapControllerProvider);
    final ctrl = ref.read(mapControllerProvider.notifier);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final raw = _code.text.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pay merchant'),
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft), onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(TaifaSpacing.screenH),
        children: [
          Text(
            'Scan · Open link · Pay · Receipt',
            style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: TaifaSpacing.sm),
          Text(
            'Paste an intent code (pi_…) or payment link token.',
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: TaifaSpacing.lg),
          TextField(
            controller: _code,
            decoration: const InputDecoration(
              labelText: 'Intent code or link token',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: TaifaSpacing.md),
          FilledButton(
            onPressed: state.isBusy || raw.isEmpty
                ? null
                : () {
                    if (raw.startsWith('pi_')) {
                      ctrl.payCode(raw);
                    } else {
                      ctrl.payLink(raw);
                    }
                  },
            child: state.isBusy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Pay with wallet'),
          ),
          if (state.lastReceipt != null) ...[
            const SizedBox(height: TaifaSpacing.xl),
            Container(
              padding: const EdgeInsets.all(TaifaSpacing.lg),
              decoration: BoxDecoration(
                color: TaifaColors.emerald700.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Receipt', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  Text(state.lastReceipt!.merchantDisplay),
                  Text('${state.lastReceipt!.amountMinor} ${state.lastReceipt!.currency}'),
                  Text('Ref: ${state.lastReceipt!.paymentRef}', style: text.bodySmall),
                  if (state.lastReceipt!.verificationQr.isNotEmpty)
                    Text(state.lastReceipt!.verificationQr, style: text.labelSmall),
                ],
              ),
            ),
          ],
          if (state.error != null) ...[
            const SizedBox(height: TaifaSpacing.md),
            Text(state.error!, style: TextStyle(color: scheme.error)),
          ],
          if (state.message != null) ...[
            const SizedBox(height: TaifaSpacing.sm),
            Text(state.message!, style: TextStyle(color: TaifaColors.emerald700)),
          ],
        ],
      ),
    );
  }
}

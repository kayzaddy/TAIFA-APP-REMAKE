import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../application/super_app_providers.dart';
import '../domain/qr_resolver.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Universal QR experience — camera-ready shell; paste/simulate today.
/// Never processes payments; only routes to MAP / Mobility / etc.
class UniversalQrScreen extends ConsumerStatefulWidget {
  const UniversalQrScreen({super.key});

  @override
  ConsumerState<UniversalQrScreen> createState() => _UniversalQrScreenState();
}

class _UniversalQrScreenState extends ConsumerState<UniversalQrScreen> {
  final _payload = TextEditingController();
  QrResolveResult? _result;

  @override
  void dispose() {
    _payload.dispose();
    super.dispose();
  }

  void _resolve() {
    final resolver = ref.read(qrResolverProvider);
    setState(() => _result = resolver.resolve(_payload.text));
  }

  void _open() {
    final r = _result;
    if (r == null) return;
    final route = r.route;
    if (route.startsWith('/search?')) {
      final q = Uri.tryParse('https://taifa.local$route')?.queryParameters['q'];
      context.push('/search', extra: q);
      return;
    }
    // Prefill MAP pay when we have pi_ / token in detail
    if (route == '/map/pay' && r.detail.startsWith('Intent ')) {
      final code = r.detail.replaceFirst('Intent ', '');
      context.push('/map/pay', extra: code);
      return;
    }
    context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(TaifaSpacing.screenH),
        children: [
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: TaifaColors.ocean500.withValues(alpha: 0.35)),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.scanLine, size: 64, color: TaifaColors.ocean500),
                  const SizedBox(height: 12),
                  Text('Camera scanner — future-ready', style: text.titleSmall),
                  Text(
                    'Paste a Taifa payload or use a sample below.',
                    style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: TaifaSpacing.lg),
          TextField(
            controller: _payload,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'QR payload or intent code',
              hintText: 'taifa://pay/… or pi_…',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: TaifaSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(onPressed: _resolve, child: const Text('Resolve')),
              OutlinedButton(
                onPressed: () {
                  _payload.text =
                      'taifa://pay/map-seed-retail?q=pi_demo123&a=2500&c=TZS&i=pi_demo123&e=&s=demo';
                  _resolve();
                },
                child: const Text('Sample pay QR'),
              ),
              OutlinedButton(
                onPressed: () {
                  _payload.text = 'taifa://ride/demo';
                  _resolve();
                },
                child: const Text('Sample ride QR'),
              ),
              TextButton(
                onPressed: () async {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  if (data?.text != null) {
                    _payload.text = data!.text!;
                    _resolve();
                  }
                },
                child: const Text('Paste'),
              ),
            ],
          ),
          if (_result != null) ...[
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
                  Text(_result!.label, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  Text('Kind: ${_result!.kind.name}'),
                  Text(_result!.detail, style: text.bodySmall),
                  Text('Route: ${_result!.route}', style: text.labelSmall),
                  const SizedBox(height: TaifaSpacing.md),
                  FilledButton(
                    onPressed: _open,
                    child: const Text('Continue'),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: TaifaSpacing.xl),
          Text(
            'Payments stay on Taifa Payments / MAP. This screen only routes.',
            style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/taifa_dimens.dart';
import '../application/tap_providers.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class TapFundingScreen extends ConsumerStatefulWidget {
  const TapFundingScreen({super.key});

  @override
  ConsumerState<TapFundingScreen> createState() => _TapFundingScreenState();
}

class _TapFundingScreenState extends ConsumerState<TapFundingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tapPayControllerProvider.notifier).loadPrefs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(tapPayControllerProvider).prefs;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment priority'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(TaifaSpacing.screenH),
        children: [
          Text(
            'Default payment priority',
            style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: TaifaSpacing.sm),
          Text(
            'Tap & Pay tries sources in order. Capture today uses Taifa Wallet balance; other sources guide top-up / future rails.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: TaifaSpacing.lg),
          if (prefs == null)
            const Center(child: CircularProgressIndicator())
          else
            ...prefs.priority.asMap().entries.map((e) {
              final i = e.key + 1;
              final s = e.value;
              return ListTile(
                leading: CircleAvatar(child: Text('$i')),
                title: Text(s.label),
                subtitle: Text('${s.kind} · ${s.ref}'),
                trailing: Icon(
                  s.enabled ? LucideIcons.circleCheckBig : LucideIcons.ban,
                ),
              );
            }),
          const SizedBox(height: TaifaSpacing.xl),
          Text(
            'Auth policy: ${prefs?.authPolicy ?? '—'} · Auto-route: ${prefs?.autoRoute ?? true}',
            style: text.labelMedium,
          ),
        ],
      ),
    );
  }
}

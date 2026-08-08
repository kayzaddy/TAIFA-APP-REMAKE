import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// MAP entry — Accept Everywhere · Process Once · Settle Once.
class MapHubScreen extends ConsumerWidget {
  const MapHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.surface,
              TaifaColors.ocean500.withValues(alpha: 0.08),
              scheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(TaifaSpacing.screenH),
            children: [
              Row(
                children: [
                  IconButton(onPressed: () => context.pop(), icon: const Icon(LucideIcons.arrowLeft)),
                  const Spacer(),
                  TextButton(onPressed: () => context.push('/wallet'), child: const Text('Wallet')),
                ],
              ),
              Text(
                'TAIFA',
                style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.2),
              ),
              Text(
                'Accept',
                style: text.displaySmall?.copyWith(
                  color: TaifaColors.ocean500,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: TaifaSpacing.sm),
              Text(
                'Merchant Acceptance Platform — QR, links, invoices, POS. '
                'One ledger. One settlement. Many channels.',
                style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: TaifaSpacing.xl),
              _tile(
                context,
                title: 'Merchant console',
                subtitle: 'Issue QR · links · invoices · analytics',
                icon: LucideIcons.store,
                color: TaifaColors.ocean500,
                path: '/map/merchant',
              ),
              _tile(
                context,
                title: 'Customer pay',
                subtitle: 'Open link or intent · pay · receipt',
                icon: LucideIcons.scanLine,
                color: TaifaColors.emerald600,
                path: '/map/pay',
              ),
              const SizedBox(height: TaifaSpacing.xl),
              TextButton(onPressed: () => context.push('/commerce'), child: const Text('Commerce MOS')),
              TextButton(onPressed: () => context.push('/winga'), child: const Text('Winga')),
              Text(
                'Payments · Ledger · Settlement — owned by Taifa Payments. MAP never duplicates money logic.',
                textAlign: TextAlign.center,
                style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String path,
  }) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: TaifaSpacing.md),
      child: Material(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push(path),
          child: Padding(
            padding: const EdgeInsets.all(TaifaSpacing.lg),
            child: Row(
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(width: TaifaSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      Text(subtitle, style: text.bodySmall),
                    ],
                  ),
                ),
                const Icon(LucideIcons.chevronRight),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

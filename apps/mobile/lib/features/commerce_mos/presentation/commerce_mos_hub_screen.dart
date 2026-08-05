import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../application/mos_providers.dart';
import 'widgets/commerce_kit.dart';

/// Role gateway for Taifa Commerce MOS experiences.
class CommerceMosHubScreen extends ConsumerWidget {
  const CommerceMosHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final onboarded = ref.watch(mosControllerProvider).onboardingComplete;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.surface,
              TaifaColors.emerald900.withValues(alpha: 0.08),
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
                  IconButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/home');
                      }
                    },
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const Spacer(),
                  TextButton(onPressed: () => context.push('/wallet'), child: const Text('Wallet')),
                ],
              ),
              Text('TAIFA', style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
              Text(
                'Commerce',
                style: text.displaySmall?.copyWith(
                  color: TaifaColors.emerald700,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: TaifaSpacing.sm),
              Text(
                'Merchant Operating System — run sales, stock, and suppliers every day.',
                style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: TaifaSpacing.lg),
              if (!onboarded)
                MosNextAction(
                  title: 'New team member?',
                  subtitle: 'Pick your role · first success in minutes',
                  actionLabel: 'Start onboarding',
                  onAction: () => context.push('/commerce/onboarding'),
                ),
              const SizedBox(height: TaifaSpacing.xl),
              _role(context, 'Merchant Desk', 'Owner · today\'s health · Winga', Icons.dashboard_customize_outlined, TaifaColors.emerald600, '/commerce/desk'),
              _role(context, 'Point of Sale', 'Cashier · scan · charge · close shift', Icons.point_of_sale, TaifaColors.ocean500, '/commerce/pos'),
              _role(context, 'Warehouse', 'Receive · pick · pack · count', Icons.warehouse_outlined, TaifaColors.gold500, '/commerce/warehouse'),
              _role(context, 'Procurement', 'Suppliers · POs · vendor performance', Icons.local_shipping_outlined, TaifaColors.emerald700, '/commerce/procurement'),
              _role(context, 'Customer Shop', 'Browse · cart · pay · track', Icons.storefront_outlined, TaifaColors.ocean500, '/commerce/shop'),
              _role(context, 'Management', 'Revenue · inventory · growth', Icons.insights_outlined, TaifaColors.emerald600, '/commerce/management'),
              const SizedBox(height: TaifaSpacing.xl),
              TextButton(onPressed: () => context.push('/map'), child: const Text('Accept payments (MAP)')),
              TextButton(onPressed: () => context.push('/merchant'), child: const Text('Legacy kitchen queue')),
              TextButton(onPressed: () => context.push('/winga'), child: const Text('Winga brokerage')),
              Text(
                'Payments · Ledger · Winga · Mobility · AI — shared platform. No duplicated money logic.',
                textAlign: TextAlign.center,
                style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _role(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String route,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TaifaSpacing.md),
      child: Material(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(TaifaRadii.xxl),
        child: InkWell(
          onTap: () => context.push(route),
          borderRadius: BorderRadius.circular(TaifaRadii.xxl),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: TaifaSpacing.lg, vertical: TaifaSpacing.sm),
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.2),
              foregroundColor: color,
              child: Icon(icon),
            ),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(subtitle),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
          ),
        ),
      ),
    );
  }
}

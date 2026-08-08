import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../application/brokerage_providers.dart';
import '../application/experience_providers.dart';
import '../domain/brokerage_models.dart';
import 'widgets/experience_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Role gateway — Customer / Winga / Provider apps share one entry.
class WingaHubScreen extends ConsumerWidget {
  const WingaHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
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
                      icon: const Icon(LucideIcons.arrowLeft),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.push('/winga/opportunities'),
                      child: const Text('Opportunities'),
                    ),
                    TextButton(
                      onPressed: () => context.push('/winga/marketplace'),
                      child: const Text('Demo shop'),
                    ),
                  ],
                ),
                const SizedBox(height: TaifaSpacing.md),
                Text(
                  'TAIFA',
                  style: text.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'Winga',
                  style: text.displaySmall?.copyWith(
                    color: TaifaColors.emerald700,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: TaifaSpacing.sm),
                Text(
                  'Trusted brokerage for Africa — connect, negotiate, earn.',
                  style: text.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: TaifaSpacing.lg),
                if (!ref.watch(experiencePrefsProvider).onboardingComplete)
                  WingaNextActionBar(
                    title: 'New here?',
                    subtitle: 'Two-minute setup · wallet · first success',
                    actionLabel: 'Start onboarding',
                    onAction: () => context.push('/winga/onboarding'),
                  ),
                const SizedBox(height: TaifaSpacing.xl),
                _RoleCard(
                  title: 'Customer',
                  subtitle: 'Discover · quote · pay · review',
                  icon: LucideIcons.globe,
                  color: TaifaColors.ocean500,
                  onTap: () {
                    ref.read(wingaActorRoleProvider.notifier).setRole(
                          WingaActorRole.customer,
                        );
                    context.push('/winga/customer');
                  },
                ),
                const SizedBox(height: TaifaSpacing.md),
                _RoleCard(
                  title: 'Winga',
                  subtitle: 'CRM · pipeline · commissions · AI coach',
                  icon: LucideIcons.handshake,
                  color: TaifaColors.emerald600,
                  featured: true,
                  onTap: () {
                    ref.read(wingaActorRoleProvider.notifier).setRole(
                          WingaActorRole.broker,
                        );
                    context.push('/winga/broker');
                  },
                ),
                const SizedBox(height: TaifaSpacing.md),
                _RoleCard(
                  title: 'Provider',
                  subtitle: 'Offerings · campaigns · settlements',
                  icon: LucideIcons.store,
                  color: TaifaColors.gold500,
                  onTap: () {
                    ref.read(wingaActorRoleProvider.notifier).setRole(
                          WingaActorRole.provider,
                        );
                    context.push('/winga/provider');
                  },
                ),
                const SizedBox(height: TaifaSpacing.xl),
                Text(
                  'Powered by Taifa Identity · Wallet · Payments · AI',
                  textAlign: TextAlign.center,
                  style: text.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.featured = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: featured ? 0.16 : 0.1),
      borderRadius: BorderRadius.circular(TaifaRadii.xxl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TaifaRadii.xxl),
        child: Padding(
          padding: EdgeInsets.all(featured ? TaifaSpacing.xxl : TaifaSpacing.xl),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.2),
                foregroundColor: color,
                child: Icon(icon),
              ),
              const SizedBox(width: TaifaSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    Text(subtitle),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronRight, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

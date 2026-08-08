import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/taifa_colors.dart';
import '../../../../app/theme/taifa_dimens.dart';
import '../../application/brokerage_providers.dart';
import '../../application/experience_providers.dart';
import '../../domain/brokerage_models.dart';
import '../widgets/experience_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// First-success onboarding — value → role → wallet → first action.
class WingaOnboardingScreen extends ConsumerStatefulWidget {
  const WingaOnboardingScreen({super.key});

  @override
  ConsumerState<WingaOnboardingScreen> createState() =>
      _WingaOnboardingScreenState();
}

class _WingaOnboardingScreenState extends ConsumerState<WingaOnboardingScreen> {
  int _step = 0;

  static const _steps = ['Welcome', 'Role', 'Trust', 'Go'];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Get started'),
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(TaifaSpacing.screenH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WingaJourneyStepper(steps: _steps, currentIndex: _step),
              const SizedBox(height: TaifaSpacing.xxl),
              Expanded(child: _body(text)),
              WingaNextActionBar(
                title: _ctaTitle,
                subtitle: _ctaSubtitle,
                actionLabel: _ctaLabel,
                onAction: _next,
                secondaryLabel: _step > 0 ? 'Back' : null,
                onSecondary: _step > 0 ? () => setState(() => _step--) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _ctaTitle => switch (_step) {
        0 => 'Ready to explore Winga?',
        1 => 'Choose how you use Winga',
        2 => 'Trust is built in',
        _ => 'You\'re ready',
      };

  String get _ctaSubtitle => switch (_step) {
        0 => 'Find services, earn as a broker, or grow your business.',
        1 => 'You can switch roles anytime from the hub.',
        2 => 'Verified people, ledger payments, clear commissions.',
        _ => 'Complete your first action in under two minutes.',
      };

  String get _ctaLabel => switch (_step) {
        3 => 'Enter Winga',
        _ => 'Continue',
      };

  Widget _body(TextTheme text) {
    return switch (_step) {
      0 => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Brokerage that feels human',
              style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: TaifaSpacing.md),
            Text(
              'Winga connects customers with trusted providers through verified intermediaries — with transparent commissions and Taifa Wallet payments.',
              style: text.bodyLarge,
            ),
            const SizedBox(height: TaifaSpacing.xl),
            const WingaTrustBadge(label: 'Taifa Identity'),
            const SizedBox(height: 8),
            const WingaTrustBadge(label: 'Ledger-backed payments'),
            const SizedBox(height: 8),
            const WingaTrustBadge(label: 'AI assists — never pays'),
          ],
        ),
      1 => Column(
          children: [
            _roleTile(
              'I need products or services',
              'Customer',
              LucideIcons.globe,
              TaifaColors.ocean500,
              () {
                ref.read(wingaActorRoleProvider.notifier).setRole(
                      WingaActorRole.customer,
                    );
                setState(() => _step = 2);
              },
            ),
            _roleTile(
              'I connect buyers with providers',
              'Winga',
              LucideIcons.handshake,
              TaifaColors.emerald600,
              () {
                ref.read(wingaActorRoleProvider.notifier).setRole(
                      WingaActorRole.broker,
                    );
                setState(() => _step = 2);
              },
            ),
            _roleTile(
              'I offer products or services',
              'Provider',
              LucideIcons.store,
              TaifaColors.gold500,
              () {
                ref.read(wingaActorRoleProvider.notifier).setRole(
                      WingaActorRole.provider,
                    );
                setState(() => _step = 2);
              },
            ),
          ],
        ),
      2 => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const WingaGoalHeader(
              goal: 'Your money stays protected',
              hint: 'Every payment posts to the Taifa ledger. Commissions settle to your wallet with a full breakdown.',
            ),
            const SizedBox(height: TaifaSpacing.xl),
            ListTile(
              leading: const Icon(LucideIcons.wallet),
              title: const Text('Connect Wallet'),
              subtitle: const Text('Already part of your Taifa account'),
              trailing: TextButton(
                onPressed: () => context.push('/wallet'),
                child: const Text('Open'),
              ),
            ),
            const ListTile(
              leading: Icon(LucideIcons.badgeCheck),
              title: Text('Verification'),
              subtitle: Text('KYC / KYB when you earn or sell'),
            ),
          ],
        ),
      _ => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const WingaGoalHeader(
              goal: 'First success',
              hint: 'Pick one action — we guide the rest.',
            ),
            const SizedBox(height: TaifaSpacing.lg),
            ..._firstActions(),
          ],
        ),
    };
  }

  List<Widget> _firstActions() {
    final role = ref.watch(wingaActorRoleProvider);
    return switch (role) {
      WingaActorRole.broker => [
          ListTile(
            leading: const Icon(LucideIcons.megaphone),
            title: const Text('Browse opportunities'),
            subtitle: const Text('Campaigns with clear commissions'),
            onTap: () {
              ref.read(experiencePrefsProvider.notifier).completeOnboarding();
              context.go('/winga/opportunities');
            },
          ),
          ListTile(
            leading: const Icon(LucideIcons.funnel),
            title: const Text('Open Winga Desk'),
            onTap: () {
              ref.read(experiencePrefsProvider.notifier).completeOnboarding();
              context.go('/winga/broker');
            },
          ),
        ],
      WingaActorRole.provider => [
          ListTile(
            leading: const Icon(LucideIcons.store),
            title: const Text('Open Provider Hub'),
            onTap: () {
              ref.read(experiencePrefsProvider.notifier).completeOnboarding();
              context.go('/winga/provider');
            },
          ),
        ],
      _ => [
          ListTile(
            leading: const Icon(LucideIcons.compass),
            title: const Text('Discover offerings'),
            subtitle: const Text('Hotels, insurance, property, and more'),
            onTap: () {
              ref.read(experiencePrefsProvider.notifier).completeOnboarding();
              context.go('/winga/customer');
            },
          ),
        ],
    };
  }

  Widget _roleTile(
    String subtitle,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TaifaSpacing.sm),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TaifaRadii.lg),
        ),
        tileColor: color.withValues(alpha: 0.12),
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: const Icon(LucideIcons.chevronRight),
      ),
    );
  }

  void _next() {
    if (_step < 3) {
      setState(() => _step++);
      return;
    }
    ref.read(experiencePrefsProvider.notifier).completeOnboarding();
    final role = ref.read(wingaActorRoleProvider);
    switch (role) {
      case WingaActorRole.broker:
        context.go('/winga/broker');
      case WingaActorRole.provider:
        context.go('/winga/provider');
      case WingaActorRole.customer:
      case null:
        context.go('/winga/customer');
    }
  }
}

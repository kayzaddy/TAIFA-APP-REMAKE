import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../../../app/theme/taifa_theme.dart';
import '../../../app/theme/theme_mode_provider.dart';
import '../../../shared/widgets/promo_card.dart';
import '../../../shared/widgets/quick_action_button.dart';
import '../../../shared/widgets/service_tile.dart';
import '../../../shared/widgets/taifa_logo.dart';
import '../../../shared/widgets/wallet_card.dart';
import '../../super_app/application/super_app_providers.dart';
import '../../super_app/presentation/widgets/home_journey_rail.dart';
import '../../super_app/presentation/widgets/super_search_bar.dart';
import '../application/home_providers.dart';

/// TAIFA Home — the living dashboard. Screen 01 in the design spec.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletSummaryProvider);
    final quickActions = ref.watch(quickActionsProvider);
    final services = ref.watch(servicesProvider);
    final offer = ref.watch(featuredOfferProvider);

    final greetingName = walletAsync.value?.greetingName ?? '…';

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          TaifaSpacing.screenH,
          TaifaSpacing.md,
          TaifaSpacing.screenH,
          120, // clears floating bottom nav
        ),
        children: [
          _Header(
            greetingName: greetingName,
            isDark: ref.watch(themeModeProvider) == ThemeMode.dark,
            onToggleTheme: () => ref.read(themeModeProvider.notifier).toggle(),
            onProfile: () => context.go('/profile'),
            onNotifications: () => context.go('/notifications'),
          ),
          const SizedBox(height: TaifaSpacing.lg),
          const SuperSearchBar(),
          const SizedBox(height: TaifaSpacing.lg),
          walletAsync.when(
            data: (w) => WalletCard(
              balance: w.balanceLabel,
              currencyLabel: 'TZS',
              secondaryLabel: w.secondaryLabel,
              maskedNumber: w.maskedNumber,
            ),
            loading: () => const _WalletSkeleton(),
            error: (_, _) => const _WalletSkeleton(),
          ),
          const SizedBox(height: TaifaSpacing.lg),
          Row(
            children: [
              for (var i = 0; i < quickActions.length; i++) ...[
                if (i > 0) const SizedBox(width: TaifaSpacing.sm),
                Expanded(
                  child: QuickActionButton(
                    icon: quickActions[i].icon,
                    label: quickActions[i].label,
                    onTap: () => _onQuickAction(context, quickActions[i].id),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: TaifaSpacing.lg),
          if (ref.watch(superAppFlagsProvider).homeJourneyRail) ...[
            const HomeJourneyRail(),
            const SizedBox(height: TaifaSpacing.lg),
          ],
          _SectionHeader(
            title: 'Services',
            action: 'All',
            onAction: () => context.go('/menu'),
          ),
          const SizedBox(height: TaifaSpacing.xs),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: services.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: TaifaSpacing.sm,
              crossAxisSpacing: TaifaSpacing.sm,
              childAspectRatio: 0.82,
            ),
            itemBuilder: (context, i) => ServiceTile(
              icon: services[i].icon,
              label: services[i].label,
              tint: services[i].tint,
              onTap: () =>
                  _onService(context, services[i].route, services[i].label),
            ),
          ),
          const SizedBox(height: TaifaSpacing.md),
          PromoCard(
            title: offer.title,
            subtitle: offer.subtitle,
            badge: offer.badge,
            onTap: () => context.go('/flights'),
          ),
        ],
      ),
    );
  }
}

void _onQuickAction(BuildContext context, String id) {
  switch (id) {
    case 'send':
      context.go('/wallet/send');
    case 'topup':
      context.go('/wallet/topup');
    case 'scan':
      context.push('/scan');
    case 'bills':
      context.push('/pay');
    default:
      context.push('/search');
  }
}

void _onService(BuildContext context, String route, String label) {
  context.go(route);
}

class _Header extends StatelessWidget {
  const _Header({
    required this.greetingName,
    required this.isDark,
    required this.onToggleTheme,
    required this.onProfile,
    required this.onNotifications,
  });
  final String greetingName;
  final bool isDark;
  final VoidCallback onToggleTheme;
  final VoidCallback onProfile;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return Row(
      children: [
        const TaifaLogo(variant: TaifaLogoVariant.mark, size: 40),
        const SizedBox(width: TaifaSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Habari, $greetingName',
                style: TextStyle(fontSize: 13, color: palette.textMuted),
              ),
              const SizedBox(height: 2),
              Text(
                'Karibu TAIFA',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onNotifications,
          visualDensity: VisualDensity.compact,
          icon: Icon(
            Icons.notifications_none_rounded,
            size: 22,
            color: palette.textMuted,
          ),
        ),
        IconButton(
          onPressed: onToggleTheme,
          visualDensity: VisualDensity.compact,
          icon: Icon(
            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            size: 20,
            color: palette.textMuted,
          ),
        ),
        const SizedBox(width: TaifaSpacing.xs),
        GestureDetector(
          onTap: onProfile,
          child: ClipOval(
            child: SizedBox(
              width: 38,
              height: 38,
              child: Image.asset(
                'assets/brand/taifa_app_icon.png',
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.action,
    this.onAction,
  });
  final String title;
  final String action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: palette.textPrimary,
          ),
        ),
        GestureDetector(
          onTap: onAction,
          child: Row(
            children: [
              Text(
                action,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: palette.accent,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.arrow_forward_rounded,
                size: 12,
                color: palette.accent,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WalletSkeleton extends StatelessWidget {
  const _WalletSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        gradient: TaifaColors.walletCardGradient,
        borderRadius: BorderRadius.circular(TaifaRadii.xxl),
      ),
    );
  }
}

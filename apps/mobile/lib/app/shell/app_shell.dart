import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/taifa_dimens.dart';
import '../../shared/widgets/taifa_bottom_nav.dart';

/// Root shell hosting the persistent floating bottom navigation across the
/// primary tabs. Uses GoRouter's [StatefulNavigationShell] so each tab keeps
/// its own navigation stack and state.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _destinations = [
    TaifaNavDestination(icon: Icons.home_rounded, label: 'Home'),
    TaifaNavDestination(icon: Icons.explore_rounded, label: 'Mobility'),
    TaifaNavDestination(icon: Icons.auto_awesome_rounded, label: 'AI'),
    TaifaNavDestination(
      icon: Icons.account_balance_wallet_rounded,
      label: 'Wallet',
    ),
    TaifaNavDestination(icon: Icons.menu_rounded, label: 'Menu'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(
          TaifaSpacing.md,
          0,
          TaifaSpacing.md,
          TaifaSpacing.md,
        ),
        child: TaifaBottomNav(
          destinations: _destinations,
          currentIndex: navigationShell.currentIndex,
          onSelected: (i) => navigationShell.goBranch(
            i,
            initialLocation: i == navigationShell.currentIndex,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/taifa_dimens.dart';
import '../theme/taifa_icons.dart';
import '../../shared/widgets/taifa_bottom_nav.dart';

/// Root shell hosting the persistent floating bottom navigation across the
/// primary tabs. Uses GoRouter's [StatefulNavigationShell] so each tab keeps
/// its own navigation stack and state.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _destinations = [
    TaifaNavDestination(icon: TaifaIcons.home, label: 'Home'),
    TaifaNavDestination(icon: TaifaIcons.mobility, label: 'Mobility'),
    TaifaNavDestination(icon: TaifaIcons.ai, label: 'AI'),
    TaifaNavDestination(icon: TaifaIcons.wallet, label: 'Wallet'),
    TaifaNavDestination(icon: TaifaIcons.menu, label: 'Menu'),
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

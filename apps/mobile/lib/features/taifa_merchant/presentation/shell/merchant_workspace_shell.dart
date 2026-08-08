import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MerchantWorkspaceShell extends StatelessWidget {
  const MerchantWorkspaceShell({super.key, required this.child});

  final Widget child;

  int _indexForLocation(String location) {
    if (location.contains('/profile')) return 1;
    if (location.contains('/settings')) return 2;
    if (location.contains('/notifications')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final index = _indexForLocation(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              context.go('/taifa-merchant/dashboard');
            case 1:
              context.go('/taifa-merchant/profile');
            case 2:
              context.go('/taifa-merchant/settings');
            case 3:
              context.go('/taifa-merchant/notifications');
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(LucideIcons.layoutGrid), label: 'Home'),
          NavigationDestination(icon: Icon(LucideIcons.store), label: 'Profile'),
          NavigationDestination(icon: Icon(LucideIcons.slidersHorizontal), label: 'Settings'),
          NavigationDestination(icon: Icon(LucideIcons.bell), label: 'Alerts'),
        ],
      ),
    );
  }
}

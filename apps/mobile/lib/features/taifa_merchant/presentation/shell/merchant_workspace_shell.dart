import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.storefront_outlined), label: 'Profile'),
          NavigationDestination(icon: Icon(Icons.tune), label: 'Settings'),
          NavigationDestination(icon: Icon(Icons.notifications_outlined), label: 'Alerts'),
        ],
      ),
    );
  }
}

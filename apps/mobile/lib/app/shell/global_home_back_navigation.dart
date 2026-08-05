import 'package:flutter/material.dart';

import '../router.dart';

/// Adds a consistent home affordance above every entered page.
///
/// This intentionally navigates to Home instead of relying on navigator
/// history: many super-app modules are opened with `go`, so a normal pop may
/// have no route to return to.
class GlobalHomeBackNavigation extends StatelessWidget {
  const GlobalHomeBackNavigation({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: TaifaRouter.router.routeInformationProvider,
      child: child,
      builder: (context, child) {
        final path = TaifaRouter.router.routeInformationProvider.value.uri.path;
        final showBack = path != '/home' && path != '/splash';
        if (!showBack) return child!;

        final colors = Theme.of(context).colorScheme;
        return Column(
          children: [
            Material(
              color: colors.surface,
              elevation: 1,
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 48,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Semantics(
                      label: 'Back to Home',
                      button: true,
                      child: IconButton(
                        key: const ValueKey('global-home-back'),
                        onPressed: () => TaifaRouter.router.go('/home'),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(child: child!),
          ],
        );
      },
    );
  }
}

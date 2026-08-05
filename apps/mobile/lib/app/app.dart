import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'shell/global_home_back_navigation.dart';
import 'theme/taifa_theme.dart';
import 'theme/theme_mode_provider.dart';

/// Root application widget. Wires the router, both themes, and the reactive
/// theme mode.
class TaifaApp extends ConsumerWidget {
  const TaifaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'TAIFA',
      debugShowCheckedModeBanner: false,
      theme: TaifaTheme.light(),
      darkTheme: TaifaTheme.dark(),
      themeMode: themeMode,
      routerConfig: TaifaRouter.router,
      builder: (context, child) =>
          GlobalHomeBackNavigation(child: child ?? const SizedBox.shrink()),
    );
  }
}

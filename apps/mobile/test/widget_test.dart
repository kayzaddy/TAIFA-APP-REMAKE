import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:taifa/app/app.dart';
import 'package:taifa/app/router.dart';

void main() {
  testWidgets('TAIFA app boots through splash into the Home dashboard', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: TaifaApp()));

    // Splash is the cold-start surface.
    expect(find.text('TAIFA'), findsWidgets);
    expect(
      find.text('The Digital Operating System of Tanzania'),
      findsOneWidget,
    );

    // Advance through the splash intro + hold + exit (~3.6s).
    await tester.pump(const Duration(milliseconds: 3600));
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    expect(find.text('Karibu TAIFA'), findsOneWidget);
  });

  testWidgets('every entered page exposes a back-to-home arrow', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: TaifaApp()));
    TaifaRouter.router.go('/settings');
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('global-home-back')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('global-home-back')));
    await tester.pumpAndSettle();

    expect(find.text('Karibu TAIFA'), findsOneWidget);
    expect(find.byKey(const ValueKey('global-home-back')), findsNothing);
  });
}

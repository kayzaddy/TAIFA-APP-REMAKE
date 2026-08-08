import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taifa/app/theme/taifa_icons.dart';
import 'package:taifa/app/theme/taifa_theme.dart';
import 'package:taifa/shared/widgets/taifa_icon_tile.dart';
import 'package:taifa/shared/widgets/taifa_pressable.dart';
import 'package:taifa/shared/widgets/taifa_skeleton.dart';
import 'package:taifa/shared/widgets/taifa_status_chip.dart';

Widget _host(Widget child, {bool dark = true, bool reduceMotion = false}) {
  return MaterialApp(
    theme: dark ? TaifaTheme.dark() : TaifaTheme.light(),
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  group('TaifaStatusChip', () {
    testWidgets('renders a label and glyph for every tone', (tester) async {
      for (final tone in TaifaStatusTone.values) {
        await tester.pumpWidget(
          _host(TaifaStatusChip(label: tone.name, tone: tone)),
        );
        expect(find.text(tone.name), findsOneWidget);
        // Colour is never the only signal — each tone pairs with an icon.
        expect(find.byType(Icon), findsOneWidget);
      }
    });

    testWidgets('compact variant drops the glyph', (tester) async {
      await tester.pumpWidget(
        _host(
          const TaifaStatusChip(
            label: 'Paid',
            tone: TaifaStatusTone.positive,
            compact: true,
          ),
        ),
      );
      expect(find.text('Paid'), findsOneWidget);
      expect(find.byType(Icon), findsNothing);
    });
  });

  group('TaifaPressable', () {
    testWidgets('press does not change the widget\'s layout bounds', (tester) async {
      await tester.pumpWidget(
        _host(
          TaifaPressable(
            onTap: () {},
            child: const SizedBox(width: 120, height: 48),
          ),
        ),
      );

      final before = tester.getSize(find.byType(TaifaPressable));
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(TaifaPressable)),
      );
      await tester.pump(const Duration(milliseconds: 120));
      final during = tester.getSize(find.byType(TaifaPressable));
      await gesture.up();
      await tester.pumpAndSettle();

      // The scale is a paint-time transform, so nothing around it reflows.
      expect(during, before);
    });

    testWidgets('fires onTap and exposes button semantics', (tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        _host(
          TaifaPressable(
            onTap: () => taps++,
            semanticLabel: 'Send money',
            child: const SizedBox(width: 100, height: 44),
          ),
        ),
      );
      await tester.tap(find.byType(TaifaPressable));
      expect(taps, 1);
      expect(find.bySemanticsLabel('Send money'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('disabled when onTap is null', (tester) async {
      await tester.pumpWidget(
        _host(
          const TaifaPressable(child: SizedBox(width: 100, height: 44)),
        ),
      );
      await tester.tap(find.byType(TaifaPressable));
      await tester.pump();
      // Nothing to assert beyond "did not throw"; the opacity cue is visual.
      expect(find.byType(TaifaPressable), findsOneWidget);
    });
  });

  group('TaifaFeatureTile', () {
    testWidgets('meets the 44pt minimum touch target', (tester) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 90,
            child: TaifaFeatureTile(
              icon: TaifaIcons.splitBill,
              label: 'Split Bills',
              onTap: () {},
            ),
          ),
        ),
      );
      final size = tester.getSize(find.byType(TaifaFeatureTile));
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
    });

    testWidgets('badge count reaches the accessibility label', (tester) async {
      // The semantics tree is only built while a handle is held.
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 90,
            child: TaifaFeatureTile(
              icon: TaifaIcons.notifications,
              label: 'Alerts',
              badgeCount: 3,
              onTap: () {},
            ),
          ),
        ),
      );
      expect(find.text('3'), findsOneWidget);
      // A screen reader announces the pending count, not just "Alerts".
      expect(find.bySemanticsLabel('Alerts, 3 new'), findsOneWidget);
      handle.dispose();
    });
  });

  group('TaifaSkeleton', () {
    testWidgets('animates by default and settles flat under reduced motion', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const TaifaSkeletonCard()));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(TaifaSkeleton), findsWidgets);

      await tester.pumpWidget(
        _host(const TaifaSkeletonCard(), reduceMotion: true),
      );
      // With animations disabled the shimmer controller must not keep the
      // tester waiting forever.
      await tester.pumpAndSettle();
      expect(find.byType(TaifaSkeleton), findsWidgets);
    });
  });

  group('theme', () {
    testWidgets('icon tile renders in both light and dark', (tester) async {
      for (final dark in [true, false]) {
        await tester.pumpWidget(
          _host(
            TaifaIconTile(icon: TaifaIcons.wallet, hue: TaifaIconHue.emerald),
            dark: dark,
          ),
        );
        expect(find.byType(TaifaIconTile), findsOneWidget);
      }
    });
  });
}

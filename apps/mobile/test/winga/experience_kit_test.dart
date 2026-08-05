import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:taifa/features/winga/domain/opportunity_models.dart';
import 'package:taifa/features/winga/presentation/widgets/experience_kit.dart';

void main() {
  test('opportunity catalog filters by industry and trending', () {
    final hotels = WingaOpportunityCatalog.filtered(industry: 'Hotels');
    expect(hotels, isNotEmpty);
    expect(hotels.every((o) => o.industry == 'Hotels'), isTrue);

    final trending = WingaOpportunityCatalog.filtered(trendingOnly: true);
    expect(trending.every((o) => o.trending), isTrue);
  });

  testWidgets('journey stepper highlights current step', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WingaJourneyStepper(
            steps: ['Discover', 'Compare', 'Pay'],
            currentIndex: 1,
          ),
        ),
      ),
    );
    expect(find.text('Compare'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('commission breakdown shows share and status', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WingaCommissionBreakdown(
            dealAmountMinor: 10000000,
            commissionMinor: 1200000,
            status: 'pending',
            bps: 1200,
            providerName: 'Harbour View',
          ),
        ),
      ),
    );
    expect(find.text('Commission transparency'), findsOneWidget);
    expect(find.textContaining('pending'), findsOneWidget);
    expect(find.textContaining('Harbour View'), findsOneWidget);
  });

  testWidgets('next action bar invokes primary CTA', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WingaNextActionBar(
            title: 'Next',
            subtitle: 'Do the thing',
            actionLabel: 'Go',
            onAction: () => tapped = true,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Go'));
    expect(tapped, isTrue);
  });
}

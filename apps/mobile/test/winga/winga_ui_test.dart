import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:taifa/features/winga/presentation/widgets/winga_ui.dart';

void main() {
  testWidgets('WingaMoneyText formats minor units', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: WingaMoneyText(150000, currency: 'TZS')),
      ),
    );
    expect(find.textContaining('TZS'), findsOneWidget);
    expect(find.textContaining('1,500'), findsOneWidget);
  });

  testWidgets('WingaEmptyState shows message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: WingaEmptyState(message: 'Nothing here')),
      ),
    );
    expect(find.text('Nothing here'), findsOneWidget);
  });
}

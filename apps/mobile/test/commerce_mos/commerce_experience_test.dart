import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:taifa/features/commerce_mos/application/seed_mos_repository.dart';
import 'package:taifa/features/commerce_mos/presentation/widgets/commerce_kit.dart';

void main() {
  test('seed MOS checkout reserves then pays', () async {
    final repo = SeedMosRepository();
    final order = await repo.createOrder(
      lines: [(productId: 'p1', quantity: 2)],
    );
    expect(order.totalMinor, 2400000);
    final paid = await repo.payOrder(order.id, idempotencyKey: 't1');
    expect(paid.paid, isTrue);
    expect(paid.paymentRef, isNotEmpty);
    final fulfilled = await repo.fulfillOrder(order.id);
    expect(fulfilled.status, 'fulfilled');
  });

  test('AI assist blocks payment authorization', () async {
    final repo = SeedMosRepository();
    expect(
      () => repo.assist('authorize_payment'),
      throwsA(isA<StateError>()),
    );
  });

  testWidgets('MosMoneyText formats currency', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: MosMoneyText(1200000)),
      ),
    );
    expect(find.textContaining('TZS'), findsOneWidget);
    expect(find.textContaining('12,000'), findsOneWidget);
  });

  testWidgets('order timeline shows stages', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: MosOrderTimeline(currentIndex: 2)),
      ),
    );
    expect(find.text('Paid'), findsOneWidget);
  });
}

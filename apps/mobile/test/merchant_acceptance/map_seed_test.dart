import 'package:flutter_test/flutter_test.dart';

import 'package:taifa/features/merchant_acceptance/application/seed_map_repository.dart';

void main() {
  test('seed MAP issues QR and pays intent without a second ledger', () async {
    final repo = SeedMapRepository();
    final profile = await repo.bootstrap();
    expect(profile.qrIdentity, isNotEmpty);

    final issued = await repo.issueQr(amountMinor: 1500, kind: 'dynamic');
    expect(issued.intent, isNotNull);
    expect(issued.qr.payload, contains('taifa://pay/'));

    final paid = await repo.payIntent(issued.intent!.publicCode);
    expect(paid.intent.isPaid, isTrue);
    expect(paid.receipt.paymentRef, isNotEmpty);
    expect(paid.receipt.amountMinor, 1500);
  });
}

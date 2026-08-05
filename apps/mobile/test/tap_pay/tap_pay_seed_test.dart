import 'package:flutter_test/flutter_test.dart';

import 'package:taifa/features/tap_pay/application/seed_tap_repository.dart';

void main() {
  test('seed tap flow: detect → auth → confirm without second ledger', () async {
    final repo = SeedTapPayRepository();
    final prefs = await repo.fundingPrefs();
    expect(prefs.priority.first.kind, 'wallet');

    final started = await repo.startTap(merchantId: 'x', amountMinor: 2000);
    expect(started.session.needsAuth, isTrue);

    final authed = await repo.authenticate(started.session.publicCode);
    expect(authed.authCompleted, isTrue);

    final paid = await repo.confirm(started.session.publicCode);
    expect(paid.isSuccess, isTrue);
    expect(paid.paymentRef, isNotEmpty);
  });
}

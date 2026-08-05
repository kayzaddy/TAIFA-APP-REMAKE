import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taifa/features/wealth/application/wealth_providers.dart';
import 'package:taifa/features/wealth/data/wealth_catalog.dart';

void main() {
  test('WealthController contributes to a circle', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final ctrl = container.read(wealthControllerProvider.notifier);
    await ctrl.bootstrap();
    ctrl.open(WealthCatalog.circles().first);
    ctrl.goConfirm();
    await ctrl.contribute();
    expect(container.read(wealthControllerProvider).phase, WealthPhase.receipt);
  });
}

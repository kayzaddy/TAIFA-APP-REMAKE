import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taifa/features/insurance/application/insurance_providers.dart';
import 'package:taifa/features/insurance/data/insurance_catalog.dart';

void main() {
  test('InsuranceController buys a plan', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final ctrl = container.read(insuranceControllerProvider.notifier);
    await ctrl.bootstrap();
    ctrl.open(InsuranceCatalog.plans().first);
    ctrl.goConfirm();
    await ctrl.buy();
    expect(
      container.read(insuranceControllerProvider).phase,
      InsurancePhase.receipt,
    );
  });
}

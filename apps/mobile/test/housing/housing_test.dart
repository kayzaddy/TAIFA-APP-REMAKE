import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taifa/features/housing/application/housing_providers.dart';
import 'package:taifa/features/housing/data/housing_catalog.dart';

void main() {
  test('HousingController schedules viewing', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final ctrl = container.read(housingControllerProvider.notifier);
    await ctrl.bootstrap();
    ctrl.open(HousingCatalog.all().first);
    await ctrl.requestViewing();
    expect(
      container.read(housingControllerProvider).phase,
      HousingPhase.scheduled,
    );
  });
}

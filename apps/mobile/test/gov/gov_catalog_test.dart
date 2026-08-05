import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taifa/features/gov/application/gov_providers.dart';
import 'package:taifa/features/gov/data/gov_catalog.dart';

void main() {
  test('Gov catalog has services', () {
    expect(GovCatalog.all(), isNotEmpty);
  });

  test('GovController can open a service', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final ctrl = container.read(govControllerProvider.notifier);
    await ctrl.bootstrap();
    ctrl.open(GovCatalog.all().first);
    expect(container.read(govControllerProvider).phase, GovPhase.detail);
  });
}

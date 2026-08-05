import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taifa/features/health/application/health_providers.dart';
import 'package:taifa/features/health/data/health_catalog.dart';

void main() {
  test('Health catalog has facilities', () {
    expect(HealthCatalog.all(), isNotEmpty);
  });

  test('HealthController opens checkout', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final ctrl = container.read(healthControllerProvider.notifier);
    await ctrl.bootstrap();
    ctrl.open(HealthCatalog.all().first);
    ctrl.goCheckout();
    expect(
      container.read(healthControllerProvider).phase,
      HealthPhase.checkout,
    );
  });
}

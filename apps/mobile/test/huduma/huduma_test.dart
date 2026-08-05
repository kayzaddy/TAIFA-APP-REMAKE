import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taifa/features/huduma/application/huduma_providers.dart';
import 'package:taifa/features/huduma/data/huduma_catalog.dart';

void main() {
  test('HudumaController books a service', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final ctrl = container.read(hudumaControllerProvider.notifier);
    await ctrl.bootstrap();
    ctrl.open(HudumaCatalog.services().first);
    ctrl.goConfirm();
    await ctrl.book();
    expect(container.read(hudumaControllerProvider).phase, HudumaPhase.receipt);
  });
}

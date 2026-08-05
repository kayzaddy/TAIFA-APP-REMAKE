import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taifa/features/family/application/family_providers.dart';
import 'package:taifa/features/family/data/family_catalog.dart';

void main() {
  test('FamilyController sends allowance', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final ctrl = container.read(familyControllerProvider.notifier);
    await ctrl.bootstrap();
    ctrl.open(FamilyCatalog.members().first);
    ctrl.goConfirm();
    await ctrl.submit();
    expect(container.read(familyControllerProvider).phase, FamilyPhase.receipt);
  });
}

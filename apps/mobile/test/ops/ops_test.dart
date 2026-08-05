import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taifa/features/ops/application/ops_providers.dart';
import 'package:taifa/features/ops/domain/ops_models.dart';

void main() {
  test('OpsController acknowledges an incident', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final ctrl = container.read(opsControllerProvider.notifier);
    await ctrl.bootstrap();
    final incidents = container.read(opsControllerProvider).incidents;
    expect(incidents, isNotEmpty);
    final first = incidents.firstWhere(
      (i) => i.status == OpsIncidentStatus.open,
    );
    ctrl.open(first);
    await ctrl.advanceSelected();
    expect(
      container.read(opsControllerProvider).selected?.status,
      OpsIncidentStatus.acknowledged,
    );
  });
}

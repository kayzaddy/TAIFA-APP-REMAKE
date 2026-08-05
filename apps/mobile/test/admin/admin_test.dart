import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taifa/features/admin/application/admin_providers.dart';
import 'package:taifa/features/admin/domain/admin_models.dart';

void main() {
  test('AdminController advances a case', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final ctrl = container.read(adminControllerProvider.notifier);
    await ctrl.bootstrap();
    final cases = container.read(adminControllerProvider).cases;
    expect(cases, isNotEmpty);
    final first = cases.firstWhere((c) => c.status == AdminCaseStatus.open);
    ctrl.open(first);
    await ctrl.advanceSelected();
    expect(
      container.read(adminControllerProvider).selected?.status,
      AdminCaseStatus.reviewing,
    );
  });
}

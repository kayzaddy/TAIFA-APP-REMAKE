import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taifa/features/driver/application/driver_providers.dart';
import 'package:taifa/features/driver/domain/driver_models.dart';

void main() {
  test('DriverController accepts a job', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final ctrl = container.read(driverControllerProvider.notifier);
    await ctrl.bootstrap();
    final job = container.read(driverControllerProvider).jobs.first;
    ctrl.open(job);
    await ctrl.accept();
    expect(
      container.read(driverControllerProvider).active?.status,
      DriverJobStatus.accepted,
    );
  });
}

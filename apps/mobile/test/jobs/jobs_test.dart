import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taifa/features/jobs/application/jobs_providers.dart';
import 'package:taifa/features/jobs/data/jobs_catalog.dart';

void main() {
  test('JobsController accepts a job', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final ctrl = container.read(jobsControllerProvider.notifier);
    await ctrl.bootstrap();
    ctrl.open(JobsCatalog.all().first);
    await ctrl.accept();
    expect(container.read(jobsControllerProvider).phase, JobsPhase.active);
  });
}

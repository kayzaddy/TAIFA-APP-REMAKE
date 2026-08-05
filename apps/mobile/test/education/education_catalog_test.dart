import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taifa/features/education/application/education_providers.dart';
import 'package:taifa/features/education/data/education_catalog.dart';

void main() {
  test('Education catalog has schools', () {
    expect(EducationCatalog.all(), isNotEmpty);
  });

  test('EducationController creates invoice path', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final ctrl = container.read(educationControllerProvider.notifier);
    await ctrl.bootstrap();
    ctrl.open(EducationCatalog.all().first);
    ctrl.goCheckout();
    await ctrl.createInvoice();
    expect(
      container.read(educationControllerProvider).phase,
      EducationPhase.invoiced,
    );
  });
}

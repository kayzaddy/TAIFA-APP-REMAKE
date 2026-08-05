import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taifa/features/nfc/application/nfc_providers.dart';
import 'package:taifa/features/nfc/data/nfc_catalog.dart';
import 'package:taifa/features/nfc/domain/nfc_models.dart';

void main() {
  test('NFC catalog has phrase packs', () {
    expect(NfcCatalog.packs(), isNotEmpty);
    expect(NfcCatalog.packs().first.phrases, isNotEmpty);
  });

  test('NfcController reaches result after simulateTap', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final ctrl = container.read(nfcControllerProvider.notifier);
    ctrl.simulateTap(NfcCatalog.packs().first);
    expect(container.read(nfcControllerProvider).phase, NfcPhase.scanning);
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    expect(container.read(nfcControllerProvider).phase, NfcPhase.result);
  });
}

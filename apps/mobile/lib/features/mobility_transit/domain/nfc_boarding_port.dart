/// NFC boarding port — Phase 5 hardware integration (architecture only).
abstract class NfcBoardingPort {
  Future<bool> get isAvailable;

  Future<String?> readTransitToken();

  Future<bool> writeTransitToken(String payload);
}

import '../domain/nfc_boarding_port.dart';

/// Simulated NFC reader for demos until hardware integration lands.
class NoOpNfcBoardingPort implements NfcBoardingPort {
  const NoOpNfcBoardingPort();

  @override
  Future<bool> get isAvailable async => false;

  @override
  Future<String?> readTransitToken() async => null;

  @override
  Future<bool> writeTransitToken(String payload) async => false;
}

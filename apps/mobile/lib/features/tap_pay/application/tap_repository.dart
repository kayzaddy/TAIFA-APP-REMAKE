import '../domain/tap_models.dart';

abstract class TapPayRepository {
  Future<TapFundingPrefs> fundingPrefs();

  Future<TapFundingPrefs> updateFundingPrefs({
    List<Map<String, dynamic>>? priority,
    bool? autoRoute,
    bool? requireConfirmation,
    String? authPolicy,
  });

  Future<TapStartResult> startTap({
    required String merchantId,
    required int amountMinor,
    String channel = 'nfc',
    String terminalCode = '',
  });

  Future<TapSession> authenticate(String publicCode, {String method = 'biometric'});

  Future<TapSession> confirm(String publicCode, {String? idempotencyKey});

  Future<TapSession> cancel(String publicCode);
}

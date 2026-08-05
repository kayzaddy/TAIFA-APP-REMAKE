import '../domain/tap_models.dart';
import 'tap_repository.dart';

/// Offline demo — simulates NFC tap without a second ledger.
class SeedTapPayRepository implements TapPayRepository {
  TapFundingPrefs _prefs = const TapFundingPrefs(
    priority: [
      TapFundingSource(kind: 'wallet', ref: 'taifa_wallet', label: 'Taifa Wallet'),
      TapFundingSource(kind: 'mobile_money', ref: 'mpesa', label: 'M-Pesa'),
      TapFundingSource(kind: 'mobile_money', ref: 'airtel', label: 'Airtel Money'),
      TapFundingSource(kind: 'bank', ref: 'crdb', label: 'CRDB'),
      TapFundingSource(kind: 'card', ref: 'visa', label: 'Visa'),
    ],
  );
  final _sessions = <String, TapSession>{};
  var _n = 0;

  @override
  Future<TapFundingPrefs> fundingPrefs() async => _prefs;

  @override
  Future<TapFundingPrefs> updateFundingPrefs({
    List<Map<String, dynamic>>? priority,
    bool? autoRoute,
    bool? requireConfirmation,
    String? authPolicy,
  }) async {
    _prefs = TapFundingPrefs(
      priority: priority == null
          ? _prefs.priority
          : priority.map(TapFundingSource.fromJson).toList(),
      autoRoute: autoRoute ?? _prefs.autoRoute,
      requireConfirmation: requireConfirmation ?? _prefs.requireConfirmation,
      authPolicy: authPolicy ?? _prefs.authPolicy,
      lowRiskThresholdMinor: _prefs.lowRiskThresholdMinor,
    );
    return _prefs;
  }

  @override
  Future<TapStartResult> startTap({
    required String merchantId,
    required int amountMinor,
    String channel = 'nfc',
    String terminalCode = '',
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final code = 'tap_seed_${++_n}';
    final session = TapSession(
      publicCode: code,
      status: 'auth_required',
      amountMinor: amountMinor,
      channel: channel,
      merchantDisplay: 'Demo Merchant',
      authRequired: true,
      selectedFunding: _prefs.priority.first,
      intentCode: 'pi_seed_$_n',
    );
    _sessions[code] = session;
    return TapStartResult(session: session, routing: {'selected': {'kind': 'wallet'}});
  }

  @override
  Future<TapSession> authenticate(String publicCode, {String method = 'biometric'}) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final s = _sessions[publicCode];
    if (s == null) throw StateError('session not found');
    final next = TapSession(
      publicCode: s.publicCode,
      status: 'authorizing',
      amountMinor: s.amountMinor,
      currency: s.currency,
      channel: s.channel,
      merchantDisplay: s.merchantDisplay,
      authRequired: true,
      authCompleted: true,
      selectedFunding: s.selectedFunding,
      intentCode: s.intentCode,
    );
    _sessions[publicCode] = next;
    return next;
  }

  @override
  Future<TapSession> confirm(String publicCode, {String? idempotencyKey}) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    final s = _sessions[publicCode];
    if (s == null) throw StateError('session not found');
    if (s.needsAuth) throw StateError('authentication required');
    final next = TapSession(
      publicCode: s.publicCode,
      status: 'succeeded',
      amountMinor: s.amountMinor,
      currency: s.currency,
      channel: s.channel,
      merchantDisplay: s.merchantDisplay,
      authRequired: s.authRequired,
      authCompleted: true,
      paymentRef: 'seed-txn-$publicCode',
      receiptCode: 'rcpt_seed_$_n',
      selectedFunding: s.selectedFunding,
      intentCode: s.intentCode,
    );
    _sessions[publicCode] = next;
    return next;
  }

  @override
  Future<TapSession> cancel(String publicCode) async {
    final s = _sessions[publicCode];
    if (s == null) throw StateError('session not found');
    final next = TapSession(
      publicCode: s.publicCode,
      status: 'cancelled',
      amountMinor: s.amountMinor,
      merchantDisplay: s.merchantDisplay,
      authRequired: s.authRequired,
      authCompleted: s.authCompleted,
    );
    _sessions[publicCode] = next;
    return next;
  }
}

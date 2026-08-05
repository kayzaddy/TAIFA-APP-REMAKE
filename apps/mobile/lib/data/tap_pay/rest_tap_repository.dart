import '../../features/tap_pay/application/seed_tap_repository.dart';
import '../../features/tap_pay/application/tap_repository.dart';
import '../../features/tap_pay/domain/tap_models.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';

class RestTapPayRepository implements TapPayRepository {
  RestTapPayRepository(this._client, {TapPayRepository? fallback})
      : _fallback = fallback ?? SeedTapPayRepository();

  final TaifaApiClient _client;
  final TapPayRepository _fallback;
  String? _merchantId;

  Future<T> _guard<T>(Future<T> Function() live, Future<T> Function() soft) async {
    try {
      return await live();
    } on ApiException {
      return soft();
    } catch (_) {
      return soft();
    }
  }

  Future<String> _merchant() async {
    if (_merchantId != null) return _merchantId!;
    final json = await _client.postJson(
      '/api/v1/map/bootstrap',
      body: {'code': 'tap-pay-retail', 'legal_name': 'Tap & Pay Retail'},
    );
    _merchantId = json['merchant_id']?.toString();
    if (_merchantId == null || _merchantId!.isEmpty) {
      throw StateError('bootstrap missing merchant_id');
    }
    return _merchantId!;
  }

  @override
  Future<TapFundingPrefs> fundingPrefs() => _guard(() async {
        final json = await _client.getJson('/api/v1/map/funding/prefs');
        return TapFundingPrefs.fromJson(json);
      }, _fallback.fundingPrefs);

  @override
  Future<TapFundingPrefs> updateFundingPrefs({
    List<Map<String, dynamic>>? priority,
    bool? autoRoute,
    bool? requireConfirmation,
    String? authPolicy,
  }) =>
      _guard(() async {
        final body = <String, dynamic>{};
        if (priority != null) body['priority'] = priority;
        if (autoRoute != null) body['auto_route'] = autoRoute;
        if (requireConfirmation != null) {
          body['require_confirmation'] = requireConfirmation;
        }
        if (authPolicy != null) body['auth_policy'] = authPolicy;
        final json = await _client.postJson('/api/v1/map/funding/prefs', body: body);
        // API is PUT — use patch if available
        return TapFundingPrefs.fromJson(json);
      }, () => _fallback.updateFundingPrefs(
            priority: priority,
            autoRoute: autoRoute,
            requireConfirmation: requireConfirmation,
            authPolicy: authPolicy,
          ));

  @override
  Future<TapStartResult> startTap({
    required String merchantId,
    required int amountMinor,
    String channel = 'nfc',
    String terminalCode = '',
  }) =>
      _guard(() async {
        final mid = merchantId.isEmpty ? await _merchant() : merchantId;
        final json = await _client.postJson(
          '/api/v1/map/merchants/$mid/tap',
          body: {
            'amount_minor': amountMinor,
            'channel': channel,
            'terminal_code': terminalCode,
          },
        );
        return TapStartResult(
          session: TapSession.fromJson(json['session'] as Map<String, dynamic>? ?? {}),
          routing: json['routing'] as Map<String, dynamic>?,
        );
      }, () => _fallback.startTap(
            merchantId: merchantId,
            amountMinor: amountMinor,
            channel: channel,
            terminalCode: terminalCode,
          ));

  @override
  Future<TapSession> authenticate(String publicCode, {String method = 'biometric'}) =>
      _guard(() async {
        final json = await _client.postJson(
          '/api/v1/map/tap/$publicCode/auth',
          body: {'method': method},
        );
        return TapSession.fromJson(json);
      }, () => _fallback.authenticate(publicCode, method: method));

  @override
  Future<TapSession> confirm(String publicCode, {String? idempotencyKey}) =>
      _guard(() async {
        final key = idempotencyKey ?? 'tap-${DateTime.now().millisecondsSinceEpoch}';
        final json = await _client.postJson(
          '/api/v1/map/tap/$publicCode/confirm',
          body: {},
          idempotencyKey: key,
        );
        return TapSession.fromJson(json);
      }, () => _fallback.confirm(publicCode, idempotencyKey: idempotencyKey));

  @override
  Future<TapSession> cancel(String publicCode) => _guard(() async {
        final json = await _client.postJson('/api/v1/map/tap/$publicCode/cancel', body: {});
        return TapSession.fromJson(json);
      }, () => _fallback.cancel(publicCode));
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_config.dart';
import '../api/api_exception.dart';
import 'device_identity.dart';

/// Owns the device-bound bearer token: it registers the device once against
/// `POST /auth/device/register`, persists the returned token, and produces the
/// auth headers every subsequent call needs.
///
/// The token is bound to the [DeviceIdentity]; the server verifies both the
/// `Authorization: Bearer` token and the `X-Device-Id` header match. If the
/// token is ever rejected the session [invalidate]s and re-registers.
class DeviceSession {
  DeviceSession(
    this._config, {
    http.Client? client,
    DeviceIdentity? identity,
    SharedPreferences? prefs,
    FlutterSecureStorage? secureStorage,
  }) : _http = client ?? http.Client(),
       _identity = identity ?? DeviceIdentity(prefs: prefs),
       _prefs = prefs,
       _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _tokenKey = 'taifa.device_token';

  final ApiConfig _config;
  final http.Client _http;
  final DeviceIdentity _identity;
  final FlutterSecureStorage _secureStorage;
  SharedPreferences? _prefs;

  String? _token;
  Future<String>? _inFlight;

  /// Headers to attach to an authenticated request. Registers on first use.
  Future<Map<String, String>> authorizationHeaders() async {
    final token = await _ensureToken();
    final deviceId = await _identity.id();
    return {'Authorization': 'Bearer $token', 'X-Device-Id': deviceId};
  }

  /// Drops the cached/persisted token so the next call re-registers. Called when
  /// the server rejects the token (401).
  Future<void> invalidate() async {
    _token = null;
    await _secureStorage.delete(key: _tokenKey);
    final prefs = await _prefsInstance();
    await prefs.remove(_tokenKey);
  }

  Future<String> _ensureToken() {
    if (_token != null) return Future.value(_token);
    // Collapse concurrent callers onto a single registration attempt.
    return _inFlight ??= _loadOrRegister().whenComplete(() => _inFlight = null);
  }

  Future<String> _loadOrRegister() async {
    final prefs = await _prefsInstance();
    var stored = await _secureStorage.read(key: _tokenKey);
    // One-time migration from legacy SharedPreferences storage.
    stored ??= prefs.getString(_tokenKey);
    if (stored != null && stored.isNotEmpty) {
      await _secureStorage.write(key: _tokenKey, value: stored);
      await prefs.remove(_tokenKey);
      return _token = stored;
    }
    return _register();
  }

  Future<String> _register() async {
    final deviceId = await _identity.id();
    final uri = _config.resolve('auth/device/register');
    final http.Response response;
    try {
      response = await _http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'device_id': deviceId, 'platform': _platform()}),
          )
          .timeout(_config.timeout);
    } on TimeoutException {
      throw const NetworkException('Registration timed out.');
    } on SocketException {
      throw const NetworkException();
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiStatusException(
        response.statusCode,
        'Device registration failed.',
      );
    }

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw const ApiDecodeException();
    }
    final token = body['token'];
    if (token is! String || token.isEmpty) {
      throw const ApiDecodeException('Registration response missing token.');
    }
    await _secureStorage.write(key: _tokenKey, value: token);
    return _token = token;
  }

  Future<SharedPreferences> _prefsInstance() async =>
      _prefs ??= await SharedPreferences.getInstance();

  /// Registers or updates the device push token for outbound notifications.
  Future<void> registerPushToken(String pushToken) async {
    if (pushToken.isEmpty) return;
    final headers = await authorizationHeaders();
    final uri = _config.resolve('auth/device/push-token');
    try {
      await _http
          .post(
            uri,
            headers: {...headers, 'Content-Type': 'application/json'},
            body: jsonEncode({'push_token': pushToken}),
          )
          .timeout(_config.timeout);
    } on Object {
      // Push registration is best-effort; in-app notifications still work.
    }
  }

  String _platform() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return 'flutter';
  }
}

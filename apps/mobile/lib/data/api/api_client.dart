// Private, injectable fields cannot be named-parameter initializing formals
// (Dart forbids `this._x` for named params), so the lint below is a false hit.
// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../auth/device_session.dart';
import 'api_config.dart';
import 'api_exception.dart';

/// The versioned REST boundary. The repository layer depends on this interface,
/// not on `http`, so it can be faked wholesale in tests.
abstract interface class TaifaApiClient {
  Future<Map<String, dynamic>> getJson(String path);

  /// GET that returns a JSON array (e.g. trip history).
  Future<List<dynamic>> getJsonList(String path);

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic> body,
    String? idempotencyKey,
  });

  Future<Map<String, dynamic>> patchJson(
    String path, {
    Map<String, dynamic> body,
  });

  Future<void> deleteJson(String path);
}

/// `http`-backed client. Attaches device-bound auth headers on every call, sets
/// the `Idempotency-Key` when provided, decodes JSON, and maps failures to the
/// [ApiException] hierarchy. A single 401 triggers one token refresh + retry.
class HttpApiClient implements TaifaApiClient {
  HttpApiClient({
    required ApiConfig config,
    required DeviceSession session,
    http.Client? client,
  }) : _config = config,
       _session = session,
       _http = client ?? http.Client();

  final ApiConfig _config;
  final DeviceSession _session;
  final http.Client _http;

  @override
  Future<Map<String, dynamic>> getJson(String path) => _sendMap(
    () async => _http.get(_config.resolve(path), headers: await _headers()),
  );

  @override
  Future<List<dynamic>> getJsonList(String path) => _sendList(
    () async => _http.get(_config.resolve(path), headers: await _headers()),
  );

  @override
  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic> body = const {},
    String? idempotencyKey,
  }) {
    return _sendMap(
      () async => _http.post(
        _config.resolve(path),
        headers: await _headers(idempotencyKey: idempotencyKey),
        body: jsonEncode(body),
      ),
    );
  }

  @override
  Future<Map<String, dynamic>> patchJson(
    String path, {
    Map<String, dynamic> body = const {},
  }) {
    return _sendMap(
      () async => _http.patch(
        _config.resolve(path),
        headers: await _headers(),
        body: jsonEncode(body),
      ),
    );
  }

  @override
  Future<void> deleteJson(String path) async {
    var response = await _execute(
      () async => _http.delete(_config.resolve(path), headers: await _headers()),
    );

    if (response.statusCode == 401) {
      await _session.invalidate();
      response = await _execute(
        () async => _http.delete(_config.resolve(path), headers: await _headers()),
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) return;

    Map<String, dynamic>? parsed;
    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) parsed = decoded;
      } on FormatException {
        parsed = null;
      }
    }
    final detail = parsed?['detail'];
    throw ApiStatusException(
      response.statusCode,
      detail is String ? detail : 'Request failed (${response.statusCode}).',
      body: parsed,
    );
  }

  Future<Map<String, String>> _headers({String? idempotencyKey}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...await _session.authorizationHeaders(),
    };
    if (idempotencyKey != null) headers['Idempotency-Key'] = idempotencyKey;
    return headers;
  }

  Future<Map<String, dynamic>> _sendMap(
    Future<http.Response> Function() request,
  ) async {
    var response = await _execute(request);

    if (response.statusCode == 401) {
      await _session.invalidate();
      response = await _execute(request);
    }

    return _decodeMap(response);
  }

  Future<List<dynamic>> _sendList(
    Future<http.Response> Function() request,
  ) async {
    var response = await _execute(request);

    if (response.statusCode == 401) {
      await _session.invalidate();
      response = await _execute(request);
    }

    return _decodeList(response);
  }

  Future<http.Response> _execute(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request().timeout(_config.timeout);
    } on TimeoutException {
      throw const NetworkException('The request timed out.');
    } on SocketException {
      throw const NetworkException();
    } on http.ClientException {
      throw const NetworkException();
    }
  }

  Map<String, dynamic> _decodeMap(http.Response response) {
    Map<String, dynamic>? parsed;
    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) parsed = decoded;
      } on FormatException {
        parsed = null;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (parsed == null) throw const ApiDecodeException();
      return parsed;
    }

    final detail = parsed?['detail'];
    throw ApiStatusException(
      response.statusCode,
      detail is String ? detail : 'Request failed (${response.statusCode}).',
      body: parsed,
    );
  }

  List<dynamic> _decodeList(http.Response response) {
    List<dynamic>? parsed;
    Map<String, dynamic>? errorBody;
    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          parsed = decoded;
        } else if (decoded is Map<String, dynamic>) {
          errorBody = decoded;
        }
      } on FormatException {
        parsed = null;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (parsed == null) throw const ApiDecodeException();
      return parsed;
    }

    final detail = errorBody?['detail'];
    throw ApiStatusException(
      response.statusCode,
      detail is String ? detail : 'Request failed (${response.statusCode}).',
      body: errorBody,
    );
  }
}

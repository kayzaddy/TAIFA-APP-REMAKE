import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../api/api_config.dart';
import '../api/api_exception.dart';
import '../auth/device_session.dart';

class RegistryDocumentClient {
  RegistryDocumentClient(this._config, this._session, {http.Client? client})
    : _client = client ?? http.Client();

  final ApiConfig _config;
  final DeviceSession _session;
  final http.Client _client;

  Future<void> upload({
    required String applicationId,
    required String kind,
    required String filePath,
    String? documentNumber,
    DateTime? issueDate,
    DateTime? expiryDate,
  }) async {
    final file = File(filePath);
    final size = await file.length();
    if (size <= 0 || size > 10 * 1024 * 1024) {
      throw StateError('Document must be between 1 byte and 10 MiB.');
    }
    final request = http.MultipartRequest(
      'POST',
      _config.resolve(
        'mobility-registry/applications/$applicationId/documents/upload',
      ),
    );
    request.headers.addAll(await _session.authorizationHeaders());
    request.fields['kind'] = kind;
    if (documentNumber?.isNotEmpty ?? false) {
      request.fields['document_number'] = documentNumber!;
    }
    if (issueDate != null) {
      request.fields['issue_date'] = _date(issueDate);
    }
    if (expiryDate != null) {
      request.fields['expiry_date'] = _date(expiryDate);
    }
    request.files.add(await http.MultipartFile.fromPath('document', filePath));
    late http.StreamedResponse response;
    try {
      response = await _client.send(request).timeout(_config.timeout);
    } on TimeoutException {
      throw const NetworkException('Document upload timed out.');
    } on SocketException {
      throw const NetworkException();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiStatusException(
        response.statusCode,
        'Document upload failed (${response.statusCode}).',
      );
    }
  }

  String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

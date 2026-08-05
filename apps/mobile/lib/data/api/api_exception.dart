/// Transport/protocol level failures from the REST client. The repository layer
/// translates these into domain-level `WalletException`s so the UI never sees
/// raw HTTP concerns.
sealed class ApiException implements Exception {
  const ApiException(this.message);
  final String message;

  @override
  String toString() => 'ApiException: $message';
}

/// The request never reached the server, or timed out.
class NetworkException extends ApiException {
  const NetworkException([
    super.message = 'Network unavailable. Check your connection.',
  ]);
}

/// The server responded with a non-2xx status.
class ApiStatusException extends ApiException {
  const ApiStatusException(this.statusCode, super.message, {this.body});
  final int statusCode;
  final Map<String, dynamic>? body;

  bool get isUnauthorized => statusCode == 401;
  bool get isConflict => statusCode == 409;
  bool get isUnprocessable => statusCode == 422;
}

/// The response body could not be decoded as the expected shape.
class ApiDecodeException extends ApiException {
  const ApiDecodeException([
    super.message = 'Unexpected response from server.',
  ]);
}

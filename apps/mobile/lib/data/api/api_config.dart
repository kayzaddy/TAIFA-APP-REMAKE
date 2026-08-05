/// Immutable configuration for talking to the TAIFA backend.
///
/// Everything is overridable at build time with `--dart-define` so the same
/// binary points at local / staging / production without code changes:
///
/// ```
/// flutter run \
///   --dart-define=TAIFA_USE_REMOTE=true \
///   --dart-define=TAIFA_API_BASE_URL=http://10.0.2.2:8000
/// ```
///
/// `10.0.2.2` is the host loopback as seen from the Android emulator; iOS
/// simulators and desktop use `localhost`.
class ApiConfig {
  const ApiConfig({
    required this.baseUrl,
    this.apiVersion = 'v1',
    this.useRemoteBackend = false,
    this.timeout = const Duration(seconds: 20),
  });

  final String baseUrl;
  final String apiVersion;
  final bool useRemoteBackend;
  final Duration timeout;

  /// Reads configuration from the compile-time environment, falling back to a
  /// sensible local-dev default (seed/offline mode off the network).
  factory ApiConfig.fromEnvironment() {
    return ApiConfig(
      baseUrl: const String.fromEnvironment(
        'TAIFA_API_BASE_URL',
        defaultValue: 'http://10.0.2.2:8000',
      ),
      useRemoteBackend: const bool.fromEnvironment(
        'TAIFA_USE_REMOTE',
        defaultValue: false,
      ),
    );
  }

  /// The versioned root, e.g. `http://10.0.2.2:8000/api/v1`.
  String get apiRoot => '$baseUrl/api/$apiVersion';

  Uri resolve(String path) {
    final normalized = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$apiRoot/$normalized');
  }
}

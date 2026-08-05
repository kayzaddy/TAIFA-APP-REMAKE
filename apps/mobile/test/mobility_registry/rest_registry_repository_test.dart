import 'package:flutter_test/flutter_test.dart';
import 'package:taifa/data/api/api_client.dart';
import 'package:taifa/data/api/api_exception.dart';
import 'package:taifa/data/mobility_registry/rest_registry_repository.dart';
import 'package:taifa/data/mobility_registry/secure_registry_queue.dart';
import 'package:taifa/features/mobility_registry/domain/registry_application.dart';

void main() {
  test('remote registration maps authoritative registry response', () async {
    final client = _RegistryApiClient();
    final repository = RestRegistryRepository(client, queue: _MemoryQueue());

    final result = await repository.submit(RegistryApplicationType.driver, {
      'full_name': 'Asha Mussa',
    });

    expect(result.queuedOffline, isFalse);
    expect(result.application?.number, 'DRV-2026-ABC');
    expect(result.application?.mayOperate, isFalse);
    expect(client.lastPath, 'mobility-registry/applications/drivers');
    expect(client.lastBody?['client_reference'], isNotEmpty);
  });

  test(
    'network failure securely queues and later synchronizes idempotently',
    () async {
      final client = _RegistryApiClient(networkUnavailable: true);
      final queue = _MemoryQueue();
      final repository = RestRegistryRepository(client, queue: queue);

      final result = await repository.submit(RegistryApplicationType.station, {
        'client_reference': 'offline-station-1',
        'name': 'Mwenge Station',
      });

      expect(result.queuedOffline, isTrue);
      expect(await repository.pendingCount(), 1);
      await repository.submit(RegistryApplicationType.station, {
        'client_reference': 'offline-station-1',
        'name': 'Mwenge Station',
      });
      expect(await repository.pendingCount(), 1);

      client.networkUnavailable = false;
      expect(await repository.synchronize(), 1);
      expect(await repository.pendingCount(), 0);
    },
  );
}

class _MemoryQueue implements RegistryQueue {
  final entries = <QueuedRegistrySubmission>[];

  @override
  Future<void> add(QueuedRegistrySubmission entry) async {
    if (!entries.any(
      (item) =>
          item.payload['client_reference'] == entry.payload['client_reference'],
    )) {
      entries.add(entry);
    }
  }

  @override
  Future<List<QueuedRegistrySubmission>> read() async => List.of(entries);

  @override
  Future<void> write(List<QueuedRegistrySubmission> value) async {
    entries
      ..clear()
      ..addAll(value);
  }
}

class _RegistryApiClient implements TaifaApiClient {
  _RegistryApiClient({this.networkUnavailable = false});

  bool networkUnavailable;
  String? lastPath;
  Map<String, dynamic>? lastBody;

  @override
  Future<Map<String, dynamic>> getJson(String path) async => {'results': []};

  @override
  Future<List<dynamic>> getJsonList(String path) async => [];

  @override
  Future<Map<String, dynamic>> patchJson(
    String path, {
    Map<String, dynamic> body = const {},
  }) async => {};

  @override
  Future<void> deleteJson(String path) async {}

  @override
  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic> body = const {},
    String? idempotencyKey,
  }) async {
    lastPath = path;
    lastBody = body;
    if (networkUnavailable) throw const NetworkException();
    return {
      'id': '9daed8eb-d062-4fbf-8c34-991f2d9c2b1e',
      'application_number': 'DRV-2026-ABC',
      'application_type': 'driver',
      'status': 'draft',
      'stage': 'draft',
      'region': 'Dar es Salaam',
      'district': 'Kinondoni',
      'updated_at': '2026-07-17T12:00:00Z',
    };
  }
}

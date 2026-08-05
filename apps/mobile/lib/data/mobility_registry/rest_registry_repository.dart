import 'package:uuid/uuid.dart';

import '../../features/mobility_registry/application/registry_repository.dart';
import '../../features/mobility_registry/domain/registry_application.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import 'registry_api_paths.dart';
import 'secure_registry_queue.dart';

class RestRegistryRepository implements RegistryRepository {
  RestRegistryRepository(this._client, {RegistryQueue? queue})
    : _queue = queue ?? SecureRegistryQueue();

  final TaifaApiClient _client;
  final RegistryQueue _queue;

  @override
  Future<List<RegistryApplication>> applications() async {
    final json = await _client.getJson(RegistryApiPaths.applications);
    final rows = (json['results'] as List<dynamic>? ?? const []);
    return rows
        .map((row) => _fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  @override
  Future<RegistrySubmissionResult> submit(
    RegistryApplicationType type,
    Map<String, dynamic> payload,
  ) async {
    final apiType = _typeToApi(type);
    final body = Map<String, dynamic>.from(payload);
    body.putIfAbsent('client_reference', () => const Uuid().v4());
    if (type == RegistryApplicationType.transportCompany) {
      body['application_type'] = 'transport_company';
    }
    try {
      final response = await _client.postJson(
        RegistryApiPaths.registration(apiType),
        body: body,
      );
      return RegistrySubmissionResult(application: _fromJson(response));
    } on NetworkException {
      await _queue.add(
        QueuedRegistrySubmission(
          type: apiType,
          payload: body,
          queuedAt: DateTime.now(),
        ),
      );
      return const RegistrySubmissionResult(queuedOffline: true);
    }
  }

  @override
  Future<int> synchronize() async {
    final pending = await _queue.read();
    final remaining = <QueuedRegistrySubmission>[];
    var synchronized = 0;
    for (final command in pending) {
      try {
        await _client.postJson(
          RegistryApiPaths.registration(command.type),
          body: command.payload,
        );
        synchronized++;
      } on NetworkException {
        remaining.add(command);
      } on ApiStatusException catch (error) {
        // Keep retriable conflicts/server failures; discard invalid 4xx commands
        // only after the server has authoritatively rejected them.
        if (error.statusCode >= 500 || error.statusCode == 409) {
          remaining.add(command);
        }
      }
    }
    await _queue.write(remaining);
    return synchronized;
  }

  @override
  Future<int> pendingCount() async => (await _queue.read()).length;

  @override
  Future<Map<String, dynamic>> verificationDashboard() =>
      _client.getJson('mobility-registry/verification/dashboard');

  @override
  Future<Map<String, dynamic>> complianceDashboard() =>
      _client.getJson('mobility-registry/compliance/dashboard');

  @override
  Future<List<RegistryApplication>> verificationQueue() async {
    final json = await _client.getJson(
      'mobility-registry/verification/queue?page_size=100',
    );
    return (json['results'] as List<dynamic>? ?? const [])
        .map((row) => _fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  @override
  Future<RegistryApplication> workflowAction(
    String applicationId,
    String action, {
    String reason = '',
    String comments = '',
  }) async {
    final response = await _client.postJson(
      'mobility-registry/applications/$applicationId/workflow/$action',
      body: {'reason': reason, 'comments': comments},
    );
    return _fromJson(response);
  }

  RegistryApplication _fromJson(Map<String, dynamic> json) {
    return RegistryApplication(
      id: json['id'].toString(),
      number: json['application_number'] as String,
      type: _typeFromApi(json['application_type'] as String),
      status: _statusFromApi(json['status'] as String),
      stage: json['stage'] as String,
      region: json['region'] as String,
      district: json['district'] as String,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  String _typeToApi(RegistryApplicationType value) => switch (value) {
    RegistryApplicationType.driver => 'driver',
    RegistryApplicationType.vehicle => 'vehicle',
    RegistryApplicationType.station => 'station',
    RegistryApplicationType.fleet => 'fleet',
    RegistryApplicationType.transportCompany => 'transport_company',
  };

  RegistryApplicationType _typeFromApi(String value) => switch (value) {
    'vehicle' => RegistryApplicationType.vehicle,
    'station' => RegistryApplicationType.station,
    'fleet' => RegistryApplicationType.fleet,
    'transport_company' => RegistryApplicationType.transportCompany,
    _ => RegistryApplicationType.driver,
  };

  RegistryApplicationStatus _statusFromApi(String value) => switch (value) {
    'submitted' => RegistryApplicationStatus.submitted,
    'pending_review' => RegistryApplicationStatus.pendingReview,
    'documents_missing' => RegistryApplicationStatus.documentsMissing,
    'rejected' => RegistryApplicationStatus.rejected,
    'suspended' => RegistryApplicationStatus.suspended,
    'approved' => RegistryApplicationStatus.approved,
    'blocked' => RegistryApplicationStatus.blocked,
    _ => RegistryApplicationStatus.draft,
  };
}

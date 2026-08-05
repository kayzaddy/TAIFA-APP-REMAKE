import '../domain/registry_application.dart';

class RegistrySubmissionResult {
  const RegistrySubmissionResult({
    this.application,
    this.queuedOffline = false,
  });

  final RegistryApplication? application;
  final bool queuedOffline;
}

abstract interface class RegistryRepository {
  Future<List<RegistryApplication>> applications();

  Future<RegistrySubmissionResult> submit(
    RegistryApplicationType type,
    Map<String, dynamic> payload,
  );

  Future<int> synchronize();

  Future<int> pendingCount();

  Future<Map<String, dynamic>> verificationDashboard();

  Future<Map<String, dynamic>> complianceDashboard();

  Future<List<RegistryApplication>> verificationQueue();

  Future<RegistryApplication> workflowAction(
    String applicationId,
    String action, {
    String reason = '',
    String comments = '',
  });
}

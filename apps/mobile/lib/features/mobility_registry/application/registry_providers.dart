import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/mobility_registry/rest_registry_repository.dart';
import '../../../data/mobility_registry/registry_document_client.dart';
import '../../wallet/application/wallet_providers.dart'
    show apiClientProvider, apiConfigProvider, deviceSessionProvider;
import '../domain/registry_application.dart';
import 'registry_repository.dart';

final registryRepositoryProvider = Provider<RegistryRepository>(
  (ref) => RestRegistryRepository(ref.watch(apiClientProvider)),
);

final registryDocumentClientProvider = Provider<RegistryDocumentClient>(
  (ref) => RegistryDocumentClient(
    ref.watch(apiConfigProvider),
    ref.watch(deviceSessionProvider),
  ),
);

class RegistryState {
  const RegistryState({
    this.applications = const [],
    this.pendingOffline = 0,
    this.loading = false,
    this.message,
    this.error,
  });

  final List<RegistryApplication> applications;
  final int pendingOffline;
  final bool loading;
  final String? message;
  final String? error;

  RegistryState copyWith({
    List<RegistryApplication>? applications,
    int? pendingOffline,
    bool? loading,
    String? message,
    String? error,
    bool clearFeedback = false,
  }) => RegistryState(
    applications: applications ?? this.applications,
    pendingOffline: pendingOffline ?? this.pendingOffline,
    loading: loading ?? this.loading,
    message: clearFeedback ? null : (message ?? this.message),
    error: clearFeedback ? null : (error ?? this.error),
  );
}

class RegistryController extends Notifier<RegistryState> {
  StreamSubscription<List<ConnectivityResult>>? _connectivity;

  RegistryRepository get _repository => ref.read(registryRepositoryProvider);

  @override
  RegistryState build() {
    _connectivity = Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((result) => result != ConnectivityResult.none)) {
        synchronize();
      }
    });
    ref.onDispose(() => _connectivity?.cancel());
    Future<void>.microtask(load);
    return const RegistryState(loading: true);
  }

  Future<void> load() async {
    try {
      final pending = await _repository.pendingCount();
      final applications = await _repository.applications();
      state = state.copyWith(
        applications: applications,
        pendingOffline: pending,
        loading: false,
        clearFeedback: true,
      );
    } catch (error) {
      state = state.copyWith(
        pendingOffline: await _repository.pendingCount(),
        loading: false,
        error: error.toString(),
      );
    }
  }

  Future<bool> submit(
    RegistryApplicationType type,
    Map<String, dynamic> payload,
  ) async {
    state = state.copyWith(loading: true, clearFeedback: true);
    try {
      final result = await _repository.submit(type, payload);
      final pending = await _repository.pendingCount();
      final applications = [
        if (result.application != null) result.application!,
        ...state.applications.where(
          (item) => item.id != result.application?.id,
        ),
      ];
      state = state.copyWith(
        applications: applications,
        pendingOffline: pending,
        loading: false,
        message: result.queuedOffline
            ? 'Saved securely. It will submit when connectivity returns.'
            : 'Registration application created.',
      );
      return true;
    } catch (error) {
      state = state.copyWith(loading: false, error: error.toString());
      return false;
    }
  }

  Future<void> synchronize() async {
    try {
      final count = await _repository.synchronize();
      if (count > 0) {
        await load();
        state = state.copyWith(
          message: '$count offline application(s) synchronized.',
        );
      } else {
        state = state.copyWith(
          pendingOffline: await _repository.pendingCount(),
        );
      }
    } catch (_) {
      state = state.copyWith(pendingOffline: await _repository.pendingCount());
    }
  }

  Future<bool> uploadDocument({
    required String applicationId,
    required String kind,
    required String filePath,
    String? documentNumber,
    DateTime? issueDate,
    DateTime? expiryDate,
  }) async {
    state = state.copyWith(loading: true, clearFeedback: true);
    try {
      await ref
          .read(registryDocumentClientProvider)
          .upload(
            applicationId: applicationId,
            kind: kind,
            filePath: filePath,
            documentNumber: documentNumber,
            issueDate: issueDate,
            expiryDate: expiryDate,
          );
      state = state.copyWith(
        loading: false,
        message: 'Document uploaded securely.',
      );
      return true;
    } catch (error) {
      state = state.copyWith(loading: false, error: error.toString());
      return false;
    }
  }
}

final registryControllerProvider =
    NotifierProvider<RegistryController, RegistryState>(RegistryController.new);

class RegistryAdminState {
  const RegistryAdminState({
    this.dashboard = const {},
    this.queue = const [],
    this.loading = false,
    this.error,
  });

  final Map<String, dynamic> dashboard;
  final List<RegistryApplication> queue;
  final bool loading;
  final String? error;
}

class RegistryAdminController extends Notifier<RegistryAdminState> {
  RegistryRepository get _repository => ref.read(registryRepositoryProvider);

  @override
  RegistryAdminState build() {
    Future<void>.microtask(load);
    return const RegistryAdminState(loading: true);
  }

  Future<void> load() async {
    state = RegistryAdminState(
      dashboard: state.dashboard,
      queue: state.queue,
      loading: true,
    );
    try {
      final results = await Future.wait([
        _repository.verificationDashboard(),
        _repository.complianceDashboard(),
        _repository.verificationQueue(),
      ]);
      final dashboard = <String, dynamic>{
        ...(results[0] as Map<String, dynamic>),
        ...(results[1] as Map<String, dynamic>),
      };
      state = RegistryAdminState(
        dashboard: dashboard,
        queue: results[2] as List<RegistryApplication>,
      );
    } catch (error) {
      state = RegistryAdminState(error: error.toString());
    }
  }

  Future<void> action(
    RegistryApplication application,
    String action, {
    String reason = '',
  }) async {
    state = RegistryAdminState(
      dashboard: state.dashboard,
      queue: state.queue,
      loading: true,
    );
    try {
      await _repository.workflowAction(
        application.id,
        action,
        reason: reason,
        comments: 'Reviewed in Registry Admin Portal',
      );
      await load();
    } catch (error) {
      state = RegistryAdminState(
        dashboard: state.dashboard,
        queue: state.queue,
        error: error.toString(),
      );
    }
  }
}

final registryAdminControllerProvider =
    NotifierProvider<RegistryAdminController, RegistryAdminState>(
      RegistryAdminController.new,
    );

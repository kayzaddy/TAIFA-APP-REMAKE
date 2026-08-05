import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/ecosystem/ecosystem_client.dart';
import '../../wallet/application/wallet_providers.dart' show apiClientProvider, apiConfigProvider;
import '../domain/super_app_module_registry.dart';

final ecosystemClientProvider = Provider<EcosystemClient>(
  (ref) => EcosystemClient(ref.watch(apiClientProvider)),
);

class EnabledModulesState {
  const EnabledModulesState({
    this.modules = const [],
    this.isLoading = false,
    this.error,
  });

  final List<EnabledSuperAppModule> modules;
  final bool isLoading;
  final String? error;

  Set<String> get enabledRoutes => SuperAppModuleRegistry.enabledRoutes(modules);

  bool isRouteEnabled(String route) => enabledRoutes.contains(route);

  EnabledModulesState copyWith({
    List<EnabledSuperAppModule>? modules,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return EnabledModulesState(
      modules: modules ?? this.modules,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class EnabledModulesController extends Notifier<EnabledModulesState> {
  EcosystemClient get _client => ref.read(ecosystemClientProvider);

  @override
  EnabledModulesState build() {
    Future.microtask(load);
    return EnabledModulesState(
      modules: SuperAppModuleRegistry.localDefaults(),
      isLoading: true,
    );
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (!ref.read(apiConfigProvider).useRemoteBackend) {
        state = EnabledModulesState(
          modules: SuperAppModuleRegistry.localDefaults(),
          isLoading: false,
        );
        return;
      }
      final rows = await _client.myModules();
      state = EnabledModulesState(
        modules: SuperAppModuleRegistry.fromApiRows(rows),
        isLoading: false,
      );
    } catch (e) {
      state = EnabledModulesState(
        modules: SuperAppModuleRegistry.localDefaults(),
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> setEnabled(String code, bool enabled) async {
    if (!ref.read(apiConfigProvider).useRemoteBackend) {
      final updated = state.modules
          .map(
            (m) => m.meta.code == code
                ? EnabledSuperAppModule(meta: m.meta, enabled: enabled)
                : m,
          )
          .toList();
      state = state.copyWith(modules: updated);
      return;
    }
    try {
      await _client.setModuleEnabled(moduleCode: code, enabled: enabled);
      await load();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final enabledModulesProvider =
    NotifierProvider<EnabledModulesController, EnabledModulesState>(
  EnabledModulesController.new,
);

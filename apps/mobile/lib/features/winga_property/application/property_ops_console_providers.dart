import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/winga_property/rest_property_repository.dart';
import '../../wallet/application/wallet_providers.dart'
    show apiClientProvider, apiConfigProvider;
import '../domain/property_models.dart';
import 'property_repository.dart';
import 'seed_property_repository.dart';

class PropertyOpsConsoleState {
  const PropertyOpsConsoleState({
    this.console,
    this.isBusy = false,
    this.error,
    this.selectedTab = 0,
  });

  final PropertyOpsConsole? console;
  final bool isBusy;
  final String? error;
  final int selectedTab;

  PropertyOpsConsoleState copyWith({
    PropertyOpsConsole? console,
    bool? isBusy,
    String? error,
    int? selectedTab,
    bool clearError = false,
  }) {
    return PropertyOpsConsoleState(
      console: console ?? this.console,
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : (error ?? this.error),
      selectedTab: selectedTab ?? this.selectedTab,
    );
  }
}

class PropertyOpsConsoleController extends Notifier<PropertyOpsConsoleState> {
  PropertyRepository get _repo {
    if (ref.read(apiConfigProvider).useRemoteBackend) {
      return RestPropertyRepository(ref.read(apiClientProvider));
    }
    return SeedPropertyRepository();
  }

  @override
  PropertyOpsConsoleState build() => const PropertyOpsConsoleState();

  Future<void> bootstrap() async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final console = await _repo.loadOpsConsole();
      state = state.copyWith(console: console, isBusy: false);
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  void setTab(int index) {
    state = state.copyWith(selectedTab: index);
  }

  Future<void> dismissReport(String reportId) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      await _repo.resolveModerationReport(reportId, action: 'dismiss');
      await bootstrap();
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> suspendFromReport(String reportId) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      await _repo.resolveModerationReport(reportId, action: 'suspend_listing');
      await bootstrap();
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }
}

final propertyOpsConsoleProvider =
    NotifierProvider<PropertyOpsConsoleController, PropertyOpsConsoleState>(
  PropertyOpsConsoleController.new,
);

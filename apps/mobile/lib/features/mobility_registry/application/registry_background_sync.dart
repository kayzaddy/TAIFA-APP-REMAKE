import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import '../../../data/api/api_client.dart';
import '../../../data/api/api_config.dart';
import '../../../data/auth/device_session.dart';
import '../../../data/mobility_registry/rest_registry_repository.dart';

const _registrySyncTask = 'taifa.mobility_registry.sync';

@pragma('vm:entry-point')
void mobilityRegistryCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != _registrySyncTask && task != Workmanager.iOSBackgroundTask) {
      return true;
    }
    final config = ApiConfig.fromEnvironment();
    if (!config.useRemoteBackend) return true;
    final session = DeviceSession(config);
    final client = HttpApiClient(config: config, session: session);
    final repository = RestRegistryRepository(client);
    try {
      await repository.synchronize();
      return true;
    } catch (_) {
      return false;
    }
  });
}

Future<void> initializeRegistryBackgroundSync() async {
  if (!(Platform.isAndroid || Platform.isIOS)) return;
  WidgetsFlutterBinding.ensureInitialized();
  await Workmanager().initialize(mobilityRegistryCallbackDispatcher);
  await Workmanager().registerPeriodicTask(
    _registrySyncTask,
    _registrySyncTask,
    frequency: const Duration(minutes: 15),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    constraints: Constraints(networkType: NetworkType.connected),
  );
}

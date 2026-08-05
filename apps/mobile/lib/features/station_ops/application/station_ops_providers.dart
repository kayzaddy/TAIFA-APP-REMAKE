import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/trips/mobility_ops_client.dart';
import '../../wallet/application/wallet_providers.dart' show apiClientProvider;

final mobilityOpsClientProvider = Provider<MobilityOpsClient>(
  (ref) => MobilityOpsClient(ref.watch(apiClientProvider)),
);

class StationOpsState {
  const StationOpsState({
    this.stations = const [],
    this.selectedStationId,
    this.dashboard = const {},
    this.queue = const [],
    this.loading = false,
    this.error,
  });

  final List<Map<String, dynamic>> stations;
  final String? selectedStationId;
  final Map<String, dynamic> dashboard;
  final List<Map<String, dynamic>> queue;
  final bool loading;
  final String? error;

  StationOpsState copyWith({
    List<Map<String, dynamic>>? stations,
    String? selectedStationId,
    Map<String, dynamic>? dashboard,
    List<Map<String, dynamic>>? queue,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return StationOpsState(
      stations: stations ?? this.stations,
      selectedStationId: selectedStationId ?? this.selectedStationId,
      dashboard: dashboard ?? this.dashboard,
      queue: queue ?? this.queue,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class StationOpsController extends Notifier<StationOpsState> {
  MobilityOpsClient get _client => ref.read(mobilityOpsClientProvider);

  @override
  StationOpsState build() => const StationOpsState(loading: true);

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final stations = await _client.managedStations();
      if (stations.isEmpty) {
        state = state.copyWith(
          stations: const [],
          loading: false,
          dashboard: const {},
          queue: const [],
        );
        return;
      }
      final selected =
          state.selectedStationId ?? stations.first['id'].toString();
      await selectStation(selected, stations: stations);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> selectStation(
    String stationId, {
    List<Map<String, dynamic>>? stations,
  }) async {
    state = state.copyWith(
      loading: true,
      selectedStationId: stationId,
      stations: stations ?? state.stations,
      clearError: true,
    );
    try {
      final dashboard = await _client.stationDashboard(stationId);
      final queue = await _client.stationQueue(stationId);
      state = state.copyWith(
        dashboard: dashboard,
        queue: queue,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> moveDriverUp(String driverId) async {
    final stationId = state.selectedStationId;
    if (stationId == null) return;
    final ids = state.queue.map((e) => e['driver'].toString()).toList();
    final index = ids.indexOf(driverId);
    if (index <= 0) return;
    final swapped = [...ids];
    swapped[index - 1] = ids[index];
    swapped[index] = ids[index - 1];
    state = state.copyWith(loading: true, clearError: true);
    try {
      final queue = await _client.reorderQueue(
        stationId: stationId,
        orderedDriverIds: swapped,
      );
      state = state.copyWith(queue: queue, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }
}

final stationOpsControllerProvider =
    NotifierProvider<StationOpsController, StationOpsState>(
      StationOpsController.new,
    );

class MobilityDriverState {
  const MobilityDriverState({
    this.profile = const {},
    this.earnings = const {},
    this.offers = const [],
    this.loading = false,
    this.error,
  });

  final Map<String, dynamic> profile;
  final Map<String, dynamic> earnings;
  final List<Map<String, dynamic>> offers;
  final bool loading;
  final String? error;

  MobilityDriverState copyWith({
    Map<String, dynamic>? profile,
    Map<String, dynamic>? earnings,
    List<Map<String, dynamic>>? offers,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return MobilityDriverState(
      profile: profile ?? this.profile,
      earnings: earnings ?? this.earnings,
      offers: offers ?? this.offers,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class MobilityDriverController extends Notifier<MobilityDriverState> {
  MobilityOpsClient get _client => ref.read(mobilityOpsClientProvider);

  @override
  MobilityDriverState build() => const MobilityDriverState(loading: true);

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final profile = await _client.driverProfile();
      final earnings = await _client.earnings();
      final offers = await _client.pendingOffers();
      state = state.copyWith(
        profile: profile,
        earnings: earnings,
        offers: offers,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> setAvailability(String availability) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final profile = await _client.setAvailability(availability);
      final stationId = profile['station']?.toString();
      if (availability == 'available' &&
          stationId != null &&
          stationId.isNotEmpty) {
        await _client.joinQueue(stationId);
      }
      if (availability == 'offline' &&
          stationId != null &&
          stationId.isNotEmpty) {
        await _client.leaveQueue(stationId);
      }
      await load();
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> acceptOffer(String offerId) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      await _client.acceptOffer(offerId);
      await load();
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> rejectOffer(String offerId) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      await _client.rejectOffer(offerId, reason: 'driver_declined');
      await load();
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> sos() async {
    try {
      await _client.reportSos(latitude: -6.8162, longitude: 39.2804);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final mobilityDriverControllerProvider =
    NotifierProvider<MobilityDriverController, MobilityDriverState>(
      MobilityDriverController.new,
    );

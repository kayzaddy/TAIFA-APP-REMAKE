import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/trips/mobility_ops_client.dart';
import '../../../data/trips/rest_trip_repository.dart';
import '../../wallet/application/wallet_providers.dart'
    show apiClientProvider, apiConfigProvider;
import '../data/dar_places.dart';
import '../domain/driver.dart';
import '../domain/place.dart';
import '../domain/ride_product.dart';
import '../domain/route_plan.dart';
import '../domain/trip.dart';
import '../gateways/maps_provider.dart';
import '../gateways/mock_location_gateway.dart';
import '../gateways/mock_maps_provider.dart';
import '../gateways/mock_matching_gateway.dart';
import '../gateways/mock_pricing_gateway.dart';
import '../gateways/mock_route_gateway.dart';
import 'ride_service.dart';
import 'seed_trip_repository.dart';
import 'trip_repository.dart';

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  final config = ref.watch(apiConfigProvider);
  if (config.useRemoteBackend) {
    return RestTripRepository(ref.watch(apiClientProvider));
  }
  return SeedTripRepository();
});

/// Swap [MockMapsProvider] for Google/Mapbox without touching Mobility UI.
final mapsProviderProvider = Provider<MapsProvider>(
  (ref) => const MockMapsProvider(),
);

final rideServiceProvider = Provider<RideService>((ref) {
  return RideService(
    location: MockLocationGateway(),
    routing: MockRouteGateway(),
    pricing: MockPricingGateway(),
    matching: MockMatchingGateway(),
    trips: ref.watch(tripRepositoryProvider),
  );
});

/// High-level phases for UI routing / sheets.
enum RidePhase {
  home,
  pickingPlaces,
  quoting,
  requesting,
  searching,
  assigned,
  enRoute,
  arrived,
  inTrip,
  completed,
  receipt,
  history,
}

class RideUiState {
  const RideUiState({
    this.phase = RidePhase.home,
    this.pickup,
    this.dropoff,
    this.route,
    this.quotes = const [],
    this.selectedProductId,
    this.trip,
    this.driver,
    this.isBusy = false,
    this.error,
    this.history = const [],
    this.tripProgress = 0,
    this.dispatchMessage = 'Finding your nearest driver…',
    this.featurePhoneDemo = false,
    this.smsPreview = '',
    this.smsDriverName = '',
    this.smsDriverPhone = '',
  });

  final RidePhase phase;
  final Place? pickup;
  final Place? dropoff;
  final RoutePlan? route;
  final List<FareEstimate> quotes;
  final String? selectedProductId;
  final Trip? trip;
  final Driver? driver;
  final bool isBusy;
  final String? error;
  final List<Trip> history;
  final double tripProgress; // 0..1 during inTrip
  final String dispatchMessage;
  final bool featurePhoneDemo;
  final String smsPreview;
  final String smsDriverName;
  final String smsDriverPhone;

  FareEstimate? get selectedQuote {
    if (quotes.isEmpty) return null;
    final id = selectedProductId ?? quotes.first.product.id;
    for (final q in quotes) {
      if (q.product.id == id) return q;
    }
    return quotes.first;
  }

  RideUiState copyWith({
    RidePhase? phase,
    Place? pickup,
    Place? dropoff,
    RoutePlan? route,
    List<FareEstimate>? quotes,
    String? selectedProductId,
    Trip? trip,
    Driver? driver,
    bool? isBusy,
    String? error,
    List<Trip>? history,
    double? tripProgress,
    String? dispatchMessage,
    bool? featurePhoneDemo,
    String? smsPreview,
    String? smsDriverName,
    String? smsDriverPhone,
    bool clearError = false,
    bool clearTrip = false,
  }) {
    return RideUiState(
      phase: phase ?? this.phase,
      pickup: pickup ?? this.pickup,
      dropoff: dropoff ?? this.dropoff,
      route: route ?? this.route,
      quotes: quotes ?? this.quotes,
      selectedProductId: selectedProductId ?? this.selectedProductId,
      trip: clearTrip ? null : (trip ?? this.trip),
      driver: driver ?? this.driver,
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : (error ?? this.error),
      history: history ?? this.history,
      tripProgress: tripProgress ?? this.tripProgress,
      dispatchMessage: dispatchMessage ?? this.dispatchMessage,
      featurePhoneDemo: featurePhoneDemo ?? this.featurePhoneDemo,
      smsPreview: smsPreview ?? this.smsPreview,
      smsDriverName: smsDriverName ?? this.smsDriverName,
      smsDriverPhone: smsDriverPhone ?? this.smsDriverPhone,
    );
  }
}

class RideController extends Notifier<RideUiState> {
  StreamSubscription<Driver>? _trackSub;
  Timer? _lifecycleTimer;
  Timer? _hybridStatusTimer;
  Timer? _dispatchDetailTimer;

  RideService get _svc => ref.read(rideServiceProvider);

  @override
  RideUiState build() {
    ref.onDispose(() {
      _trackSub?.cancel();
      _lifecycleTimer?.cancel();
      _hybridStatusTimer?.cancel();
      _dispatchDetailTimer?.cancel();
    });
    final useRemote = ref.read(apiConfigProvider).useRemoteBackend;
    return RideUiState(
      pickup: DarPlaces.masaki,
      featurePhoneDemo: useRemote,
    );
  }

  Future<void> bootstrap() async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final point = await _svc.location.currentLocation();
      final here = await _svc.location.reverseGeocode(point);
      final history = await _svc.trips.history();
      state = state.copyWith(
        pickup: here,
        history: history,
        isBusy: false,
        phase: RidePhase.home,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  void openPlacePicker() {
    state = state.copyWith(phase: RidePhase.pickingPlaces, clearError: true);
  }

  void openHistory() {
    state = state.copyWith(phase: RidePhase.history, clearError: true);
  }

  void backToHome() {
    _trackSub?.cancel();
    _lifecycleTimer?.cancel();
    _hybridStatusTimer?.cancel();
    _dispatchDetailTimer?.cancel();
    state = state.copyWith(
      phase: RidePhase.home,
      clearError: true,
      clearTrip: true,
      tripProgress: 0,
      quotes: const [],
      selectedProductId: null,
    );
  }

  void setPickup(Place place) {
    state = state.copyWith(pickup: place);
  }

  void setDropoff(Place place) {
    state = state.copyWith(dropoff: place);
  }

  Future<void> confirmPlaces() async {
    final pickup = state.pickup;
    final dropoff = state.dropoff;
    if (pickup == null || dropoff == null) {
      state = state.copyWith(error: 'Choose pickup and destination.');
      return;
    }
    if (pickup.id == dropoff.id) {
      state = state.copyWith(error: 'Destination must differ from pickup.');
      return;
    }
    state = state.copyWith(
      isBusy: true,
      clearError: true,
      phase: RidePhase.quoting,
    );
    try {
      final route = await _svc.plan(pickup, dropoff);
      final quotes = await _svc.quote(route, pickup);
      state = state.copyWith(
        route: route,
        quotes: quotes,
        selectedProductId: quotes.isEmpty ? null : quotes.first.product.id,
        isBusy: false,
      );
    } catch (e) {
      state = state.copyWith(
        isBusy: false,
        error: e.toString(),
        phase: RidePhase.pickingPlaces,
      );
    }
  }

  void selectProduct(String productId) {
    state = state.copyWith(selectedProductId: productId);
  }

  void setFeaturePhoneDemo(bool enabled) {
    state = state.copyWith(featurePhoneDemo: enabled);
  }

  Future<void> requestRide() async {
    final pickup = state.pickup;
    final dropoff = state.dropoff;
    final route = state.route;
    final quote = state.selectedQuote;
    if (pickup == null || dropoff == null || route == null || quote == null) {
      state = state.copyWith(
        error: 'Complete pickup, destination and fare first.',
      );
      return;
    }

    state = state.copyWith(
      isBusy: true,
      clearError: true,
      phase: RidePhase.requesting,
    );
    try {
      var trip = await _svc.requestRide(
        pickup: pickup,
        dropoff: dropoff,
        product: quote.product,
        route: route,
        hybridSmsDemo: state.featurePhoneDemo &&
            ref.read(apiConfigProvider).useRemoteBackend,
        passengerMsisdn: '+255700111222',
      );
      state = state.copyWith(
        trip: trip,
        phase: RidePhase.searching,
        isBusy: false,
        dispatchMessage: state.featurePhoneDemo
            ? 'Contacting nearby riders via SMS…'
            : 'Finding your nearest driver…',
        smsPreview: '',
        smsDriverName: '',
        smsDriverPhone: '',
      );

      _startHybridStatusPolling(trip.id);
      if (state.featurePhoneDemo &&
          ref.read(apiConfigProvider).useRemoteBackend) {
        _startDispatchDetailPolling(trip.id);
        return;
      }

      trip = await _svc.assignDriver(trip);
      _hybridStatusTimer?.cancel();
      _dispatchDetailTimer?.cancel();
      await _onDriverAssigned(trip);
    } catch (e) {
      state = state.copyWith(
        isBusy: false,
        error: e.toString(),
        phase: RidePhase.quoting,
      );
    }
  }

  Future<void> _onDriverAssigned(Trip trip) async {
    state = state.copyWith(
      trip: trip,
      driver: trip.driver,
      phase: RidePhase.assigned,
      smsPreview: '',
    );
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!ref.mounted) return;
    trip = await _svc.setStatus(trip, TripStatus.driverEnRoute);
    state = state.copyWith(trip: trip, phase: RidePhase.enRoute);
    _beginApproach(trip);
  }

  Future<void> simulateFeaturePhoneAccept() async {
    final trip = state.trip;
    if (trip == null) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final client = MobilityOpsClient(ref.read(apiClientProvider));
      await client.simulateFeaturePhoneSmsAccept(trip.id);
      final updated = await _svc.trips.getById(trip.id);
      _hybridStatusTimer?.cancel();
      _dispatchDetailTimer?.cancel();
      state = state.copyWith(isBusy: false);
      await _onDriverAssigned(updated);
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  void _beginApproach(Trip trip) {
    _trackSub?.cancel();
    _trackSub = _svc
        .watchDriverApproach(trip)
        .listen(
          (driver) async {
            state = state.copyWith(driver: driver);
          },
          onDone: () async {
            if (!ref.mounted) return;
            final current = state.trip;
            if (current == null) return;
            var next = await _svc.setStatus(
              current,
              TripStatus.driverArrived,
              driver: state.driver,
            );
            state = state.copyWith(
              trip: next,
              driver: next.driver,
              phase: RidePhase.arrived,
            );
            // Auto-start trip after a short dwell (demo).
            await Future<void>.delayed(const Duration(milliseconds: 1600));
            if (!ref.mounted) return;
            await startTrip();
          },
        );
  }

  Future<void> startTrip() async {
    final trip = state.trip;
    if (trip == null) return;
    final route = state.route;
    final next = await _svc.setStatus(
      trip,
      TripStatus.inProgress,
      driver: state.driver,
    );
    // Snap driver onto the route start for live tracking.
    final startDriver = state.driver == null || route == null
        ? state.driver
        : state.driver!.copyWith(location: route.pointAt(0));
    state = state.copyWith(
      trip: next,
      driver: startDriver,
      phase: RidePhase.inTrip,
      tripProgress: 0,
    );
    _lifecycleTimer?.cancel();
    const ticks = 20;
    var i = 0;
    _lifecycleTimer = Timer.periodic(const Duration(milliseconds: 280), (
      t,
    ) async {
      i++;
      if (!ref.mounted) {
        t.cancel();
        return;
      }
      final progress = i / ticks;
      final driver = state.driver;
      final along = route;
      state = state.copyWith(
        tripProgress: progress,
        driver: driver == null || along == null
            ? driver
            : driver.copyWith(location: along.pointAt(progress)),
      );
      if (i >= ticks) {
        t.cancel();
        await completeTrip();
      }
    });
  }

  Future<void> completeTrip() async {
    final trip = state.trip;
    if (trip == null) return;
    final next = await _svc.setStatus(
      trip,
      TripStatus.completed,
      driver: state.driver,
    );
    state = state.copyWith(
      trip: next,
      phase: RidePhase.completed,
      tripProgress: 1,
    );
  }

  Future<void> confirmPayment() async {
    final trip = state.trip;
    if (trip == null) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final paid = await _svc.pay(trip);
      final history = await _svc.trips.history();
      state = state.copyWith(
        trip: paid,
        phase: RidePhase.receipt,
        isBusy: false,
        history: history,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  void _startHybridStatusPolling(String tripId) {
    _hybridStatusTimer?.cancel();
    final config = ref.read(apiConfigProvider);
    if (!config.useRemoteBackend) return;
    final client = MobilityOpsClient(ref.read(apiClientProvider));
    _hybridStatusTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      try {
        final json = await client.hybridTripStatus(tripId);
        final message = json['message']?.toString();
        if (message != null && message.isNotEmpty && ref.mounted) {
          state = state.copyWith(dispatchMessage: message);
        }
      } catch (_) {
        // Keep last message — dispatch channel is opaque to passenger.
      }
    });
  }

  void _startDispatchDetailPolling(String tripId) {
    _dispatchDetailTimer?.cancel();
    final client = MobilityOpsClient(ref.read(apiClientProvider));
    _dispatchDetailTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      try {
        final json = await client.hybridDispatchDetail(tripId);
        if (!ref.mounted) return;
        state = state.copyWith(
          smsPreview: json['sms_preview']?.toString() ?? '',
          smsDriverName: json['sms_driver_name']?.toString() ?? '',
          smsDriverPhone: json['sms_to']?.toString() ?? '',
        );
      } catch (_) {}
    });
  }

  Future<void> cancelSearch() async {
    _trackSub?.cancel();
    _lifecycleTimer?.cancel();
    _hybridStatusTimer?.cancel();
    _dispatchDetailTimer?.cancel();
    final trip = state.trip;
    if (trip != null) {
      await _svc.setStatus(trip, TripStatus.cancelled);
    }
    state = state.copyWith(phase: RidePhase.quoting, clearTrip: true);
  }

  Future<void> triggerSos() async {
    final trip = state.trip;
    final client = MobilityOpsClient(ref.read(apiClientProvider));
    try {
      await client.reportSos(
        latitude: trip?.pickup.point.latitude ?? -6.8162,
        longitude: trip?.pickup.point.longitude ?? 39.2804,
        tripId: trip?.id,
      );
      state = state.copyWith(error: 'SOS sent to operations');
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final rideControllerProvider = NotifierProvider<RideController, RideUiState>(
  RideController.new,
);

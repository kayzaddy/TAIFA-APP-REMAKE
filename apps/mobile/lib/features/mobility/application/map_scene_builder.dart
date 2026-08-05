import '../data/dar_places.dart';
import '../domain/map_scene.dart';
import 'ride_providers.dart';

/// Builds a [MapScene] from ride UI state — the only place Mobility UI
/// translates phases into map camera / markers / progress.
MapScene mapSceneForRide(RideUiState state) {
  final follow =
      state.phase == RidePhase.enRoute ||
      state.phase == RidePhase.arrived ||
      state.phase == RidePhase.inTrip;
  final driverLoc = state.driver?.location;
  final fallback =
      state.pickup?.point ?? state.dropoff?.point ?? DarPlaces.masaki.point;

  return MapScene(
    cameraTarget: (follow && driverLoc != null) ? driverLoc : fallback,
    route: state.route,
    pickup: state.pickup?.point,
    dropoff: state.dropoff?.point,
    driver: driverLoc,
    progress: state.phase == RidePhase.inTrip ? state.tripProgress : 0,
    followDriver: follow,
  );
}

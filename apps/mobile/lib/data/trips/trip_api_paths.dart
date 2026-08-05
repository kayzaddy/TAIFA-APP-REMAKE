/// Canonical REST path fragments for the Mobility Trip API.
class TripApiPaths {
  const TripApiPaths._();

  /// Trailing slash matches Django `api/v1/trips/` mount.
  static const trips = 'trips/';

  static String trip(String tripId) => 'trips/$tripId';

  static String payment(String tripId) => 'trips/$tripId/payment';

  static const stations = 'trips/stations';

  static const nearbyStations = 'trips/stations/nearby';

  static String stationDashboard(String stationId) =>
      'trips/stations/$stationId/dashboard';

  static String stationQueue(String stationId) =>
      'trips/stations/$stationId/queue';

  static String stationQueueLeave(String stationId) =>
      'trips/stations/$stationId/queue/leave';

  static String stationQueueReorder(String stationId) =>
      'trips/stations/$stationId/queue/reorder';

  static const driverProfile = 'trips/driver/profile';

  static const driverAvailability = 'trips/driver/availability';

  static const driverEarnings = 'trips/driver/earnings';

  static const driverOffers = 'trips/driver/offers';

  static String driverOfferAccept(String offerId) =>
      'trips/driver/offers/$offerId/accept';

  static String driverOfferReject(String offerId) =>
      'trips/driver/offers/$offerId/reject';

  static const driverLocations = 'trips/driver/locations';

  static const operationsDashboard = 'trips/operations/dashboard';

  static const cityMap = 'trips/city/map';

  static const cityOperations = 'trips/city/operations';

  static const cityAnalytics = 'trips/city/analytics';

  static const stationRankings = 'trips/stations/rankings';

  static String stationIntelligence(String stationId) =>
      'trips/stations/$stationId/intelligence';

  static String fleetIntelligence(String fleetId) =>
      'trips/fleets/$fleetId/intelligence';

  static const driverPerformance = 'trips/driver/performance';

  static const driverRankings = 'trips/drivers/rankings';

  static const safetyIncidentsList = 'trips/safety/incidents/list';

  static String safetyIncident(String incidentId) =>
      'trips/safety/incidents/$incidentId';

  static const notifications = 'trips/notifications';

  static const safetyIncidents = 'trips/safety/incidents';

  static const ratings = 'trips/ratings';

  static const nationalCommandCenter = 'trips/national/command-center';

  static const nationalMap = 'trips/national/map';

  static const nationalAnalytics = 'trips/national/analytics';

  static const nationalOptimization = 'trips/national/optimization';

  static const nationalReports = 'trips/national/reports';

  static const openCatalog = 'trips/open/catalog';

  static String hybridTripStatus(String tripId) =>
      'mobility-channels/trips/$tripId/status';

  static String hybridDispatchDetail(String tripId) =>
      'mobility-channels/trips/$tripId/dispatch-detail';

  static String hybridSimulateSmsAccept(String tripId) =>
      'mobility-channels/trips/$tripId/simulate-sms-accept';
}

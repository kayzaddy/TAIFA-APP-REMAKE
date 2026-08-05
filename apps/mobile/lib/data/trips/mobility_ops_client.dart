import '../api/api_client.dart';
import 'trip_api_paths.dart';

/// Live mobility operations client against `/api/v1/trips/*`.
class MobilityOpsClient {
  MobilityOpsClient(this._client);

  final TaifaApiClient _client;

  Future<List<Map<String, dynamic>>> managedStations() async {
    final list = await _client.getJsonList(
      '${TripApiPaths.stations}?managed=1',
    );
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<Map<String, dynamic>> stationDashboard(String stationId) {
    return _client.getJson(TripApiPaths.stationDashboard(stationId));
  }

  Future<List<Map<String, dynamic>>> stationQueue(String stationId) async {
    final list = await _client.getJsonList(TripApiPaths.stationQueue(stationId));
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<List<Map<String, dynamic>>> reorderQueue({
    required String stationId,
    required List<String> orderedDriverIds,
  }) async {
    final json = await _client.postJson(
      TripApiPaths.stationQueueReorder(stationId),
      body: {'ordered_driver_ids': orderedDriverIds},
    );
    final queue = json['queue'];
    if (queue is! List) {
      return stationQueue(stationId);
    }
    return queue
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<Map<String, dynamic>> driverProfile() {
    return _client.getJson(TripApiPaths.driverProfile);
  }

  Future<Map<String, dynamic>> setAvailability(String availability) {
    return _client.postJson(
      TripApiPaths.driverAvailability,
      body: {'availability': availability},
    );
  }

  Future<Map<String, dynamic>> earnings() {
    return _client.getJson(TripApiPaths.driverEarnings);
  }

  Future<List<Map<String, dynamic>>> pendingOffers() async {
    final list = await _client.getJsonList(TripApiPaths.driverOffers);
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<Map<String, dynamic>> acceptOffer(String offerId) {
    return _client.postJson(TripApiPaths.driverOfferAccept(offerId));
  }

  Future<Map<String, dynamic>> rejectOffer(String offerId, {String reason = ''}) {
    return _client.postJson(
      TripApiPaths.driverOfferReject(offerId),
      body: {'reason': reason},
    );
  }

  Future<void> joinQueue(String stationId) async {
    await _client.postJson(TripApiPaths.stationQueue(stationId));
  }

  Future<void> leaveQueue(String stationId) async {
    await _client.postJson(TripApiPaths.stationQueueLeave(stationId));
  }

  Future<Map<String, dynamic>> operationsDashboard({
    String region = '',
    String district = '',
  }) {
    final query = <String>[];
    if (region.isNotEmpty) query.add('region=${Uri.encodeQueryComponent(region)}');
    if (district.isNotEmpty) {
      query.add('district=${Uri.encodeQueryComponent(district)}');
    }
    final suffix = query.isEmpty ? '' : '?${query.join('&')}';
    return _client.getJson('${TripApiPaths.operationsDashboard}$suffix');
  }

  Future<Map<String, dynamic>> cityOperations({
    required String region,
    String district = '',
  }) {
    final query = 'region=${Uri.encodeQueryComponent(region)}'
        '${district.isEmpty ? '' : '&district=${Uri.encodeQueryComponent(district)}'}';
    return _client.getJson('${TripApiPaths.cityOperations}?$query');
  }

  Future<Map<String, dynamic>> cityMap({
    required String region,
    String district = '',
  }) {
    final query = 'region=${Uri.encodeQueryComponent(region)}'
        '${district.isEmpty ? '' : '&district=${Uri.encodeQueryComponent(district)}'}';
    return _client.getJson('${TripApiPaths.cityMap}?$query');
  }

  Future<Map<String, dynamic>> fleetIntelligence(String fleetId) {
    return _client.getJson(TripApiPaths.fleetIntelligence(fleetId));
  }

  Future<List<Map<String, dynamic>>> listFleets() async {
    final list = await _client.getJsonList('trips/fleets');
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<List<Map<String, dynamic>>> listIncidents({String region = ''}) async {
    final path = region.isEmpty
        ? TripApiPaths.safetyIncidentsList
        : '${TripApiPaths.safetyIncidentsList}?region=${Uri.encodeQueryComponent(region)}';
    final list = await _client.getJsonList(path);
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<Map<String, dynamic>> advanceIncident({
    required String incidentId,
    required String status,
    String notes = '',
  }) {
    return _client.patchJson(
      TripApiPaths.safetyIncident(incidentId),
      body: {'status': status, 'notes': notes},
    );
  }

  Future<Map<String, dynamic>> reportSos({
    required double latitude,
    required double longitude,
    String? tripId,
  }) {
    return _client.postJson(
      TripApiPaths.safetyIncidents,
      body: {
        'kind': 'sos',
        'severity': 'critical',
        'latitude': latitude.toStringAsFixed(6),
        'longitude': longitude.toStringAsFixed(6),
        'trip': ?tripId,
        'details': {'source': 'mobile'},
      },
    );
  }

  Future<List<Map<String, dynamic>>> notifications() async {
    final list = await _client.getJsonList(TripApiPaths.notifications);
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<Map<String, dynamic>> nationalCommandCenter() {
    return _client.getJson(TripApiPaths.nationalCommandCenter);
  }

  Future<Map<String, dynamic>> nationalMap({String region = ''}) {
    final suffix = region.isEmpty
        ? ''
        : '?region=${Uri.encodeQueryComponent(region)}';
    return _client.getJson('${TripApiPaths.nationalMap}$suffix');
  }

  Future<Map<String, dynamic>> nationalAnalytics({
    String region = '',
    int days = 30,
  }) {
    final query = <String>['days=$days'];
    if (region.isNotEmpty) {
      query.add('region=${Uri.encodeQueryComponent(region)}');
    }
    return _client.getJson(
      '${TripApiPaths.nationalAnalytics}?${query.join('&')}',
    );
  }

  Future<Map<String, dynamic>> nationalOptimization() {
    return _client.getJson(TripApiPaths.nationalOptimization);
  }

  Future<Map<String, dynamic>> openCatalog() {
    return _client.getJson(TripApiPaths.openCatalog);
  }

  /// Channel-agnostic hybrid dispatch status for passenger UI.
  Future<Map<String, dynamic>> hybridTripStatus(String tripId) {
    return _client.getJson(TripApiPaths.hybridTripStatus(tripId));
  }

  Future<Map<String, dynamic>> hybridDispatchDetail(String tripId) {
    return _client.getJson(TripApiPaths.hybridDispatchDetail(tripId));
  }

  Future<Map<String, dynamic>> simulateFeaturePhoneSmsAccept(String tripId) {
    return _client.postJson(TripApiPaths.hybridSimulateSmsAccept(tripId));
  }
}

import '../domain/transit_models.dart';

abstract class TransitRepository {
  Future<TransitHome> loadHome({
    double? lat,
    double? lng,
    String region = 'Dar es Salaam',
    String mode = '',
  });

  Future<List<TransitMode>> loadModes({String region = 'Dar es Salaam'});

  Future<List<TransitRoute>> listRoutes({String region = '', String mode = ''});

  Future<TransitRoute> getRoute(String id);

  Future<List<TransitRoute>> search(String query, {String region = ''});

  Future<TransitTicket> purchaseTicket({
    required String routeId,
    required String productCode,
    String originStop = '',
    String destinationStop = '',
    required String idempotencyKey,
  });

  Future<List<TransitTicket>> myTickets();

  Future<List<TransitProduct>> listProducts({String mode = ''});

  Future<TransitStationDetail> getStation(String stopCode);

  Future<List<TransitPlanOption>> planJourney({
    required String originStop,
    required String destinationStop,
    String region = '',
  });

  Future<List<TransitScheduledRun>> driverRuns();

  Future<TransitScheduledRun> advanceDriverRun(String runId, String status);

  Future<TransitLiveMap> loadLiveMap({String region = 'Dar es Salaam', String routeId = ''});

  Future<TransitMapVehicle> pingAvl({
    required String vehicleLabel,
    required String routeId,
    required double latitude,
    required double longitude,
    int speedKmh = 0,
    String nextStopCode = '',
    int etaNextStopSeconds = 0,
  });

  Future<TransitProfileBundle> loadProfile();

  Future<TransitProfileBundle> updateProfile({
    String? homeStop,
    String? workStop,
    String? preferredLanguage,
    Map<String, dynamic>? accessibility,
  });

  Future<List<TransitFavorite>> listFavorites();

  Future<TransitFavorite> addFavorite({
    required String subjectType,
    required String subjectCode,
    String label = '',
  });

  Future<void> removeFavorite(String favoriteId);

  Future<List<TransitNotification>> listNotifications();

  Future<int> markNotificationsRead({List<String>? ids});

  Future<TransitFeedback> submitFeedback({
    required int rating,
    String comment = '',
    List<String> tags = const [],
    String? routeId,
    String? ticketId,
  });

  Future<TransitSosResult> reportSos({
    double? latitude,
    double? longitude,
    String stopCode = '',
    String? routeId,
    String vehicleLabel = '',
    String notes = '',
  });

  Future<TransitAnalytics> loadAnalytics({String region = 'Dar es Salaam', int days = 7});

  Future<TransitRoute> adminUpdateRoute(String routeId, Map<String, dynamic> body);

  Future<TransitProduct> adminUpdateProduct(String productId, Map<String, dynamic> body);

  Future<TransitProduct> adminCreateProduct(Map<String, dynamic> body);

  Future<TransitAssistantReply> askAssistant({
    required String query,
    String locale = '',
    String region = 'Dar es Salaam',
  });

  Future<TransitFamilyBundle> loadFamilyBundle();

  Future<List<TransitFamilyMember>> listFamilyMembers();

  Future<TransitFamilyMember> addFamilyMember({
    required String memberOwner,
    required String displayName,
    String relationship = 'child',
    int monthlyLimitMinor = 0,
  });

  Future<void> removeFamilyMember(String memberId);

  Future<TransitTicket> purchaseTicketForMember({
    required String routeId,
    required String productCode,
    required String beneficiaryOwner,
    required String idempotencyKey,
    String originStop = '',
    String destinationStop = '',
  });

  Future<TransitLostFoundBundle> loadLostFoundBundle({
    String kind = '',
    String stopCode = '',
  });

  Future<TransitLostFoundItem> reportLostFound({
    required String kind,
    required String title,
    String description = '',
    String category = 'other',
    String stopCode = '',
    String? routeId,
    String contactHint = '',
    String photoUrl = '',
  });

  Future<TransitLostFoundItem> claimLostFound({
    required String itemId,
    String message = '',
  });

  Future<TransitLostFoundItem> resolveLostFound({
    required String itemId,
    String status = 'closed',
  });

  Future<String> uploadLostFoundPhoto({
    required List<int> bytes,
    String contentType = 'image/jpeg',
  });

  Future<List<TransitLostFoundItem>> loadAdminLostFound({String status = ''});

  Future<TransitLostFoundItem> opsResolveLostFound({
    required String itemId,
    String status = 'closed',
  });
}

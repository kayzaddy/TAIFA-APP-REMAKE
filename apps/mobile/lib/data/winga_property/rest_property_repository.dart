import '../../features/winga_property/application/property_repository.dart';
import '../../features/winga_property/domain/property_models.dart';
import '../../features/wallet/domain/currency.dart';
import '../../features/wallet/domain/money.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import 'property_api_paths.dart';

class RestPropertyRepository implements PropertyRepository {
  RestPropertyRepository(this._client);

  final TaifaApiClient _client;

  @override
  bool get serverAuthoritative => true;

  @override
  Future<List<PropertyCategory>> categories() async {
    final list = await _client.getJsonList(PropertyApiPaths.categories);
    return list.whereType<Map>().map((e) {
      final m = Map<String, dynamic>.from(e);
      return PropertyCategory(
        code: m['code']?.toString() ?? '',
        name: m['name']?.toString() ?? '',
        icon: m['icon']?.toString() ?? '',
      );
    }).toList();
  }

  @override
  Future<List<PropertyListing>> search({
    String query = '',
    String region = '',
    String category = '',
    bool verifiedOnly = true,
  }) async {
    final queryParams = <String>[];
    if (query.isNotEmpty) queryParams.add('q=${Uri.encodeQueryComponent(query)}');
    if (region.isNotEmpty) {
      queryParams.add('region=${Uri.encodeQueryComponent(region)}');
    }
    if (category.isNotEmpty) {
      queryParams.add('category=${Uri.encodeQueryComponent(category)}');
    }
    if (verifiedOnly) queryParams.add('verified=1');
    final suffix = queryParams.isEmpty ? '' : '?${queryParams.join('&')}';
    final list = await _client.getJsonList('${PropertyApiPaths.listings}$suffix');
    return list
        .whereType<Map>()
        .map((e) => _listingFromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<List<PropertyListing>> advancedSearch({
    String query = '',
    String region = '',
    String category = '',
    String lifestyle = '',
    int? minBeds,
    int? minSafetyE4,
    int? minWalkabilityE4,
    bool verifiedOnly = true,
  }) async {
    final queryParams = <String>[];
    if (query.isNotEmpty) queryParams.add('q=${Uri.encodeQueryComponent(query)}');
    if (region.isNotEmpty) {
      queryParams.add('region=${Uri.encodeQueryComponent(region)}');
    }
    if (category.isNotEmpty) {
      queryParams.add('category=${Uri.encodeQueryComponent(category)}');
    }
    if (lifestyle.isNotEmpty) {
      queryParams.add('lifestyle=${Uri.encodeQueryComponent(lifestyle)}');
    }
    if (minBeds != null) queryParams.add('beds=$minBeds');
    if (minSafetyE4 != null) queryParams.add('min_safety_e4=$minSafetyE4');
    if (minWalkabilityE4 != null) {
      queryParams.add('min_walkability_e4=$minWalkabilityE4');
    }
    if (verifiedOnly) queryParams.add('verified=1');
    final suffix = queryParams.isEmpty ? '' : '?${queryParams.join('&')}';
    final list = await _client.getJsonList('${PropertyApiPaths.discoverySearch}$suffix');
    return list
        .whereType<Map>()
        .map((e) => _listingFromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<List<PropertyListing>> aiSearch({
    required String query,
    String lifestyle = '',
    String neighborhood = '',
  }) async {
    final json = await _client.postJson(
      PropertyApiPaths.discoveryAiSearch,
      body: {
        'query': query,
        if (lifestyle.isNotEmpty) 'lifestyle': lifestyle,
        if (neighborhood.isNotEmpty) 'neighborhood': neighborhood,
      },
    );
    final listings = json['listings'];
    if (listings is! List) return [];
    return listings
        .whereType<Map>()
        .map((e) => _listingFromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<List<PropertyListing>> recommendations({int limit = 6}) async {
    final list = await _client.getJsonList(
      '${PropertyApiPaths.discoveryRecommendations}?limit=$limit',
    );
    return list
        .whereType<Map>()
        .map((e) => _listingFromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<List<PropertyListing>> recentlyViewed({int limit = 8}) async {
    final list = await _client.getJsonList(
      '${PropertyApiPaths.discoveryRecentlyViewed}?limit=$limit',
    );
    return list
        .whereType<Map>()
        .map((e) => _listingFromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<List<PropertyCompareRow>> compare(List<String> listingIds) async {
    final json = await _client.postJson(
      PropertyApiPaths.discoveryCompare,
      body: {'listing_ids': listingIds},
    );
    final rows = json['listings'];
    if (rows is! List) return [];
    return rows
        .whereType<Map>()
        .map((e) => PropertyCompareRow.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<PropertyNeighborhoodIntel> getIntelligence(String listingId) async {
    final json = await _client.getJson(PropertyApiPaths.listingIntelligence(listingId));
    return PropertyNeighborhoodIntel.fromJson(json);
  }

  @override
  Future<PropertyVisitScore> getVisitScore(
    String listingId, {
    double? destLat,
    double? destLng,
  }) async {
    final params = <String>[];
    if (destLat != null) params.add('dest_lat=$destLat');
    if (destLng != null) params.add('dest_lng=$destLng');
    final suffix = params.isEmpty ? '' : '?${params.join('&')}';
    final json = await _client.getJson(
      '${PropertyApiPaths.listingVisitScore(listingId)}$suffix',
    );
    return PropertyVisitScore.fromJson(json);
  }

  @override
  Future<PropertyCommuteEstimate> getCommute(
    String listingId, {
    required double destLat,
    required double destLng,
    String mode = 'driving',
  }) async {
    final json = await _client.getJson(
      '${PropertyApiPaths.listingCommute(listingId)}?dest_lat=$destLat&dest_lng=$destLng&mode=$mode',
    );
    return PropertyCommuteEstimate.fromJson(json);
  }

  @override
  Future<List<PropertyMapCluster>> mapClusters({String region = ''}) async {
    final suffix = region.isEmpty
        ? ''
        : '?region=${Uri.encodeQueryComponent(region)}';
    final json = await _client.getJson('${PropertyApiPaths.mapClusters}$suffix');
    final clusters = json['clusters'];
    if (clusters is! List) return [];
    return clusters
        .whereType<Map>()
        .map((e) => PropertyMapCluster.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<PropertyListing> getById(String id) async {
    final json = await _client.getJson(PropertyApiPaths.listing(id));
    return _listingFromJson(json);
  }

  @override
  Future<List<PropertyMapPin>> mapPins({String region = ''}) async {
    final suffix = region.isEmpty
        ? ''
        : '?region=${Uri.encodeQueryComponent(region)}';
    final json = await _client.getJson('${PropertyApiPaths.mapPins}$suffix');
    final pins = json['pins'];
    if (pins is! List) return [];
    return pins.whereType<Map>().map((e) {
      final m = Map<String, dynamic>.from(e);
      return PropertyMapPin(
        id: m['id'].toString(),
        title: m['title']?.toString() ?? '',
        lat: (m['lat'] as num?)?.toDouble() ?? 0,
        lng: (m['lng'] as num?)?.toDouble() ?? 0,
        price: Money(
          (m['price_minor'] as num?)?.toInt() ?? 0,
          Currency.fromCode(m['currency']?.toString() ?? 'TZS'),
        ),
        beds: (m['beds'] as num?)?.toInt() ?? 0,
        transactionType: m['transaction_type']?.toString() ?? 'rent',
      );
    }).toList();
  }

  @override
  Future<bool> toggleFavorite(String listingId) async {
    final json = await _client.postJson(
      PropertyApiPaths.favorites,
      body: {'listing_id': listingId},
    );
    return json['favorited'] == true;
  }

  @override
  Future<List<PropertyListing>> favorites() async {
    final list = await _client.getJsonList(PropertyApiPaths.favorites);
    return list.whereType<Map>().map((e) {
      final m = Map<String, dynamic>.from(e);
      final listing = m['listing'];
      if (listing is Map) return _listingFromJson(Map<String, dynamic>.from(listing));
      return _listingFromJson(m);
    }).toList();
  }

  @override
  Future<PropertyListing> createListing(Map<String, dynamic> body) async {
    final json = await _client.postJson(PropertyApiPaths.listings, body: body);
    return _listingFromJson(json);
  }

  @override
  Future<PropertyListing> addMedia(String listingId, Map<String, dynamic> body) async {
    await _client.postJson(PropertyApiPaths.listingMedia(listingId), body: body);
    return getById(listingId);
  }

  PropertyListing _listingFromJson(Map<String, dynamic> json) {
    final currency = Currency.fromCode(json['currency']?.toString() ?? 'TZS');
    final mediaList = json['media'];
    final media = mediaList is List
        ? mediaList.whereType<Map>().map((e) => PropertyMedia.fromJson(Map<String, dynamic>.from(e))).toList()
        : <PropertyMedia>[];
    return PropertyListing(
      id: json['id'].toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      transactionType: json['transaction_type']?.toString() ?? 'rent',
      categoryCode: json['category_code']?.toString() ?? '',
      propertyTypeCode: json['property_type_code']?.toString() ?? '',
      price: Money((json['price_minor'] as num?)?.toInt() ?? 0, currency),
      deposit: Money((json['deposit_minor'] as num?)?.toInt() ?? 0, currency),
      beds: (json['beds'] as num?)?.toInt() ?? 0,
      baths: (json['baths'] as num?)?.toInt() ?? 0,
      areaSqm: (json['area_sqm'] as num?)?.toInt() ?? 0,
      region: json['region']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      ward: json['ward']?.toString() ?? '',
      addressLine: json['address_line']?.toString() ?? '',
      latitude: double.tryParse(json['latitude']?.toString() ?? '') ?? 0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '') ?? 0,
      verificationStatus: json['verification_status']?.toString() ?? '',
      primaryPhotoUrl: json['primary_photo_url']?.toString() ?? '',
      media: media,
      ownerName: json['owner_name']?.toString() ?? '',
      isUnlocked: json['is_unlocked'] == true,
      ownerPhone: json['owner_phone']?.toString() ?? '',
      ownerEmail: json['owner_email']?.toString() ?? '',
    );
  }

  @override
  Future<PropertyExperience> getExperience(String listingId) async {
    final json = await _client.getJson(PropertyApiPaths.listingExperience(listingId));
    return PropertyExperience.fromJson(json);
  }

  @override
  Future<List<ViewingPassPlan>> viewingPassPlans() async {
    final json = await _client.getJson(PropertyApiPaths.viewingPassPlans);
    final plans = json['plans'];
    if (plans is! List) return [];
    return plans
        .whereType<Map>()
        .map((e) => ViewingPassPlan.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<PropertyViewingPass> createViewingPass({
    required String planCode,
    String? listingId,
  }) async {
    final json = await _client.postJson(
      PropertyApiPaths.viewingPass,
      body: {
        'plan_code': planCode,
        'listing_id': ?listingId,
      },
    );
    return PropertyViewingPass.fromJson(json);
  }

  @override
  Future<PropertyViewingPass> payViewingPass(
    String passId, {
    required String idempotencyKey,
  }) async {
    final json = await _client.postJson(
      PropertyApiPaths.viewingPassPay(passId),
      idempotencyKey: idempotencyKey,
    );
    return PropertyViewingPass.fromJson(json);
  }

  @override
  Future<List<PropertyViewingPass>> myViewingPasses() async {
    final list = await _client.getJsonList(PropertyApiPaths.viewingPass);
    return list
        .whereType<Map>()
        .map((e) => PropertyViewingPass.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<PropertyLiveSession> requestLiveSession(String listingId, {String notes = ''}) async {
    final json = await _client.postJson(
      PropertyApiPaths.listingLiveSessions(listingId),
      body: notes.isNotEmpty ? {'notes': notes} : {},
    );
    return PropertyLiveSession.fromJson(json);
  }

  @override
  Future<PropertyLiveSession> joinLiveSession(String sessionId) async {
    final json = await _client.postJson(PropertyApiPaths.liveSessionJoin(sessionId), body: {});
    return PropertyLiveSession.fromJson(json);
  }

  @override
  Future<PropertyLiveSession> endLiveSession(String sessionId) async {
    final json = await _client.postJson(PropertyApiPaths.liveSessionEnd(sessionId), body: {});
    return PropertyLiveSession.fromJson(json);
  }

  @override
  Future<void> postLiveMessage(String sessionId, String body) async {
    await _client.postJson(
      PropertyApiPaths.liveSessionMessages(sessionId),
      body: {'body': body},
    );
  }

  @override
  Future<String> copilotChat({required String query, String? listingId}) async {
    final json = await _client.postJson(
      PropertyApiPaths.copilotChat,
      body: {
        'query': query,
        'listing_id': ?listingId,
      },
    );
    return json['answer']?.toString() ?? '';
  }

  @override
  Future<PropertyWingaAssignment> assignWinga(String listingId, {String notes = ''}) async {
    final json = await _client.postJson(
      PropertyApiPaths.listingAssignWinga(listingId),
      body: notes.isNotEmpty ? {'notes': notes} : {},
    );
    return PropertyWingaAssignment.fromJson(json);
  }

  @override
  Future<PropertyWingaAssignment> loadAssignment(String assignmentId) async {
    final json = await _client.getJson(PropertyApiPaths.assignment(assignmentId));
    return PropertyWingaAssignment.fromJson(json);
  }

  @override
  Future<List<PropertySecureChatMessage>> loadAssignmentChat(String assignmentId) async {
    final json = await _client.getJson(PropertyApiPaths.assignmentChat(assignmentId));
    final messages = json['messages'];
    if (messages is! List) return [];
    return messages
        .whereType<Map>()
        .map((e) => PropertySecureChatMessage.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<PropertySecureChatMessage> sendAssignmentChat(
    String assignmentId,
    String text,
  ) async {
    final json = await _client.postJson(
      PropertyApiPaths.assignmentChat(assignmentId),
      body: {'text': text},
    );
    return PropertySecureChatMessage.fromJson(json);
  }

  @override
  Future<PropertyApplication> createApplication(String listingId, Map<String, dynamic> body) async {
    final json = await _client.postJson(PropertyApiPaths.listingApplications(listingId), body: body);
    return PropertyApplication.fromJson(json);
  }

  @override
  Future<PropertyApplication> loadApplication(String applicationId) async {
    final json = await _client.getJson(PropertyApiPaths.application(applicationId));
    return PropertyApplication.fromJson(json);
  }

  @override
  Future<PropertyApplication> submitApplication(String applicationId) async {
    final json = await _client.postJson(PropertyApiPaths.applicationSubmit(applicationId), body: {});
    return PropertyApplication.fromJson(json);
  }

  @override
  Future<PropertyApplication> verifyApplicationIdentity(String applicationId) async {
    await _client.postJson(PropertyApiPaths.applicationVerifyIdentity(applicationId), body: {});
    return loadApplication(applicationId);
  }

  @override
  Future<PropertyApplication> verifyApplicationIncome(String applicationId) async {
    await _client.postJson(PropertyApiPaths.applicationVerifyIncome(applicationId), body: {});
    return loadApplication(applicationId);
  }

  @override
  Future<PropertyApplication> approveApplication(String applicationId) async {
    final json = await _client.postJson(PropertyApiPaths.applicationApprove(applicationId), body: {});
    return PropertyApplication.fromJson(json);
  }

  @override
  Future<PropertyLease> generateLease(String applicationId) async {
    final json = await _client.postJson(
      PropertyApiPaths.applicationGenerateLease(applicationId),
      body: {},
    );
    return PropertyLease.fromJson(json);
  }

  @override
  Future<PropertyLease> loadLease(String leaseId) async {
    final json = await _client.getJson(PropertyApiPaths.lease(leaseId));
    return PropertyLease.fromJson(json);
  }

  @override
  Future<PropertyLease> signLease(String leaseId) async {
    final json = await _client.postJson(PropertyApiPaths.leaseSign(leaseId), body: {});
    return PropertyLease.fromJson(json);
  }

  @override
  Future<PropertyLeasePayment> payLeasePayment(
    String paymentId, {
    required String idempotencyKey,
  }) async {
    final json = await _client.postJson(
      PropertyApiPaths.leasePaymentPay(paymentId),
      body: {},
      idempotencyKey: idempotencyKey,
    );
    return PropertyLeasePayment.fromJson(json);
  }

  @override
  Future<PropertyLease> renewLease(String leaseId) async {
    final json = await _client.postJson(PropertyApiPaths.leaseRenew(leaseId), body: {});
    return PropertyLease.fromJson(json);
  }

  @override
  Future<PropertyMoveWorkflow> completeMoveWorkflow(String workflowId) async {
    final json = await _client.postJson(PropertyApiPaths.moveWorkflowComplete(workflowId), body: {});
    return PropertyMoveWorkflow.fromJson(json);
  }

  @override
  Future<PropertyOpsConsole> loadOpsConsole({String region = ''}) async {
    final suffix = region.isEmpty
        ? ''
        : '?region=${Uri.encodeQueryComponent(region)}';
    final json = await _client.getJson('${PropertyApiPaths.opsConsole}$suffix');
    return PropertyOpsConsole.fromJson(json);
  }

  @override
  Future<void> resolveModerationReport(
    String reportId, {
    required String action,
    String notes = '',
  }) async {
    await _client.postJson(
      PropertyApiPaths.moderationResolve(reportId),
      body: {'action': action, if (notes.isNotEmpty) 'notes': notes},
    );
  }

  @override
  Future<PropertyOpsDashboard> opsDashboard({String region = ''}) async {
    final suffix = region.isEmpty
        ? ''
        : '?region=${Uri.encodeQueryComponent(region)}';
    final json = await _client.getJson('${PropertyApiPaths.opsDashboard}$suffix');
    return PropertyOpsDashboard.fromJson(json);
  }

  @override
  Future<PropertyFraudSignals> listingFraudSignals(String listingId) async {
    final json = await _client.getJson(PropertyApiPaths.listingFraudSignals(listingId));
    return PropertyFraudSignals.fromJson(json);
  }

  @override
  Future<void> reportListing(String listingId, {required String reason, String notes = ''}) async {
    await _client.postJson(
      PropertyApiPaths.listingReport(listingId),
      body: {'reason': reason, if (notes.isNotEmpty) 'notes': notes},
    );
  }

  @override
  Future<List<PropertyModerationReport>> moderationQueue() async {
    final json = await _client.getJson(PropertyApiPaths.opsModerationQueue);
    final reports = json['reports'];
    if (reports is! List) return [];
    return reports
        .whereType<Map>()
        .map((e) => PropertyModerationReport.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<List<PropertyDispute>> listDisputes({String status = ''}) async {
    final suffix = status.isEmpty
        ? ''
        : '?status=${Uri.encodeQueryComponent(status)}';
    final json = await _client.getJson('${PropertyApiPaths.opsDisputes}$suffix');
    final disputes = json['disputes'];
    if (disputes is! List) return [];
    return disputes
        .whereType<Map>()
        .map((e) => PropertyDispute.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}

String propertyErrorMessage(ApiException e) => switch (e) {
  NetworkException() => e.message,
  ApiStatusException(:final message) => message,
  ApiDecodeException() => e.message,
};

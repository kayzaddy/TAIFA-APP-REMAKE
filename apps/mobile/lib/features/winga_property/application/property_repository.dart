import '../domain/property_models.dart';

abstract interface class PropertyRepository {
  bool get serverAuthoritative;

  Future<List<PropertyCategory>> categories();
  Future<List<PropertyListing>> search({
    String query = '',
    String region = '',
    String category = '',
    bool verifiedOnly = true,
  });
  Future<List<PropertyListing>> advancedSearch({
    String query = '',
    String region = '',
    String category = '',
    String lifestyle = '',
    int? minBeds,
    int? minSafetyE4,
    int? minWalkabilityE4,
    bool verifiedOnly = true,
  });
  Future<List<PropertyListing>> aiSearch({
    required String query,
    String lifestyle = '',
    String neighborhood = '',
  });
  Future<List<PropertyListing>> recommendations({int limit = 6});
  Future<List<PropertyListing>> recentlyViewed({int limit = 8});
  Future<List<PropertyCompareRow>> compare(List<String> listingIds);
  Future<PropertyListing> getById(String id);
  Future<PropertyNeighborhoodIntel> getIntelligence(String listingId);
  Future<PropertyVisitScore> getVisitScore(
    String listingId, {
    double? destLat,
    double? destLng,
  });
  Future<PropertyCommuteEstimate> getCommute(
    String listingId, {
    required double destLat,
    required double destLng,
    String mode = 'driving',
  });
  Future<List<PropertyMapPin>> mapPins({String region = ''});
  Future<List<PropertyMapCluster>> mapClusters({String region = ''});
  Future<PropertyExperience> getExperience(String listingId);
  Future<List<ViewingPassPlan>> viewingPassPlans();
  Future<PropertyViewingPass> createViewingPass({required String planCode, String? listingId});
  Future<PropertyViewingPass> payViewingPass(String passId, {required String idempotencyKey});
  Future<List<PropertyViewingPass>> myViewingPasses();
  Future<PropertyLiveSession> requestLiveSession(String listingId, {String notes = ''});
  Future<PropertyLiveSession> joinLiveSession(String sessionId);
  Future<PropertyLiveSession> endLiveSession(String sessionId);
  Future<void> postLiveMessage(String sessionId, String body);
  Future<String> copilotChat({required String query, String? listingId});
  Future<PropertyWingaAssignment> assignWinga(String listingId, {String notes = ''});
  Future<PropertyWingaAssignment> loadAssignment(String assignmentId);
  Future<List<PropertySecureChatMessage>> loadAssignmentChat(String assignmentId);
  Future<PropertySecureChatMessage> sendAssignmentChat(String assignmentId, String text);
  Future<PropertyApplication> createApplication(String listingId, Map<String, dynamic> body);
  Future<PropertyApplication> loadApplication(String applicationId);
  Future<PropertyApplication> submitApplication(String applicationId);
  Future<PropertyApplication> verifyApplicationIdentity(String applicationId);
  Future<PropertyApplication> verifyApplicationIncome(String applicationId);
  Future<PropertyApplication> approveApplication(String applicationId);
  Future<PropertyLease> generateLease(String applicationId);
  Future<PropertyLease> loadLease(String leaseId);
  Future<PropertyLease> signLease(String leaseId);
  Future<PropertyLeasePayment> payLeasePayment(String paymentId, {required String idempotencyKey});
  Future<PropertyLease> renewLease(String leaseId);
  Future<PropertyMoveWorkflow> completeMoveWorkflow(String workflowId);
  Future<PropertyOpsDashboard> opsDashboard({String region = ''});
  Future<PropertyOpsConsole> loadOpsConsole({String region = ''});
  Future<void> resolveModerationReport(String reportId, {required String action, String notes = ''});
  Future<PropertyFraudSignals> listingFraudSignals(String listingId);
  Future<void> reportListing(String listingId, {required String reason, String notes = ''});
  Future<List<PropertyModerationReport>> moderationQueue();
  Future<List<PropertyDispute>> listDisputes({String status = ''});
  Future<bool> toggleFavorite(String listingId);
  Future<List<PropertyListing>> favorites();
  Future<PropertyListing> createListing(Map<String, dynamic> body);
  Future<PropertyListing> addMedia(String listingId, Map<String, dynamic> body);
}

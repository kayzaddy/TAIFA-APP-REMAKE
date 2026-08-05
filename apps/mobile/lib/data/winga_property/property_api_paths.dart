/// Winga Property API paths.
class PropertyApiPaths {
  const PropertyApiPaths._();

  static const categories = 'winga-property/categories';
  static const types = 'winga-property/types';
  static const listings = 'winga-property/listings';
  static const mapPins = 'winga-property/map/pins';
  static const mapClusters = 'winga-property/map/clusters';
  static const favorites = 'winga-property/favorites';
  static const savedSearches = 'winga-property/saved-searches';
  static const ownerMe = 'winga-property/owners/me';
  static const discoverySearch = 'winga-property/discovery/search';
  static const discoveryAiSearch = 'winga-property/discovery/ai-search';
  static const discoveryRecommendations = 'winga-property/discovery/recommendations';
  static const discoveryRecentlyViewed = 'winga-property/discovery/recently-viewed';
  static const discoveryCompare = 'winga-property/discovery/compare';
  static const viewingPassPlans = 'winga-property/viewing-pass/plans';
  static const viewingPass = 'winga-property/viewing-pass';
  static const viewingPassVerify = 'winga-property/viewing-pass/verify';
  static const copilotChat = 'winga-property/copilot/chat';
  static const copilotRankings = 'winga-property/copilot/rankings';
  static const wingas = 'winga-property/wingas';
  static const wingaLeaderboard = 'winga-property/wingas/leaderboard';
  static const assignments = 'winga-property/assignments';
  static const applications = 'winga-property/applications';
  static const opsDashboard = 'winga-property/ops/dashboard';
  static const opsConsole = 'winga-property/ops/console';
  static const opsModerationQueue = 'winga-property/ops/moderation-queue';
  static const opsDisputes = 'winga-property/ops/disputes';

  static String listing(String id) => 'winga-property/listings/$id';
  static String listingApplications(String id) => 'winga-property/listings/$id/applications';
  static String listingAssignWinga(String id) => 'winga-property/listings/$id/assign-winga';
  static String listingNegotiationAssist(String id) => 'winga-property/listings/$id/negotiation-assist';
  static String assignment(String id) => 'winga-property/assignments/$id';
  static String assignmentChat(String id) => 'winga-property/assignments/$id/chat';
  static String application(String id) => 'winga-property/applications/$id';
  static String applicationSubmit(String id) => 'winga-property/applications/$id/submit';
  static String applicationVerifyIdentity(String id) =>
      'winga-property/applications/$id/verify-identity';
  static String applicationVerifyIncome(String id) =>
      'winga-property/applications/$id/verify-income';
  static String applicationApprove(String id) => 'winga-property/applications/$id/approve';
  static String applicationGenerateLease(String id) =>
      'winga-property/applications/$id/generate-lease';
  static String lease(String id) => 'winga-property/leases/$id';
  static String leaseSign(String id) => 'winga-property/leases/$id/sign';
  static String leaseRenew(String id) => 'winga-property/leases/$id/renew';
  static String leasePaymentPay(String id) => 'winga-property/lease-payments/$id/pay';
  static String moveWorkflowComplete(String id) => 'winga-property/move-workflows/$id/complete';
  static String listingReport(String id) => 'winga-property/listings/$id/report';
  static String listingFraudSignals(String id) => 'winga-property/listings/$id/fraud-signals';
  static String moderationResolve(String id) => 'winga-property/ops/moderation/$id/resolve';
  static String listingExperience(String id) => 'winga-property/listings/$id/experience';
  static String listingLiveSessions(String id) => 'winga-property/listings/$id/live-sessions';
  static String viewingPassPay(String id) => 'winga-property/viewing-pass/$id/pay';
  static String viewingPassUnlock(String listingId) => 'winga-property/viewing-pass/unlock/$listingId';
  static String liveSession(String id) => 'winga-property/live-sessions/$id';
  static String liveSessionJoin(String id) => 'winga-property/live-sessions/$id/join';
  static String liveSessionEnd(String id) => 'winga-property/live-sessions/$id/end';
  static String liveSessionMessages(String id) => 'winga-property/live-sessions/$id/messages';
  static String listingMedia(String id) => 'winga-property/listings/$id/media';
  static String listingSubmitVerification(String id) =>
      'winga-property/listings/$id/submit-verification';
  static String listingIntelligence(String id) => 'winga-property/listings/$id/intelligence';
  static String listingCommute(String id) => 'winga-property/listings/$id/commute';
  static String listingVisitScore(String id) => 'winga-property/listings/$id/visit-score';
}

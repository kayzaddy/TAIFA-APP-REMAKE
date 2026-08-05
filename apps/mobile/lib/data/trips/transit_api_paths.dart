/// Canonical REST paths for Taifa Mobility BRT / transit (Phase 1).
class TransitApiPaths {
  const TransitApiPaths._();

  static const home = 'trips/transit/home';
  static const modes = 'trips/transit/modes';
  static const routes = 'trips/transit/routes';
  static String route(String id) => 'trips/transit/routes/$id';
  static const stationsNearby = 'trips/transit/stations/nearby';
  static String station(String code) => 'trips/transit/stations/$code';
  static const search = 'trips/transit/search';
  static const ticketsPurchase = 'trips/transit/tickets/purchase';
  static const ticketsMine = 'trips/transit/tickets/mine';
  static const ticketsValidate = 'trips/transit/tickets/validate';
  static const products = 'trips/transit/products';
  static const plan = 'trips/transit/plan';
  static const driverRuns = 'trips/transit/driver/runs';
  static String driverRun(String id) => 'trips/transit/driver/runs/$id';
  static const liveMap = 'trips/transit/map';
  static const avlPing = 'trips/transit/avl/ping';
  static const profile = 'trips/transit/profile';
  static const favorites = 'trips/transit/favorites';
  static String favorite(String id) => 'trips/transit/favorites/$id';
  static const notifications = 'trips/transit/notifications';
  static const feedback = 'trips/transit/feedback';
  static const safetySos = 'trips/transit/safety/sos';
  static const analytics = 'trips/transit/analytics';
  static const adminRoutes = 'trips/transit/admin/routes';
  static String adminRoute(String id) => 'trips/transit/admin/routes/$id';
  static const adminProducts = 'trips/transit/admin/products';
  static String adminProduct(String id) => 'trips/transit/admin/products/$id';
  static const assistant = 'trips/transit/assistant';
  static const family = 'trips/transit/family';
  static const familyMembers = 'trips/transit/family/members';
  static String familyMember(String id) => 'trips/transit/family/members/$id';
  static const lostFound = 'trips/transit/lost-found';
  static String lostFoundClaim(String id) => 'trips/transit/lost-found/$id/claim';
  static String lostFoundResolve(String id) => 'trips/transit/lost-found/$id/resolve';
  static const lostFoundPhoto = 'trips/transit/lost-found/photo';
  static const adminLostFound = 'trips/transit/admin/lost-found';
  static String adminLostFoundResolve(String id) => 'trips/transit/admin/lost-found/$id/resolve';
}

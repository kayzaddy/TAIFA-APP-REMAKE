class TourismTripApiPaths {
  static const trips = 'tourism/trips';

  static String trip(String id) => 'tourism/trips/$id';

  static String plan(String tripId) => 'tourism/trips/$tripId/plan';

  static String itineraries(String tripId) => 'tourism/trips/$tripId/itineraries';

  static String selectItinerary(String tripId, String itineraryId) =>
      'tourism/trips/$tripId/itineraries/$itineraryId/select';

  static String attachBooking(String tripId) => 'tourism/trips/$tripId/attach-booking';

  static String cartBuild(String tripId) => 'tourism/trips/$tripId/cart/build';

  static String checkout(String tripId) => 'tourism/trips/$tripId/checkout';

  static String checkoutPay(String tripId) => 'tourism/trips/$tripId/checkout/pay';
}

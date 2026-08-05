/// Path fragments for `/api/v1/commerce/huduma-bookings*` (relative to API base).
abstract final class HudumaApiPaths {
  static const hudumaBookings = 'commerce/huduma-bookings';

  static String hudumaBooking(String id) => 'commerce/huduma-bookings/$id';
}

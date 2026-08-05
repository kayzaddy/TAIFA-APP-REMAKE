/// Canonical REST path fragments for commerce tour bookings.
class TourApiPaths {
  const TourApiPaths._();

  static const tourBookings = 'commerce/tour-bookings';

  static String tourBooking(String bookingId) =>
      'commerce/tour-bookings/$bookingId';
  static String tourBookingPay(String id) =>
      'commerce/tour-bookings/$id/pay';
}

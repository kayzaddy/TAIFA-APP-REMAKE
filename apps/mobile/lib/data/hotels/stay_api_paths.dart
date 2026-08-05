/// Canonical REST path fragments for commerce stay bookings.
class StayApiPaths {
  const StayApiPaths._();

  static const stayBookings = 'commerce/stay-bookings';

  static String stayBooking(String bookingId) =>
      'commerce/stay-bookings/$bookingId';
  static String stayBookingPay(String id) =>
      'commerce/stay-bookings/$id/pay';
}

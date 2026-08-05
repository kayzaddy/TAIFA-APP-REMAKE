/// Canonical REST path fragments for commerce flight bookings.
class FlightApiPaths {
  const FlightApiPaths._();

  static const flightBookings = 'commerce/flight-bookings';

  static String flightBooking(String bookingId) =>
      'commerce/flight-bookings/$bookingId';
  static String flightBookingPay(String id) =>
      'commerce/flight-bookings/$id/pay';
}

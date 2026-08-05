import '../domain/flight_models.dart';

abstract interface class FlightSearchRepository {
  Future<List<Airport>> airports();
  Future<List<FlightOffer>> search({
    required String originCode,
    required String destinationCode,
    required DateTime date,
  });
}

abstract interface class FlightBookingRepository {
  Future<FlightBooking> book(FlightBooking draft);
  Future<FlightBooking> pay(String bookingId);
  Future<List<FlightBooking>> history({int limit = 20});
  Future<FlightBooking> getById(String id);
}

import '../domain/hotel_models.dart';

abstract interface class HotelRepository {
  Future<List<Hotel>> list({String? query});
  Future<Hotel> getById(String id);
}

abstract interface class StayBookingRepository {
  Future<StayBooking> book(StayBooking draft);
  Future<StayBooking> update(StayBooking booking);
  Future<StayBooking> pay(String bookingId);
  Future<List<StayBooking>> history({int limit = 20});
  Future<StayBooking> getById(String id);
}

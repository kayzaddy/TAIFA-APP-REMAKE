import '../domain/tourism_models.dart';

abstract interface class TourismRepository {
  Future<List<TourExperience>> list({String? query});
  Future<TourExperience> getById(String id);
}

abstract interface class TourBookingRepository {
  Future<TourBooking> book(TourBooking draft);
  Future<TourBooking> pay(String bookingId);
  Future<List<TourBooking>> history({int limit = 20});
  Future<TourBooking> getById(String id);
}

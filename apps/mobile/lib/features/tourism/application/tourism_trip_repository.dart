import '../domain/tourism_checkout_models.dart';
import '../domain/tourism_trip_models.dart';

abstract class TourismTripRepository {
  Future<List<TourismTrip>> listTrips();

  Future<TourismTrip> createTrip({
    String title = 'My Tanzania trip',
    int partySize = 2,
    String budgetTier = 'mid',
    String travelStyle = 'leisure',
    List<String> interests = const [],
    DateTime? startDate,
  });

  Future<({TourismTrip trip, List<TourismItinerary> itineraries})> planTrip({
    required String tripId,
    int? partySize,
    String? budgetTier,
    String? travelStyle,
    List<String>? interests,
    DateTime? startDate,
  });

  Future<TourismTrip> selectItinerary({
    required String tripId,
    required String itineraryId,
  });

  Future<TourismTrip> attachBooking({
    required String tripId,
    required String bookingType,
    required String bookingId,
  });

  Future<List<TourismItinerary>> listItineraries(String tripId);

  Future<TourismCart> buildCart(String tripId, {bool includeInsuranceQuote = true});

  Future<TourismCheckout> createCheckout({
    required String tripId,
    bool includeInsurance = false,
    String insurancePlanId = 'ins-travel',
    bool includeEsim = false,
    String esimPlanId = 'esim-7d-5gb',
  });

  Future<TourismCheckout> payCheckout({
    required String tripId,
    required String idempotencyKey,
  });
}

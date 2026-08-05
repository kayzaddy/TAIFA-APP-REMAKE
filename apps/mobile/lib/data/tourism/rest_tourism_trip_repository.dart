import '../../features/tourism/application/tourism_trip_repository.dart';
import '../../features/tourism/domain/tourism_checkout_models.dart';
import '../../features/tourism/domain/tourism_trip_models.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import 'tourism_trip_api_paths.dart';

class RestTourismTripRepository implements TourismTripRepository {
  RestTourismTripRepository(this._client);

  final TaifaApiClient _client;

  @override
  Future<List<TourismTrip>> listTrips() async {
    try {
      final json = await _client.getJson(TourismTripApiPaths.trips);
      final trips = json['trips'] as List? ?? const [];
      return trips
          .whereType<Map>()
          .map((e) => TourismTrip.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<TourismTrip> createTrip({
    String title = 'My Tanzania trip',
    int partySize = 2,
    String budgetTier = 'mid',
    String travelStyle = 'leisure',
    List<String> interests = const [],
    DateTime? startDate,
  }) async {
    try {
      final json = await _client.postJson(
        TourismTripApiPaths.trips,
        body: {
          'title': title,
          'party_size': partySize,
          'budget_tier': budgetTier,
          'travel_style': travelStyle,
          'interests': interests,
          if (startDate != null)
            'start_date': startDate.toIso8601String().substring(0, 10),
        },
      );
      return TourismTrip.fromJson(json);
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<({TourismTrip trip, List<TourismItinerary> itineraries})> planTrip({
    required String tripId,
    int? partySize,
    String? budgetTier,
    String? travelStyle,
    List<String>? interests,
    DateTime? startDate,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (partySize != null) body['party_size'] = partySize;
      if (budgetTier != null) body['budget_tier'] = budgetTier;
      if (travelStyle != null) body['travel_style'] = travelStyle;
      if (interests != null) body['interests'] = interests;
      if (startDate != null) {
        body['start_date'] = startDate.toIso8601String().substring(0, 10);
      }
      final json = await _client.postJson(TourismTripApiPaths.plan(tripId), body: body);
      final trip = TourismTrip.fromJson(Map<String, dynamic>.from(json['trip'] as Map));
      final rows = json['itineraries'] as List? ?? const [];
      final itineraries = rows
          .whereType<Map>()
          .map((e) => TourismItinerary.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      return (trip: trip, itineraries: itineraries);
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<TourismTrip> selectItinerary({
    required String tripId,
    required String itineraryId,
  }) async {
    try {
      final json = await _client.postJson(
        TourismTripApiPaths.selectItinerary(tripId, itineraryId),
        body: const {},
      );
      return TourismTrip.fromJson(json);
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<TourismTrip> attachBooking({
    required String tripId,
    required String bookingType,
    required String bookingId,
  }) async {
    try {
      final json = await _client.postJson(
        TourismTripApiPaths.attachBooking(tripId),
        body: {'booking_type': bookingType, 'booking_id': bookingId},
      );
      return TourismTrip.fromJson(json);
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  String _message(ApiException e) => switch (e) {
        NetworkException() => e.message,
        ApiStatusException(:final message) => message,
        ApiDecodeException() => e.message,
      };

  @override
  Future<List<TourismItinerary>> listItineraries(String tripId) async {
    try {
      final json = await _client.getJson(TourismTripApiPaths.itineraries(tripId));
      final rows = json['itineraries'] as List? ?? const [];
      return rows
          .whereType<Map>()
          .map((e) => TourismItinerary.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<TourismCart> buildCart(
    String tripId, {
    bool includeInsuranceQuote = true,
  }) async {
    try {
      final json = await _client.postJson(
        TourismTripApiPaths.cartBuild(tripId),
        body: {'include_insurance_quote': includeInsuranceQuote},
      );
      return TourismCart.fromJson(json);
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<TourismCheckout> createCheckout({
    required String tripId,
    bool includeInsurance = false,
    String insurancePlanId = 'ins-travel',
    bool includeEsim = false,
    String esimPlanId = 'esim-7d-5gb',
  }) async {
    try {
      final json = await _client.postJson(
        TourismTripApiPaths.checkout(tripId),
        body: {
          'include_insurance': includeInsurance,
          'insurance_plan_id': insurancePlanId,
          'include_esim': includeEsim,
          'esim_plan_id': esimPlanId,
        },
      );
      return TourismCheckout.fromJson(json);
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<TourismCheckout> payCheckout({
    required String tripId,
    required String idempotencyKey,
  }) async {
    try {
      final json = await _client.postJson(
        TourismTripApiPaths.checkoutPay(tripId),
        body: const {},
        idempotencyKey: idempotencyKey,
      );
      return TourismCheckout.fromJson(json);
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }
}

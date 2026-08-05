import '../../features/flights/application/flight_repository.dart';
import '../../features/flights/domain/flight_models.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import 'flight_api_paths.dart';
import 'flight_booking_dto.dart';

/// Live [FlightBookingRepository]: persists tickets on `/commerce/flight-bookings`.
/// Search catalog stays client-side; the API stores durable booking summaries.
class RestFlightBookingRepository implements FlightBookingRepository {
  RestFlightBookingRepository(this._client);

  final TaifaApiClient _client;
  final Map<String, FlightOffer> _offers = {};
  int _pnrSeq = 0;

  @override
  Future<FlightBooking> book(FlightBooking draft) async {
    try {
      _pnrSeq++;
      final pnr =
          draft.pnr ??
          'TA${(1000 + _pnrSeq * 41) % 9000}${String.fromCharCode(65 + (_pnrSeq % 26))}';
      final withPnr = draft.copyWith(pnr: pnr);
      final json = await _client.postJson(
        FlightApiPaths.flightBookings,
        body: FlightBookingDto.createBody(withPnr),
      );
      final booking = FlightBookingDto.toDomain(
        json,
        offer: draft.offer,
      ).copyWith(status: FlightBookingStatus.ticketed, pnr: pnr);
      _offers[booking.id] = draft.offer;
      if ((json['pnr'] as String?)?.trim().isEmpty ?? true) {
        return _patch(booking);
      }
      return booking;
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<FlightBooking> pay(String bookingId) async {
    try {
      final json = await _client.postJson(
        FlightApiPaths.flightBookingPay(bookingId),
        body: const {},
        idempotencyKey: 'flight-pay-$bookingId',
      );
      return FlightBookingDto.toDomain(json, offer: _offers[bookingId]);
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<List<FlightBooking>> history({int limit = 20}) async {
    try {
      final list = await _client.getJsonList(FlightApiPaths.flightBookings);
      return list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .map((json) {
            final id = json['id'].toString();
            return FlightBookingDto.toDomain(json, offer: _offers[id]);
          })
          .take(limit)
          .toList();
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<FlightBooking> getById(String id) async {
    try {
      final json = await _client.getJson(FlightApiPaths.flightBooking(id));
      return FlightBookingDto.toDomain(json, offer: _offers[id]);
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  Future<FlightBooking> _patch(FlightBooking booking) async {
    try {
      final json = await _client.patchJson(
        FlightApiPaths.flightBooking(booking.id),
        body: FlightBookingDto.patchBody(booking),
      );
      _offers[booking.id] = booking.offer;
      return FlightBookingDto.toDomain(json, offer: booking.offer);
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  String _message(ApiException e) => switch (e) {
    NetworkException() => e.message,
    ApiStatusException(:final message) => message,
    ApiDecodeException() => e.message,
  };
}

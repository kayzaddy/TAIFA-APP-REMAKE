import '../../features/tourism/application/tourism_repository.dart';
import '../../features/tourism/domain/tourism_models.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import 'tour_api_paths.dart';
import 'tour_booking_dto.dart';

/// Live [TourBookingRepository]: persists experiences on `/commerce/tour-bookings`.
/// Catalog stays client-side; the API stores durable booking summaries.
class RestTourBookingRepository implements TourBookingRepository {
  RestTourBookingRepository(this._client);

  final TaifaApiClient _client;
  final Map<String, TourExperience> _tours = {};
  int _codeSeq = 0;

  @override
  Future<TourBooking> book(TourBooking draft) async {
    try {
      _codeSeq++;
      final code =
          draft.confirmationCode ?? 'EXP-${(200000 + _codeSeq * 173) % 900000}';
      final withCode = draft.copyWith(confirmationCode: code);
      final json = await _client.postJson(
        TourApiPaths.tourBookings,
        body: TourBookingDto.createBody(withCode),
      );
      final booking = TourBookingDto.toDomain(
        json,
        tour: draft.tour,
      ).copyWith(status: TourBookingStatus.confirmed, confirmationCode: code);
      _tours[booking.id] = draft.tour;
      if ((json['confirmation_code'] as String?)?.trim().isEmpty ?? true) {
        return _patch(booking);
      }
      return booking;
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<TourBooking> pay(String bookingId) async {
    try {
      final json = await _client.postJson(
        TourApiPaths.tourBookingPay(bookingId),
        body: const {},
        idempotencyKey: 'tour-pay-$bookingId',
      );
      return TourBookingDto.toDomain(json, tour: _tours[bookingId]);
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<List<TourBooking>> history({int limit = 20}) async {
    try {
      final list = await _client.getJsonList(TourApiPaths.tourBookings);
      return list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .map((json) {
            final id = json['id'].toString();
            return TourBookingDto.toDomain(json, tour: _tours[id]);
          })
          .take(limit)
          .toList();
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<TourBooking> getById(String id) async {
    try {
      final json = await _client.getJson(TourApiPaths.tourBooking(id));
      return TourBookingDto.toDomain(json, tour: _tours[id]);
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  Future<TourBooking> _patch(TourBooking booking) async {
    try {
      final json = await _client.patchJson(
        TourApiPaths.tourBooking(booking.id),
        body: TourBookingDto.patchBody(booking),
      );
      _tours[booking.id] = booking.tour;
      return TourBookingDto.toDomain(json, tour: booking.tour);
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

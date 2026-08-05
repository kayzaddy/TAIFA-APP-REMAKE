import '../../features/hotels/application/hotel_repository.dart';
import '../../features/hotels/domain/hotel_models.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import 'stay_api_paths.dart';
import 'stay_booking_dto.dart';

/// Live [StayBookingRepository]: persists stays on `/commerce/stay-bookings`.
/// Hotel catalog stays client-side; the API stores durable booking summaries.
class RestStayBookingRepository implements StayBookingRepository {
  RestStayBookingRepository(this._client);

  final TaifaApiClient _client;
  final Map<String, ({Hotel hotel, RoomType room})> _local = {};
  int _codeSeq = 0;

  @override
  Future<StayBooking> book(StayBooking draft) async {
    try {
      _codeSeq++;
      final code =
          draft.confirmationCode ?? 'TAF-${(100000 + _codeSeq * 137) % 900000}';
      final withCode = draft.copyWith(confirmationCode: code);
      final json = await _client.postJson(
        StayApiPaths.stayBookings,
        body: StayBookingDto.createBody(withCode),
      );
      final booking = StayBookingDto.toDomain(
        json,
        hotel: draft.hotel,
        room: draft.room,
      ).copyWith(status: StayBookingStatus.confirmed, confirmationCode: code);
      _local[booking.id] = (hotel: draft.hotel, room: draft.room);
      if ((json['confirmation_code'] as String?)?.trim().isEmpty ?? true) {
        return update(booking);
      }
      return booking;
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<StayBooking> update(StayBooking booking) async {
    try {
      final json = await _client.patchJson(
        StayApiPaths.stayBooking(booking.id),
        body: StayBookingDto.patchBody(booking),
      );
      _local[booking.id] = (hotel: booking.hotel, room: booking.room);
      final cached = _local[booking.id];
      return StayBookingDto.toDomain(
        json,
        hotel: cached?.hotel ?? booking.hotel,
        room: cached?.room ?? booking.room,
      );
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<StayBooking> pay(String bookingId) async {
    try {
      final json = await _client.postJson(
        StayApiPaths.stayBookingPay(bookingId),
        body: const {},
        idempotencyKey: 'stay-pay-$bookingId',
      );
      final cached = _local[bookingId];
      return StayBookingDto.toDomain(
        json,
        hotel: cached?.hotel,
        room: cached?.room,
      );
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<List<StayBooking>> history({int limit = 20}) async {
    try {
      final list = await _client.getJsonList(StayApiPaths.stayBookings);
      return list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .map((json) {
            final id = json['id'].toString();
            final cached = _local[id];
            return StayBookingDto.toDomain(
              json,
              hotel: cached?.hotel,
              room: cached?.room,
            );
          })
          .take(limit)
          .toList();
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<StayBooking> getById(String id) async {
    try {
      final json = await _client.getJson(StayApiPaths.stayBooking(id));
      final cached = _local[id];
      return StayBookingDto.toDomain(
        json,
        hotel: cached?.hotel,
        room: cached?.room,
      );
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

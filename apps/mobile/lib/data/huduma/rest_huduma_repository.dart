import '../../features/huduma/application/huduma_repository.dart';
import '../../features/huduma/data/huduma_catalog.dart';
import '../../features/huduma/domain/huduma_models.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import 'huduma_api_paths.dart';
import 'huduma_booking_dto.dart';

/// Live [HudumaRepository]: services stay seed-local; bookings persist on
/// `/commerce/huduma-bookings`.
class RestHudumaRepository implements HudumaRepository {
  RestHudumaRepository(this._client);

  final TaifaApiClient _client;
  final Map<String, HudumaService> _services = {};

  @override
  Future<List<HudumaService>> list() async => HudumaCatalog.services();

  @override
  Future<HudumaBooking> book(HudumaBooking draft) async {
    try {
      final paymentRef =
          draft.paymentRef ??
          'HDM-${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}';
      final paid = draft.copyWith(
        status: HudumaBookingStatus.paid,
        paymentRef: paymentRef,
      );
      final json = await _client.postJson(
        HudumaApiPaths.hudumaBookings,
        body: HudumaBookingDto.createBody(paid),
      );
      final booking = HudumaBookingDto.toDomain(
        json,
        service: draft.service,
      ).copyWith(status: HudumaBookingStatus.paid, paymentRef: paymentRef);
      _services[booking.id] = draft.service;
      return booking;
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<List<HudumaBooking>> history() async {
    try {
      final list = await _client.getJsonList(HudumaApiPaths.hudumaBookings);
      return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).map(
        (json) {
          final id = json['id'].toString();
          return HudumaBookingDto.toDomain(json, service: _services[id]);
        },
      ).toList();
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

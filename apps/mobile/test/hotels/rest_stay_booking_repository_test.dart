import 'package:flutter_test/flutter_test.dart';
import 'package:taifa/data/api/api_client.dart';
import 'package:taifa/data/api/api_exception.dart';
import 'package:taifa/data/hotels/rest_stay_booking_repository.dart';
import 'package:taifa/data/hotels/stay_api_paths.dart';
import 'package:taifa/features/hotels/data/hotel_catalog.dart';
import 'package:taifa/features/hotels/domain/hotel_models.dart';
import 'package:taifa/features/wallet/domain/currency.dart';
import 'package:taifa/features/wallet/domain/money.dart';

class _FakeClient implements TaifaApiClient {
  _FakeClient({
    this.postResponse,
    this.getListResponse,
  });

  Map<String, dynamic>? postResponse;
  List<dynamic>? getListResponse;

  String? lastPostPath;
  String? lastGetPath;
  String? lastPatchPath;
  Map<String, dynamic>? lastBody;

  @override
  Future<Map<String, dynamic>> getJson(String path) async {
    lastGetPath = path;
    throw const ApiDecodeException();
  }

  @override
  Future<List<dynamic>> getJsonList(String path) async {
    lastGetPath = path;
    return getListResponse ?? const [];
  }

  @override
  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic> body = const {},
    String? idempotencyKey,
  }) async {
    lastPostPath = path;
    lastBody = body;
    return postResponse!;
  }

  @override
  Future<Map<String, dynamic>> patchJson(
    String path, {
    Map<String, dynamic> body = const {},
  }) async {
    lastPatchPath = path;
    lastBody = body;
    throw const ApiDecodeException();
  }

  @override
  Future<void> deleteJson(String path) async {}
}

Map<String, dynamic> _bookingJson({
  String id = '55555555-5555-5555-5555-555555555555',
  String status = 'confirmed',
  String confirmation = 'TAF-100137',
  String paymentRef = '',
}) {
  final hotel = HotelCatalog.all().first;
  final room = hotel.rooms.first;
  return {
    'id': id,
    'owner': 'dev_x',
    'status': status,
    'hotel_id': hotel.id,
    'hotel_name': hotel.name,
    'room_name': room.name,
    'check_in': '2026-08-01',
    'check_out': '2026-08-03',
    'guests': 2,
    'nights': 2,
    'nightly_rate_minor': room.nightlyRate.minorUnits,
    'taxes_minor': 6400000,
    'total_minor': room.nightlyRate.minorUnits * 2 + 6400000,
    'currency': 'TZS',
    'confirmation_code': confirmation,
    'payment_ref': paymentRef,
    'created_at': '2026-07-15T00:00:00Z',
    'updated_at': '2026-07-15T00:00:00Z',
  };
}

void main() {
  final hotel = HotelCatalog.all().first;
  final room = hotel.rooms.first;
  final draft = StayBooking(
    id: 'draft',
    hotel: hotel,
    room: room,
    checkIn: DateTime(2026, 8, 1),
    checkOut: DateTime(2026, 8, 3),
    guests: 2,
    nights: 2,
    nightlyRate: room.nightlyRate,
    taxes: const Money(6400000, Currency.tzs),
    total: Money(room.nightlyRate.minorUnits * 2 + 6400000, Currency.tzs),
    status: StayBookingStatus.drafting,
    createdAt: DateTime.now(),
  );

  test('StayApiPaths match commerce OpenAPI surface', () {
    expect(StayApiPaths.stayBookings, 'commerce/stay-bookings');
    expect(StayApiPaths.stayBooking('abc'), 'commerce/stay-bookings/abc');
  });

  test('RestStayBookingRepository.book POSTs stay-booking contract', () async {
    final client = _FakeClient(postResponse: _bookingJson());
    final booked = await RestStayBookingRepository(client).book(draft);

    expect(client.lastPostPath, 'commerce/stay-bookings');
    expect(client.lastBody!['hotel_id'], hotel.id);
    expect(client.lastBody!['check_in'], '2026-08-01');
    expect(client.lastBody!['nights'], 2);
    expect(booked.status, StayBookingStatus.confirmed);
    expect(booked.confirmationCode, isNotNull);
    expect(booked.hotel.name, hotel.name);
  });

  test('RestStayBookingRepository.pay posts pay endpoint', () async {
    final id = '66666666-6666-6666-6666-666666666666';
    final client = _FakeClient(
      postResponse: _bookingJson(id: id, status: 'paid', paymentRef: 'STAY-1'),
    );
    final paid = await RestStayBookingRepository(client).pay(id);
    expect(client.lastPostPath, 'commerce/stay-bookings/$id/pay');
    expect(paid.status, StayBookingStatus.paid);
  });

  test('RestStayBookingRepository.history lists stays', () async {
    final client = _FakeClient(
      getListResponse: [
        _bookingJson(id: 'a', status: 'paid', paymentRef: 'STAY-A'),
        _bookingJson(id: 'b', status: 'confirmed'),
      ],
    );
    final history = await RestStayBookingRepository(client).history();
    expect(client.lastGetPath, 'commerce/stay-bookings');
    expect(history, hasLength(2));
    expect(history.first.status, StayBookingStatus.paid);
  });
}

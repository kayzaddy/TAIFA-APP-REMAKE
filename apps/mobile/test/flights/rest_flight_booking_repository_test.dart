import 'package:flutter_test/flutter_test.dart';
import 'package:taifa/data/api/api_client.dart';
import 'package:taifa/data/api/api_exception.dart';
import 'package:taifa/data/flights/flight_api_paths.dart';
import 'package:taifa/data/flights/rest_flight_booking_repository.dart';
import 'package:taifa/features/flights/data/flight_catalog.dart';
import 'package:taifa/features/flights/domain/flight_models.dart';

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
  String id = '77777777-7777-7777-7777-777777777777',
  String status = 'ticketed',
  String pnr = 'TA1041A',
  String paymentRef = '',
}) {
  final offers = FlightCatalog.search(
    originCode: 'DAR',
    destinationCode: 'ZNZ',
    date: DateTime(2026, 8, 1),
  );
  final offer = offers.first;
  return {
    'id': id,
    'owner': 'dev_x',
    'status': status,
    'airline': offer.airline,
    'flight_number': offer.flightNumber,
    'origin_code': offer.origin.code,
    'destination_code': offer.destination.code,
    'depart_at': offer.departAt.toUtc().toIso8601String(),
    'passengers': 1,
    'total_minor': offer.price.minorUnits,
    'currency': 'TZS',
    'pnr': pnr,
    'payment_ref': paymentRef,
    'created_at': '2026-07-15T00:00:00Z',
    'updated_at': '2026-07-15T00:00:00Z',
  };
}

void main() {
  final offer = FlightCatalog.search(
    originCode: 'DAR',
    destinationCode: 'ZNZ',
    date: DateTime(2026, 8, 1),
  ).first;
  final draft = FlightBooking(
    id: 'draft',
    offer: offer,
    passengers: 1,
    total: offer.price,
    status: FlightBookingStatus.drafting,
    createdAt: DateTime.now(),
  );

  test('FlightApiPaths match commerce OpenAPI surface', () {
    expect(FlightApiPaths.flightBookings, 'commerce/flight-bookings');
    expect(FlightApiPaths.flightBooking('abc'), 'commerce/flight-bookings/abc');
  });

  test(
    'RestFlightBookingRepository.book POSTs flight-booking contract',
    () async {
      final client = _FakeClient(postResponse: _bookingJson());
      final booked = await RestFlightBookingRepository(client).book(draft);

      expect(client.lastPostPath, 'commerce/flight-bookings');
      expect(client.lastBody!['airline'], offer.airline);
      expect(client.lastBody!['origin_code'], 'DAR');
      expect(client.lastBody!['destination_code'], 'ZNZ');
      expect(booked.status, FlightBookingStatus.ticketed);
      expect(booked.pnr, isNotNull);
      expect(booked.offer.flightNumber, offer.flightNumber);
    },
  );

  test('RestFlightBookingRepository.pay posts pay endpoint', () async {
    final id = '88888888-8888-8888-8888-888888888888';
    final client = _FakeClient(
      postResponse: _bookingJson(id: id, status: 'paid', paymentRef: 'FLT-1'),
    );
    final paid = await RestFlightBookingRepository(client).pay(id);
    expect(client.lastPostPath, 'commerce/flight-bookings/$id/pay');
    expect(paid.status, FlightBookingStatus.paid);
  });

  test('RestFlightBookingRepository.history lists tickets', () async {
    final client = _FakeClient(
      getListResponse: [
        _bookingJson(id: 'a', status: 'paid', paymentRef: 'FLT-A'),
        _bookingJson(id: 'b', status: 'ticketed'),
      ],
    );
    final history = await RestFlightBookingRepository(client).history();
    expect(client.lastGetPath, 'commerce/flight-bookings');
    expect(history, hasLength(2));
    expect(history.first.status, FlightBookingStatus.paid);
  });
}

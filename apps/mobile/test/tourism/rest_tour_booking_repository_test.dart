import 'package:flutter_test/flutter_test.dart';
import 'package:taifa/data/api/api_client.dart';
import 'package:taifa/data/api/api_exception.dart';
import 'package:taifa/data/tourism/rest_tour_booking_repository.dart';
import 'package:taifa/data/tourism/tour_api_paths.dart';
import 'package:taifa/features/tourism/data/tourism_catalog.dart';
import 'package:taifa/features/tourism/domain/tourism_models.dart';
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
  String id = '99999999-9999-9999-9999-999999999999',
  String status = 'confirmed',
  String confirmation = 'EXP-200173',
  String paymentRef = '',
}) {
  final tour = TourismCatalog.all().first;
  return {
    'id': id,
    'owner': 'dev_x',
    'status': status,
    'tour_id': tour.id,
    'tour_title': tour.title,
    'experience_date': '2026-08-15',
    'guests': 2,
    'total_minor': tour.price.minorUnits * 2,
    'currency': 'TZS',
    'confirmation_code': confirmation,
    'payment_ref': paymentRef,
    'created_at': '2026-07-15T00:00:00Z',
    'updated_at': '2026-07-15T00:00:00Z',
  };
}

void main() {
  final tour = TourismCatalog.all().first;
  final draft = TourBooking(
    id: 'draft',
    tour: tour,
    guests: 2,
    date: DateTime(2026, 8, 15),
    total: Money(tour.price.minorUnits * 2, tour.price.currency),
    status: TourBookingStatus.drafting,
    createdAt: DateTime.now(),
  );

  test('TourApiPaths match commerce OpenAPI surface', () {
    expect(TourApiPaths.tourBookings, 'commerce/tour-bookings');
    expect(TourApiPaths.tourBooking('abc'), 'commerce/tour-bookings/abc');
  });

  test('RestTourBookingRepository.book POSTs tour-booking contract', () async {
    final client = _FakeClient(postResponse: _bookingJson());
    final booked = await RestTourBookingRepository(client).book(draft);

    expect(client.lastPostPath, 'commerce/tour-bookings');
    expect(client.lastBody!['tour_id'], tour.id);
    expect(client.lastBody!['experience_date'], '2026-08-15');
    expect(client.lastBody!['guests'], 2);
    expect(booked.status, TourBookingStatus.confirmed);
    expect(booked.confirmationCode, isNotNull);
    expect(booked.tour.title, tour.title);
  });

  test('RestTourBookingRepository.pay posts pay endpoint', () async {
    final id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    final client = _FakeClient(
      postResponse: _bookingJson(id: id, status: 'paid', paymentRef: 'TOUR-1'),
    );
    final paid = await RestTourBookingRepository(client).pay(id);
    expect(client.lastPostPath, 'commerce/tour-bookings/$id/pay');
    expect(paid.status, TourBookingStatus.paid);
  });

  test('RestTourBookingRepository.history lists bookings', () async {
    final client = _FakeClient(
      getListResponse: [
        _bookingJson(id: 'a', status: 'paid', paymentRef: 'TOUR-A'),
        _bookingJson(id: 'b', status: 'confirmed'),
      ],
    );
    final history = await RestTourBookingRepository(client).history();
    expect(client.lastGetPath, 'commerce/tour-bookings');
    expect(history, hasLength(2));
    expect(history.first.status, TourBookingStatus.paid);
  });
}

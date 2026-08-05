import 'package:flutter_test/flutter_test.dart';
import 'package:taifa/data/api/api_client.dart';
import 'package:taifa/data/api/api_exception.dart';
import 'package:taifa/data/winga/rest_winga_repository.dart';
import 'package:taifa/data/winga/winga_api_paths.dart';
import 'package:taifa/features/winga/data/winga_catalog.dart';
import 'package:taifa/features/winga/domain/winga_models.dart';

class _FakeClient implements TaifaApiClient {
  _FakeClient({this.postResponse});

  Map<String, dynamic>? postResponse;
  Map<String, dynamic>? patchResponse;
  String? lastPostPath;
  Map<String, dynamic>? lastBody;

  @override
  Future<Map<String, dynamic>> getJson(String path) async =>
      throw const ApiDecodeException();

  @override
  Future<List<dynamic>> getJsonList(String path) async => const [];

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
    lastBody = body;
    return patchResponse ?? postResponse!;
  }

  @override
  Future<void> deleteJson(String path) async {}
}

void main() {
  test('WingaApiPaths match commerce OpenAPI surface', () {
    expect(WingaApiPaths.orders, 'commerce/winga-orders');
    expect(WingaApiPaths.serviceBookings, 'commerce/winga-service-bookings');
    expect(WingaApiPaths.shops, 'commerce/winga-shops');
  });

  test('RestWingaRepository.placeOrder POSTs winga-orders', () async {
    final product = WingaCatalog.products().first;
    final client = _FakeClient(
      postResponse: {
        'id': 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
        'status': 'placed',
        'total_minor': product.price.minorUnits,
        'currency': 'TZS',
        'item_count': 1,
        'summary': product.name,
        'payment_ref': 'WINGA-1',
        'courier_name': '',
        'eta_label': '',
        'created_at': '2026-07-15T00:00:00Z',
        'updated_at': '2026-07-15T00:00:00Z',
      },
    );
    final order = await RestWingaRepository(client).placeOrder(
      WingaOrder(
        id: 'draft',
        lines: [WingaCartLine(product: product, quantity: 1)],
        total: product.price,
        status: WingaOrderStatus.placed,
        createdAt: DateTime.now(),
        paymentRef: 'WINGA-1',
      ),
    );
    expect(client.lastPostPath, 'commerce/winga-orders');
    expect(client.lastBody!['total_minor'], product.price.minorUnits);
    expect(order.id, 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb');
    expect(order.lines, hasLength(1));
  });

  test('RestWingaRepository.bookService and submitShop', () async {
    final service = WingaCatalog.services().first;
    final client = _FakeClient(
      postResponse: {
        'id': 'cccccccc-cccc-cccc-cccc-cccccccccccc',
        'service_id': service.id,
        'service_title': service.title,
        'slot_label': 'Today · 3–5 pm',
        'total_minor': service.priceFrom.minorUnits,
        'currency': 'TZS',
        'payment_ref': '',
        'created_at': '2026-07-15T00:00:00Z',
        'updated_at': '2026-07-15T00:00:00Z',
      },
    );
    final booked = await RestWingaRepository(client).bookService(
      WingaServiceBooking(
        id: 'draft',
        service: service,
        slotLabel: 'Today · 3–5 pm',
        total: service.priceFrom,
        createdAt: DateTime.now(),
      ),
    );
    expect(client.lastPostPath, 'commerce/winga-service-bookings');
    expect(booked.service.title, service.title);

    final shopClient = _FakeClient(
      postResponse: {
        'id': 'dddddddd-dddd-dddd-dddd-dddddddddddd',
        'name': 'Dar Gadgets',
        'category': 'Electronics',
        'address': 'Kariakoo',
        'status': 'approved',
        'created_at': '2026-07-15T00:00:00Z',
        'updated_at': '2026-07-15T00:00:00Z',
      },
    );
    final shop = await RestWingaRepository(shopClient).submitShop(
      const WingaShopDraft(
        name: 'Dar Gadgets',
        category: 'Electronics',
        address: 'Kariakoo',
      ),
    );
    expect(shopClient.lastPostPath, 'commerce/winga-shops');
    expect(shop.status, WingaShopStatus.approved);
  });
}

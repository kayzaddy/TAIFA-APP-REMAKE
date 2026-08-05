import 'package:flutter_test/flutter_test.dart';
import 'package:taifa/data/api/api_client.dart';
import 'package:taifa/data/api/api_exception.dart';
import 'package:taifa/data/food/food_api_paths.dart';
import 'package:taifa/data/food/rest_food_order_repository.dart';
import 'package:taifa/features/food/data/food_catalog.dart';
import 'package:taifa/features/food/domain/food_models.dart';

class _FakeClient implements TaifaApiClient {
  _FakeClient({
    this.postResponse,
    this.getListResponse,
    this.patchResponse,
  });

  Map<String, dynamic>? postResponse;
  List<dynamic>? getListResponse;
  Map<String, dynamic>? patchResponse;

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
    return patchResponse ?? postResponse!;
  }

  @override
  Future<void> deleteJson(String path) async {}
}

Map<String, dynamic> _orderJson({
  String id = '33333333-3333-3333-3333-333333333333',
  String status = 'confirmed',
  String courier = 'Asha M.',
  String paymentRef = '',
}) => {
  'id': id,
  'owner': 'dev_x',
  'status': status,
  'restaurant_id': 'rst-spice',
  'restaurant_name': 'Spice Bazaar',
  'subtotal_minor': 2400000,
  'delivery_fee_minor': 150000,
  'total_minor': 2550000,
  'currency': 'TZS',
  'courier_name': courier,
  'payment_ref': paymentRef,
  'created_at': '2026-07-15T00:00:00Z',
  'updated_at': '2026-07-15T00:00:00Z',
};

void main() {
  final restaurant = FoodCatalog.all().first;
  final line = CartLine(item: restaurant.menu.first, quantity: 2);
  final draft = FoodOrder(
    id: 'draft',
    restaurant: restaurant,
    lines: [line],
    subtotal: line.lineTotal,
    deliveryFee: restaurant.deliveryFee,
    total: line.lineTotal + restaurant.deliveryFee,
    status: FoodOrderStatus.placing,
    createdAt: DateTime.now(),
  );

  test('FoodApiPaths match commerce OpenAPI surface', () {
    expect(FoodApiPaths.foodOrders, 'commerce/food-orders');
    expect(FoodApiPaths.foodOrder('abc'), 'commerce/food-orders/abc');
  });

  test('RestFoodOrderRepository.place POSTs food-order contract', () async {
    final client = _FakeClient(postResponse: _orderJson());
    final order = await RestFoodOrderRepository(client).place(draft);

    expect(client.lastPostPath, 'commerce/food-orders');
    expect(client.lastBody!['restaurant_id'], 'rst-spice');
    expect(client.lastBody!['total_minor'], draft.total.minorUnits);
    expect(order.id, '33333333-3333-3333-3333-333333333333');
    expect(order.lines, hasLength(1));
    expect(order.restaurant.name, 'Spice Bazaar');
    expect(order.status, FoodOrderStatus.confirmed);
  });

  test('RestFoodOrderRepository.update PATCHes tracking status', () async {
    final client = _FakeClient(
      postResponse: _orderJson(),
      patchResponse: _orderJson(status: 'on_the_way', courier: 'Asha M.'),
    );
    final repo = RestFoodOrderRepository(client);
    final placed = await repo.place(draft);
    final updated = await repo.update(
      placed.copyWith(status: FoodOrderStatus.onTheWay, progress: 0.6),
    );

    expect(client.lastPatchPath, 'commerce/food-orders/${placed.id}');
    expect(client.lastBody!['status'], 'on_the_way');
    expect(updated.status, FoodOrderStatus.onTheWay);
    expect(updated.progress, 0.6);
  });

  test('RestFoodOrderRepository.pay posts pay endpoint', () async {
    final id = '44444444-4444-4444-4444-444444444444';
    final client = _FakeClient(
      postResponse: _orderJson(id: id, status: 'paid', paymentRef: 'FOOD-1'),
    );
    final paid = await RestFoodOrderRepository(client).pay(id);
    expect(client.lastPostPath, 'commerce/food-orders/$id/pay');
    expect(paid.status, FoodOrderStatus.paid);
  });

  test('RestFoodOrderRepository.history lists orders', () async {
    final client = _FakeClient(
      getListResponse: [
        _orderJson(id: 'a', status: 'paid', paymentRef: 'FOOD-A'),
        _orderJson(id: 'b', status: 'delivered'),
      ],
    );
    final history = await RestFoodOrderRepository(client).history();
    expect(client.lastGetPath, 'commerce/food-orders');
    expect(history, hasLength(2));
    expect(history.first.status, FoodOrderStatus.paid);
  });
}

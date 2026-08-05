import '../../features/food/application/food_repository.dart';
import '../../features/food/domain/food_models.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import 'food_api_paths.dart';
import 'food_order_dto.dart';

/// Live [FoodOrderRepository]: persists orders on `/commerce/food-orders`.
/// Catalog and cart lines stay client-side; the API stores durable summaries.
class RestFoodOrderRepository implements FoodOrderRepository {
  RestFoodOrderRepository(this._client);

  final TaifaApiClient _client;
  final Map<String, List<CartLine>> _linesById = {};

  @override
  Future<FoodOrder> place(FoodOrder draft) async {
    try {
      final withCourier = draft.copyWith(
        courierName: draft.courierName ?? 'Asha M.',
      );
      final json = await _client.postJson(
        FoodApiPaths.foodOrders,
        body: FoodOrderDto.createBody(withCourier),
      );
      final order = FoodOrderDto.toDomain(json, lines: draft.lines).copyWith(
        courierName: withCourier.courierName,
        etaMinutes: draft.restaurant.etaMinutes,
        status: FoodOrderStatus.confirmed,
      );
      _linesById[order.id] = List<CartLine>.from(draft.lines);
      // Persist courier on the server if create omitted it.
      if ((json['courier_name'] as String?)?.trim().isEmpty ?? true) {
        return update(order);
      }
      return order;
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<FoodOrder> update(FoodOrder order) async {
    try {
      final json = await _client.patchJson(
        FoodApiPaths.foodOrder(order.id),
        body: FoodOrderDto.patchBody(order),
      );
      _linesById[order.id] = List<CartLine>.from(order.lines);
      return FoodOrderDto.toDomain(json, lines: order.lines).copyWith(
        progress: order.progress,
        etaMinutes: order.etaMinutes ?? order.restaurant.etaMinutes,
      );
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<FoodOrder> pay(String orderId) async {
    try {
      final json = await _client.postJson(
        FoodApiPaths.foodOrderPay(orderId),
        body: const {},
        idempotencyKey: 'food-pay-$orderId',
      );
      final lines = _linesById[orderId];
      return FoodOrderDto.toDomain(json, lines: lines);
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<List<FoodOrder>> history({int limit = 20}) async {
    try {
      final list = await _client.getJsonList(FoodApiPaths.foodOrders);
      return list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .map((json) {
            final id = json['id'].toString();
            return FoodOrderDto.toDomain(json, lines: _linesById[id]);
          })
          .take(limit)
          .toList();
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<FoodOrder> getById(String id) async {
    try {
      final json = await _client.getJson(FoodApiPaths.foodOrder(id));
      return FoodOrderDto.toDomain(json, lines: _linesById[id]);
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

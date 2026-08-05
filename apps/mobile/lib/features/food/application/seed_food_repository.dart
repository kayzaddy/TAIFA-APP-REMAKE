import '../data/food_catalog.dart';
import '../domain/food_models.dart';
import 'food_repository.dart';

class SeedRestaurantRepository implements RestaurantRepository {
  @override
  Future<List<Restaurant>> list({String? query}) async {
    await Future<void>.delayed(const Duration(milliseconds: 280));
    final all = FoodCatalog.all();
    final q = query?.trim().toLowerCase();
    if (q == null || q.isEmpty) return all;
    return all
        .where(
          (r) =>
              r.name.toLowerCase().contains(q) ||
              r.cuisine.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Future<Restaurant> getById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return FoodCatalog.all().firstWhere((r) => r.id == id);
  }
}

class SeedFoodOrderRepository implements FoodOrderRepository {
  final Map<String, FoodOrder> _byId = {};
  final List<String> _order = [];
  int _seq = 0;

  @override
  Future<FoodOrder> place(FoodOrder draft) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final id = 'ord-${DateTime.now().millisecondsSinceEpoch}-${_seq++}';
    final placed = FoodOrder(
      id: id,
      restaurant: draft.restaurant,
      lines: draft.lines,
      subtotal: draft.subtotal,
      deliveryFee: draft.deliveryFee,
      total: draft.total,
      status: FoodOrderStatus.confirmed,
      createdAt: DateTime.now(),
      courierName: 'Asha M.',
      etaMinutes: draft.restaurant.etaMinutes,
    );
    _byId[id] = placed;
    _order.insert(0, id);
    return placed;
  }

  @override
  Future<FoodOrder> update(FoodOrder order) async {
    _byId[order.id] = order;
    return order;
  }

  @override
  Future<FoodOrder> pay(String orderId) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final order = await getById(orderId);
    return update(
      order.copyWith(
        status: FoodOrderStatus.paid,
        paymentRef:
            'FOOD-${orderId.hashCode.abs().toRadixString(36).toUpperCase()}',
      ),
    );
  }

  @override
  Future<List<FoodOrder>> history({int limit = 20}) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return _order.take(limit).map((id) => _byId[id]!).toList();
  }

  @override
  Future<FoodOrder> getById(String id) async {
    final o = _byId[id];
    if (o == null) throw StateError('Order not found: $id');
    return o;
  }
}

import '../../features/food/data/food_catalog.dart';
import '../../features/food/domain/food_models.dart';
import '../../features/wallet/domain/currency.dart';
import '../../features/wallet/domain/money.dart';

/// Maps `/api/v1/commerce/food-orders` JSON ↔ domain [FoodOrder].
///
/// Line items are not stored on the API — pass [lines] from a local cache when
/// hydrating an active order.
class FoodOrderDto {
  const FoodOrderDto._();

  static FoodOrder toDomain(
    Map<String, dynamic> json, {
    List<CartLine>? lines,
  }) {
    final currency = Currency.fromCode(json['currency'] as String? ?? 'TZS');
    final restaurantId = json['restaurant_id'] as String? ?? '';
    final restaurantName = json['restaurant_name'] as String? ?? 'Restaurant';
    final restaurant = _resolveRestaurant(
      restaurantId,
      restaurantName,
      currency,
    );
    final courier = (json['courier_name'] as String?)?.trim();
    final paymentRef = (json['payment_ref'] as String?)?.trim();
    final resolvedLines = lines ?? const <CartLine>[];

    return FoodOrder(
      id: json['id'].toString(),
      restaurant: restaurant,
      lines: resolvedLines,
      subtotal: Money((json['subtotal_minor'] as num?)?.toInt() ?? 0, currency),
      deliveryFee: Money(
        (json['delivery_fee_minor'] as num?)?.toInt() ?? 0,
        currency,
      ),
      total: Money((json['total_minor'] as num?)?.toInt() ?? 0, currency),
      status: statusFromApi(json['status'] as String? ?? 'confirmed'),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      courierName: (courier == null || courier.isEmpty) ? null : courier,
      etaMinutes: restaurant.etaMinutes,
      paymentRef: (paymentRef == null || paymentRef.isEmpty)
          ? null
          : paymentRef,
    );
  }

  static Map<String, dynamic> createBody(FoodOrder draft) => {
    'restaurant_id': draft.restaurant.id,
    'restaurant_name': draft.restaurant.name,
    'subtotal_minor': draft.subtotal.minorUnits,
    'delivery_fee_minor': draft.deliveryFee.minorUnits,
    'total_minor': draft.total.minorUnits,
    'currency': draft.total.currency.code,
    if (draft.courierName != null && draft.courierName!.isNotEmpty)
      'courier_name': draft.courierName,
  };

  static Map<String, dynamic> patchBody(FoodOrder order) {
    final body = <String, dynamic>{};
    // Never send paid/payment_ref — money is server-authored via POST …/pay.
    if (order.status != FoodOrderStatus.paid) {
      body['status'] = statusToApi(order.status);
    }
    if (order.courierName != null && order.courierName!.isNotEmpty) {
      body['courier_name'] = order.courierName;
    }
    return body;
  }

  static String statusToApi(FoodOrderStatus status) => switch (status) {
    FoodOrderStatus.drafting ||
    FoodOrderStatus.placing ||
    FoodOrderStatus.confirmed => 'confirmed',
    FoodOrderStatus.preparing => 'preparing',
    FoodOrderStatus.pickingUp => 'picking_up',
    FoodOrderStatus.onTheWay => 'on_the_way',
    FoodOrderStatus.delivered => 'delivered',
    FoodOrderStatus.paid => 'paid',
    FoodOrderStatus.cancelled => 'cancelled',
  };

  static FoodOrderStatus statusFromApi(String raw) => switch (raw) {
    'preparing' => FoodOrderStatus.preparing,
    'picking_up' => FoodOrderStatus.pickingUp,
    'on_the_way' => FoodOrderStatus.onTheWay,
    'delivered' => FoodOrderStatus.delivered,
    'paid' => FoodOrderStatus.paid,
    'cancelled' => FoodOrderStatus.cancelled,
    _ => FoodOrderStatus.confirmed,
  };

  static Restaurant _resolveRestaurant(
    String id,
    String name,
    Currency currency,
  ) {
    try {
      return FoodCatalog.all().firstWhere((r) => r.id == id);
    } catch (_) {
      return Restaurant(
        id: id.isEmpty ? 'rst-unknown' : id,
        name: name,
        cuisine: '',
        rating: 4.5,
        etaMinutes: 30,
        deliveryFee: Money.zero(currency),
        imageTone: 0,
        menu: const [],
      );
    }
  }
}

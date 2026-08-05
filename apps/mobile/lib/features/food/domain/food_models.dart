import '../../wallet/domain/money.dart';

class MenuItem {
  const MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.popular = false,
  });

  final String id;
  final String name;
  final String description;
  final Money price;
  final String category;
  final bool popular;
}

class Restaurant {
  const Restaurant({
    required this.id,
    required this.name,
    required this.cuisine,
    required this.rating,
    required this.etaMinutes,
    required this.deliveryFee,
    required this.imageTone,
    required this.menu,
    this.featured = false,
  });

  final String id;
  final String name;
  final String cuisine;
  final double rating;
  final int etaMinutes;
  final Money deliveryFee;
  final int imageTone; // palette seed for demo tiles
  final List<MenuItem> menu;
  final bool featured;
}

class CartLine {
  const CartLine({required this.item, required this.quantity});
  final MenuItem item;
  final int quantity;

  Money get lineTotal =>
      Money(item.price.minorUnits * quantity, item.price.currency);

  CartLine copyWith({int? quantity}) =>
      CartLine(item: item, quantity: quantity ?? this.quantity);
}

enum FoodOrderStatus {
  drafting,
  placing,
  confirmed,
  preparing,
  pickingUp,
  onTheWay,
  delivered,
  paid,
  cancelled,
}

extension FoodOrderStatusX on FoodOrderStatus {
  String get label => switch (this) {
    FoodOrderStatus.drafting => 'Draft',
    FoodOrderStatus.placing => 'Placing order',
    FoodOrderStatus.confirmed => 'Restaurant confirmed',
    FoodOrderStatus.preparing => 'Preparing your food',
    FoodOrderStatus.pickingUp => 'Courier picking up',
    FoodOrderStatus.onTheWay => 'On the way',
    FoodOrderStatus.delivered => 'Delivered',
    FoodOrderStatus.paid => 'Paid',
    FoodOrderStatus.cancelled => 'Cancelled',
  };

  bool get isActive =>
      this == FoodOrderStatus.confirmed ||
      this == FoodOrderStatus.preparing ||
      this == FoodOrderStatus.pickingUp ||
      this == FoodOrderStatus.onTheWay;
}

class FoodOrder {
  const FoodOrder({
    required this.id,
    required this.restaurant,
    required this.lines,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.status,
    required this.createdAt,
    this.courierName,
    this.etaMinutes,
    this.paymentRef,
    this.progress = 0,
  });

  final String id;
  final Restaurant restaurant;
  final List<CartLine> lines;
  final Money subtotal;
  final Money deliveryFee;
  final Money total;
  final FoodOrderStatus status;
  final DateTime createdAt;
  final String? courierName;
  final int? etaMinutes;
  final String? paymentRef;
  final double progress;

  FoodOrder copyWith({
    FoodOrderStatus? status,
    String? courierName,
    int? etaMinutes,
    String? paymentRef,
    double? progress,
  }) {
    return FoodOrder(
      id: id,
      restaurant: restaurant,
      lines: lines,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      total: total,
      status: status ?? this.status,
      createdAt: createdAt,
      courierName: courierName ?? this.courierName,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      paymentRef: paymentRef ?? this.paymentRef,
      progress: progress ?? this.progress,
    );
  }
}

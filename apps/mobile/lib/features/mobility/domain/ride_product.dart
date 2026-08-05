import '../../wallet/domain/currency.dart';
import '../../wallet/domain/money.dart';

/// A bookable ride product (Go / Comfort / XL / Boda).
class RideProduct {
  const RideProduct({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.capacity,
    required this.etaMinutes,
    required this.fare,
    required this.iconName,
  });

  final String id;
  final String name;
  final String subtitle;
  final int capacity;
  final int etaMinutes;
  final Money fare;
  final String iconName; // semantic key for UI icons
}

/// Quoted fare for a product on a given route.
class FareEstimate {
  const FareEstimate({
    required this.product,
    required this.base,
    required this.distance,
    required this.time,
    required this.total,
    this.surgeMultiplier = 1.0,
  });

  final RideProduct product;
  final Money base;
  final Money distance;
  final Money time;
  final Money total;
  final double surgeMultiplier;

  Currency get currency => total.currency;
}

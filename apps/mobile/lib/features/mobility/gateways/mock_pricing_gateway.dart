import '../../wallet/domain/currency.dart';
import '../../wallet/domain/money.dart';
import '../domain/geo_point.dart';
import '../domain/ride_product.dart';
import '../domain/route_plan.dart';
import 'pricing_gateway.dart';

class MockPricingGateway implements PricingGateway {
  @override
  Future<List<FareEstimate>> quote({
    required RoutePlan route,
    required GeoPoint pickup,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final km = route.distanceKm;
    final mins = route.durationSeconds / 60.0;

    FareEstimate build({
      required String id,
      required String name,
      required String subtitle,
      required int capacity,
      required int baseMajor,
      required double perKm,
      required double perMin,
      required int etaSkew,
      required String icon,
    }) {
      final base = Money.major(baseMajor, Currency.tzs);
      final distance = Money.major((km * perKm).round(), Currency.tzs);
      final time = Money.major((mins * perMin).round(), Currency.tzs);
      final total = base + distance + time;
      final product = RideProduct(
        id: id,
        name: name,
        subtitle: subtitle,
        capacity: capacity,
        etaMinutes: max(3, (mins * 0.15).round() + etaSkew),
        fare: total,
        iconName: icon,
      );
      return FareEstimate(
        product: product,
        base: base,
        distance: distance,
        time: time,
        total: total,
      );
    }

    return [
      build(
        id: 'go',
        name: 'TAIFA Go',
        subtitle: 'Affordable everyday rides',
        capacity: 4,
        baseMajor: 1500,
        perKm: 900,
        perMin: 80,
        etaSkew: 2,
        icon: 'go',
      ),
      build(
        id: 'comfort',
        name: 'TAIFA Comfort',
        subtitle: 'Top-rated drivers · AC',
        capacity: 4,
        baseMajor: 2500,
        perKm: 1200,
        perMin: 100,
        etaSkew: 4,
        icon: 'comfort',
      ),
      build(
        id: 'xl',
        name: 'TAIFA XL',
        subtitle: 'SUVs for groups & luggage',
        capacity: 6,
        baseMajor: 4000,
        perKm: 1600,
        perMin: 120,
        etaSkew: 6,
        icon: 'xl',
      ),
      build(
        id: 'boda',
        name: 'TAIFA Boda',
        subtitle: 'Fast motorcycle · solo',
        capacity: 1,
        baseMajor: 800,
        perKm: 500,
        perMin: 40,
        etaSkew: 1,
        icon: 'boda',
      ),
    ];
  }

  static int max(int a, int b) => a > b ? a : b;
}

import '../../wallet/domain/currency.dart';
import '../../wallet/domain/money.dart';
import '../data/winga_catalog.dart';
import '../domain/winga_models.dart';

/// Commerce AI boundary — Demo Complete uses [MockWingaAiGateway].
abstract interface class WingaAiGateway {
  Future<String> shopAssist(String query);
  Future<List<NegotiaQuote>> negotiate(String query);
  Future<String> businessAssist(String topic);
}

class MockWingaAiGateway implements WingaAiGateway {
  @override
  Future<String> shopAssist(String query) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final q = query.toLowerCase();
    final products = WingaCatalog.products();
    final services = WingaCatalog.services();

    if (q.contains('fridge') ||
        q.contains('refrigerator') ||
        q.contains('friji')) {
      final p = products.firstWhere((x) => x.id == 'p-fridge');
      return 'Found ${p.name} at Serengeti Tech Hub for ${p.price.format()} '
          '(was ${p.compareAt?.format()}). Best value under TSh 900,000 with '
          '4.6★ from ${p.reviewCount} reviews. I can add it to your cart.';
    }
    if (q.contains('photo') || q.contains('wedding') || q.contains('picha')) {
      final s = services.firstWhere((x) => x.id == 'svc-photo');
      return 'Top match: ${s.provider} — ${s.title} from ${s.priceFrom.format()} '
          'in ${s.city} (${s.rating}★). Open Services to book a slot.';
    }
    if (q.contains('uniform') || q.contains('school') || q.contains('shule')) {
      final p = products.firstWhere((x) => x.id == 'p-uniform');
      return 'Recommended: ${p.name} at ${p.price.format()} from Spice Coast Fashion. '
          'Durable primary set — popular this term. Want it in your cart?';
    }
    if (q.contains('cement') || q.contains('simiti')) {
      return 'For bulk cement, switch to NEGOTIA — it will source suppliers, '
          'negotiate unit price, and estimate transport. Or browse Building category.';
    }
    return 'I searched WINGA merchants for “$query”. Try electronics under TSh 1M, '
        'fashion deals, or service pros (plumber, tutor, lawyer). Ask in Kiswahili or English.';
  }

  @override
  Future<List<NegotiaQuote>> negotiate(String query) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final qty = _extractQty(query) ?? 500;
    Money u(int major) => Money.major(major, Currency.tzs);
    return [
      NegotiaQuote(
        supplier: 'Ujenzi Supply Co. · Dodoma',
        unitPrice: u(17200),
        qty: qty,
        transport: u(450000),
        negotiated: true,
        scoreLabel: 'Best overall',
      ),
      NegotiaQuote(
        supplier: 'Twiga Depot · Dar',
        unitPrice: u(18500),
        qty: qty,
        transport: u(180000),
        negotiated: true,
        scoreLabel: 'Fastest delivery',
      ),
      NegotiaQuote(
        supplier: 'Coast Builders · Tanga',
        unitPrice: u(16800),
        qty: qty,
        transport: u(620000),
        negotiated: false,
        scoreLabel: 'Lowest unit',
      ),
    ];
  }

  @override
  Future<String> businessAssist(String topic) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    final t = topic.toLowerCase();
    if (t.contains('sales') || t.contains('mauzo')) {
      return 'Sales up 18% WoW. Fridge and uniforms lead. Push a 48h flash deal on fans — inventory turns slow.';
    }
    if (t.contains('inventory') || t.contains('stock')) {
      return 'Cement stock covers 4 days at current velocity. Reorder 200 bags via NEGOTIA before Friday.';
    }
    if (t.contains('price') || t.contains('bei')) {
      return 'Competitor undercuts phone A25 by TSh 15k. Hold margin: bundle charger + case instead of cutting price.';
    }
    if (t.contains('market') || t.contains('promo')) {
      return 'Run “Back to school” coupon UNIFORM10 (10% off kids). Peak search window: Sun 6–9 pm.';
    }
    if (t.contains('customer') || t.contains('insight')) {
      return '62% repeat buyers are Kinondoni. Average basket TSh 118k. Suggest loyalty stamp after 3 orders.';
    }
    return 'Business AI (mock): ask about sales, inventory, pricing, marketing, or customers for Tanzanian retail insights.';
  }

  int? _extractQty(String q) {
    final m = RegExp(r'(\d{2,5})').firstMatch(q);
    return m == null ? null : int.tryParse(m.group(1)!);
  }
}

/// Delivery dispatch — mirrors Mobility lifecycle without duplicating map SDKs.
abstract interface class WingaDeliveryGateway {
  Future<WingaOrder> dispatch(WingaOrder order);
  Future<WingaOrder> advance(WingaOrder order);
}

class MockWingaDeliveryGateway implements WingaDeliveryGateway {
  static const _couriers = ['Juma Boda', 'Asha Courier', 'Kassim Express'];

  @override
  Future<WingaOrder> dispatch(WingaOrder order) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return order.copyWith(
      status: WingaOrderStatus.driverAssigned,
      courierName: _couriers[order.id.hashCode.abs() % _couriers.length],
      etaLabel: '28–40 min',
    );
  }

  @override
  Future<WingaOrder> advance(WingaOrder order) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final next = switch (order.status) {
      WingaOrderStatus.placed => WingaOrderStatus.driverAssigned,
      WingaOrderStatus.driverAssigned => WingaOrderStatus.pickup,
      WingaOrderStatus.pickup => WingaOrderStatus.delivering,
      WingaOrderStatus.delivering => WingaOrderStatus.completed,
      WingaOrderStatus.completed => WingaOrderStatus.completed,
    };
    return order.copyWith(
      status: next,
      etaLabel: next == WingaOrderStatus.completed
          ? 'Delivered'
          : order.etaLabel,
    );
  }
}

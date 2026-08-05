import '../domain/express_models.dart';
import 'express_repository.dart';

/// Offline demo — smart merchant selection without a second ledger.
class SeedExpressRepository implements ExpressRepository {
  final _orders = <ExpressOrder>[];
  var _n = 0;

  static const _catalog = <ExpressProduct>[
    ExpressProduct(
      id: 'p1',
      name: 'Milk',
      priceMinor: 3500,
      storeName: 'Karibu Mart Masaki',
      sku: 'MILK-1L',
      stockQty: 40,
    ),
    ExpressProduct(
      id: 'p2',
      name: 'Bread',
      priceMinor: 2000,
      storeName: 'Karibu Mart Masaki',
      sku: 'BREAD',
      stockQty: 30,
    ),
    ExpressProduct(
      id: 'p3',
      name: 'Eggs',
      priceMinor: 6500,
      storeName: 'Karibu Mart Masaki',
      sku: 'EGGS-12',
      stockQty: 25,
    ),
    ExpressProduct(
      id: 'p4',
      name: 'Rice',
      priceMinor: 18000,
      storeName: 'Karibu Mart Masaki',
      sku: 'RICE-5KG',
      stockQty: 20,
    ),
    ExpressProduct(
      id: 'p5',
      name: 'Soap',
      priceMinor: 2500,
      storeName: 'Karibu Mart Masaki',
      sku: 'SOAP',
      stockQty: 50,
    ),
    ExpressProduct(
      id: 'p6',
      name: 'Paracetamol',
      priceMinor: 2000,
      storeName: 'Afya Pharmacy',
      sku: 'PARA-500',
      stockQty: 80,
    ),
  ];

  @override
  Future<List<ExpressProduct>> searchProducts({
    String query = '',
    String category = '',
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return List.of(_catalog);
    return _catalog.where((p) => p.name.toLowerCase().contains(q)).toList();
  }

  @override
  Future<List<ExpressRankedStore>> rankStores({
    required double lat,
    required double lng,
    List<String> products = const [],
    String category = '',
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return const [
      ExpressRankedStore(
        storeId: 's1',
        code: 'xp-karibu-mart',
        name: 'Karibu Mart Masaki',
        distanceM: 620,
        etaMinutes: 18,
        score: 1.2,
        rating: 4.7,
        coverage: 1,
      ),
    ];
  }

  @override
  Future<ExpressBasketSuggestion> aiBasket(String prompt) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final p = prompt.toLowerCase();
    var theme = 'custom';
    var items = <ExpressBasketItem>[
      const ExpressBasketItem(name: 'Milk'),
      const ExpressBasketItem(name: 'Bread'),
    ];
    if (p.contains('breakfast')) {
      theme = 'breakfast';
      items = const [
        ExpressBasketItem(name: 'Milk', qty: 2),
        ExpressBasketItem(name: 'Bread'),
        ExpressBasketItem(name: 'Eggs'),
      ];
    } else if (p.contains('dinner') || p.contains('pilau')) {
      theme = p.contains('pilau') ? 'pilau' : 'dinner';
      items = const [
        ExpressBasketItem(name: 'Rice'),
        ExpressBasketItem(name: 'Chicken'),
        ExpressBasketItem(name: 'Onions'),
      ];
    } else if (p.contains('weekly') || p.contains('grocery')) {
      theme = 'weekly';
      items = const [
        ExpressBasketItem(name: 'Milk', qty: 3),
        ExpressBasketItem(name: 'Bread', qty: 2),
        ExpressBasketItem(name: 'Rice'),
        ExpressBasketItem(name: 'Soap'),
      ];
    }
    return ExpressBasketSuggestion(
      prompt: prompt,
      theme: theme,
      items: items,
      disclaimer:
          'AI suggests a basket only. You must review and pay — AI never authorizes payments.',
    );
  }

  @override
  Future<ParsedShoppingList> parseShoppingList({
    required String text,
    double lat = -6.75,
    double lng = 39.28,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final matched = <ExpressBasketItem>[];
    final unknown = <ExpressBasketItem>[];
    for (final raw in text.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      var qty = 1;
      var name = line;
      final lead = RegExp(r'^(\d+)\s+(.+)$').firstMatch(line);
      final xQty = RegExp(r'^(.+?)\s*[x×]\s*(\d+)$', caseSensitive: false).firstMatch(line);
      if (lead != null) {
        qty = int.parse(lead.group(1)!);
        name = lead.group(2)!;
      } else if (xQty != null) {
        name = xQty.group(1)!;
        qty = int.parse(xQty.group(2)!);
      }
      final key = name.toLowerCase().replaceAll('cook oil', 'oil').replaceAll('cooking oil', 'oil');
      final hit = _catalog.where((p) => p.name.toLowerCase().contains(key.split(' ').first));
      if (hit.isEmpty) {
        unknown.add(ExpressBasketItem(name: name, qty: qty, status: 'unknown'));
      } else {
        final p = hit.first;
        matched.add(
          ExpressBasketItem(
            name: p.name,
            qty: qty,
            sku: p.sku,
            productId: p.id,
            priceMinor: p.priceMinor,
            storeName: p.storeName,
          ),
        );
      }
    }
    final subtotal = matched.fold<int>(0, (s, i) => s + i.lineTotalMinor);
    return ParsedShoppingList(
      matched: matched,
      unknown: unknown,
      items: matched,
      subtotalMinor: subtotal,
      preferredStoreName: matched.isEmpty ? '' : matched.first.storeName,
    );
  }

  @override
  Future<ExpressQuote> quote({
    required List<ExpressBasketItem> items,
    required double lat,
    required double lng,
    String urgency = 'standard',
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final subtotal = items.fold<int>(0, (sum, i) {
      final match = _catalog.where(
        (p) => p.name.toLowerCase() == i.name.toLowerCase(),
      );
      final price = match.isEmpty ? 3000 : match.first.priceMinor;
      return sum + price * i.qty;
    });
    final delivery = urgency == 'express' ? 2500 : 1800;
    final platform = (subtotal * 0.02).round().clamp(200, 999999);
    return ExpressQuote(
      subtotalMinor: subtotal,
      deliveryFeeMinor: delivery,
      platformFeeMinor: platform,
      totalMinor: subtotal + delivery + platform,
      etaMinutes: urgency == 'express' ? 15 : 22,
      storeName: 'Karibu Mart Masaki',
    );
  }

  @override
  Future<ExpressOrder> checkout({
    required List<ExpressBasketItem> items,
    required double lat,
    required double lng,
    String address = '',
    String phone = '',
    String notes = '',
    String urgency = 'standard',
    String aiPrompt = '',
    String paymentTiming = 'prepaid',
    String paymentMethod = 'wallet',
    bool autoReady = true,
    String? idempotencyKey,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final q = await quote(items: items, lat: lat, lng: lng, urgency: urgency);
    final code = 'xp_seed_${++_n}';
    final pkg = 'pkg_seed_$_n';
    final timeline = <Map<String, dynamic>>[
      {'event': 'basket_submitted'},
      {'event': 'merchant_found'},
      {'event': 'merchant_accepted'},
      if (paymentTiming == 'prepaid') {'event': 'paid'},
      {'event': 'preparing'},
      if (autoReady) ...[
        {'event': 'ready'},
        {'event': 'rider_assigned'},
      ],
      {'event': 'settlement_allocated'},
    ];
    final order = ExpressOrder(
      id: 'oid_$_n',
      publicCode: code,
      status: autoReady ? 'rider_assigned' : 'preparing',
      totalMinor: q.totalMinor,
      subtotalMinor: q.subtotalMinor,
      deliveryFeeMinor: q.deliveryFeeMinor,
      platformFeeMinor: q.platformFeeMinor,
      storeName: q.storeName,
      paymentRef: paymentTiming == 'prepaid' ? 'seed_pay_$_n' : '',
      tripId: autoReady ? 'trip_seed_$_n' : '',
      deliveryId: autoReady ? 'del_seed_$_n' : '',
      packageCode: pkg,
      packageQr: 'taifa://express/pkg/$pkg',
      deliveryPin: '123456',
      customerAddress: address,
      settlementStatus: 'allocated',
      etaMinutes: q.etaMinutes,
      lines: items
          .map((i) => {'name': i.name, 'qty': i.qty, 'line_total_minor': i.qty * 3000})
          .toList(),
      ranking: await rankStores(lat: lat, lng: lng),
      timeline: timeline,
      settlementPlan: {
        'allocations': [
          {'party': 'merchant', 'amount_minor': q.subtotalMinor},
          {'party': 'rider', 'amount_minor': q.deliveryFeeMinor},
          {'party': 'platform', 'amount_minor': q.platformFeeMinor},
        ],
      },
    );
    _orders.insert(0, order);
    return order;
  }

  @override
  Future<ExpressOrder> merchantReady(String orderId) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final idx = _orders.indexWhere((o) => o.id == orderId || o.publicCode == orderId);
    if (idx < 0) throw StateError('order not found');
    final prev = _orders[idx];
    final next = ExpressOrder(
      id: prev.id,
      publicCode: prev.publicCode,
      status: 'rider_assigned',
      totalMinor: prev.totalMinor,
      subtotalMinor: prev.subtotalMinor,
      deliveryFeeMinor: prev.deliveryFeeMinor,
      platformFeeMinor: prev.platformFeeMinor,
      currency: prev.currency,
      storeName: prev.storeName,
      paymentRef: prev.paymentRef,
      tripId: 'trip_ready_${prev.id}',
      deliveryId: 'del_ready_${prev.id}',
      packageCode: prev.packageCode,
      packageQr: prev.packageQr,
      deliveryPin: prev.deliveryPin,
      customerAddress: prev.customerAddress,
      customerLat: prev.customerLat,
      customerLng: prev.customerLng,
      settlementStatus: prev.settlementStatus,
      etaMinutes: prev.etaMinutes,
      lines: prev.lines,
      ranking: prev.ranking,
      timeline: [
        ...prev.timeline,
        {'event': 'ready'},
        {'event': 'rider_assigned'},
      ],
      settlementPlan: prev.settlementPlan,
    );
    _orders[idx] = next;
    return next;
  }

  @override
  Future<List<ExpressOrder>> listOrders() async => List.of(_orders);

  @override
  Future<ExpressOrder> getOrder(String orderId) async {
    return _orders.firstWhere(
      (o) => o.id == orderId || o.publicCode == orderId,
      orElse: () => throw StateError('order not found'),
    );
  }
}

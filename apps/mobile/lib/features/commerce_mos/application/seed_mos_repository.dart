import '../domain/mos_models.dart';
import 'mos_repository.dart';

/// Offline-first MOS seed — demo retail shop for cashiers/warehouse/owners.
class SeedMosRepository implements MosRepository {
  final _products = <MosProduct>[
    const MosProduct(
      id: 'p1',
      sku: 'RICE-5KG',
      name: 'Rice 5kg',
      priceMinor: 1200000,
      stockAvailable: 48,
      favorite: true,
      category: 'Staples',
    ),
    const MosProduct(
      id: 'p2',
      sku: 'OIL-1L',
      name: 'Cooking Oil 1L',
      priceMinor: 650000,
      stockAvailable: 22,
      favorite: true,
      category: 'Staples',
    ),
    const MosProduct(
      id: 'p3',
      sku: 'SOAP-BAR',
      name: 'Bar Soap',
      priceMinor: 150000,
      stockAvailable: 4,
      category: 'Household',
    ),
    const MosProduct(
      id: 'p4',
      sku: 'SUGAR-2KG',
      name: 'Sugar 2kg',
      priceMinor: 550000,
      stockAvailable: 0,
      category: 'Staples',
    ),
    const MosProduct(
      id: 'p5',
      sku: 'TEA-500',
      name: 'Tea 500g',
      priceMinor: 420000,
      stockAvailable: 31,
      category: 'Beverages',
    ),
  ];

  final _orders = <MosOrder>[];
  final _suppliers = <MosSupplier>[
    const MosSupplier(id: 's1', code: 'afya-dist', name: 'Afya Distributors', rating: 4.5),
    const MosSupplier(id: 's2', code: 'kariakoo', name: 'Kariakoo Wholesale', rating: 4.1),
  ];
  final _pos = <MosPurchaseOrder>[
      const MosPurchaseOrder(
      id: 'po1',
      supplierName: 'Afya Distributors',
      status: 'submitted',
      totalMinor: 24000000,
    ),
  ];
  final _customers = <MosCustomer>[
    const MosCustomer(id: 'c1', displayName: 'Asha M.', phone: '+255700000001', loyaltyPoints: 120),
    const MosCustomer(id: 'c2', displayName: 'Juma K.', phone: '+255700000002', loyaltyPoints: 40),
  ];

  MosPosSession? _session;
  var _seq = 100;

  @override
  Future<MosAnalytics> bootstrap() async => analytics();

  @override
  Future<List<MosProduct>> products({String query = ''}) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return List.unmodifiable(_products);
    return _products
        .where(
          (p) =>
              p.name.toLowerCase().contains(q) ||
              p.sku.toLowerCase().contains(q) ||
              p.category.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Future<List<MosOrder>> orders() async => List.unmodifiable(_orders.reversed);

  @override
  Future<List<MosSupplier>> suppliers() async => List.unmodifiable(_suppliers);

  @override
  Future<List<MosPurchaseOrder>> purchaseOrders() async => List.unmodifiable(_pos);

  @override
  Future<List<MosCustomer>> customers() async => List.unmodifiable(_customers);

  @override
  Future<MosAnalytics> analytics() async {
    final paid = _orders.where((o) => o.paid);
    return MosAnalytics(
      products: _products.length,
      ordersTotal: _orders.length,
      ordersPaid: paid.length,
      gmvMinor: paid.fold<int>(0, (a, o) => a + o.totalMinor),
      customers: _customers.length,
      lowStock: _products.where((p) => p.isLowStock || p.isOutOfStock).length,
      wingaEnabled: true,
    );
  }

  @override
  Future<MosOrder> createOrder({
    required List<({String productId, int quantity})> lines,
    String channel = 'pos',
  }) async {
    if (lines.isEmpty) throw StateError('order requires lines');
    final orderLines = <MosOrderLine>[];
    var total = 0;
    for (final line in lines) {
      final i = _products.indexWhere((p) => p.id == line.productId);
      if (i < 0) throw StateError('product not found');
      final p = _products[i];
      if (p.stockAvailable < line.quantity) {
        throw StateError('insufficient stock for ${p.name}');
      }
      _products[i] = p.copyWith(
        stockAvailable: p.stockAvailable - line.quantity,
        stockReserved: p.stockReserved + line.quantity,
      );
      orderLines.add(
        MosOrderLine(
          productId: p.id,
          name: p.name,
          quantity: line.quantity,
          unitPriceMinor: p.priceMinor,
        ),
      );
      total += p.priceMinor * line.quantity;
    }
    final order = MosOrder(
      id: 'ord-${_seq++}',
      status: 'open',
      totalMinor: total,
      channel: channel,
      lines: orderLines,
      timeline: ['created', 'reserved'],
    );
    _orders.add(order);
    return order;
  }

  @override
  Future<MosOrder> payOrder(String orderId, {required String idempotencyKey}) async {
    final i = _orders.indexWhere((o) => o.id == orderId);
    if (i < 0) throw StateError('order not found');
    final o = _orders[i];
    if (o.paid) return o;
    final paid = MosOrder(
      id: o.id,
      status: 'confirmed',
      totalMinor: o.totalMinor,
      channel: o.channel,
      paid: true,
      paymentRef: 'pay-$idempotencyKey',
      lines: o.lines,
      timeline: [...o.timeline, 'paid', 'ledger_confirmed'],
    );
    _orders[i] = paid;
    return paid;
  }

  @override
  Future<MosOrder> fulfillOrder(String orderId) async {
    final i = _orders.indexWhere((o) => o.id == orderId);
    if (i < 0) throw StateError('order not found');
    final o = _orders[i];
    if (!o.paid) throw StateError('order must be paid');
    for (final line in o.lines) {
      final pi = _products.indexWhere((p) => p.id == line.productId);
      if (pi < 0) continue;
      final p = _products[pi];
      _products[pi] = p.copyWith(
        stockReserved: (p.stockReserved - line.quantity).clamp(0, 1e9),
      );
    }
    final done = MosOrder(
      id: o.id,
      status: 'fulfilled',
      totalMinor: o.totalMinor,
      channel: o.channel,
      paid: true,
      paymentRef: o.paymentRef,
      lines: o.lines,
      timeline: [...o.timeline, 'picking', 'packing', 'fulfilled'],
    );
    _orders[i] = done;
    return done;
  }

  @override
  Future<void> adjustStock({
    required String productId,
    required String kind,
    required num quantity,
  }) async {
    final i = _products.indexWhere((p) => p.id == productId);
    if (i < 0) throw StateError('product not found');
    final p = _products[i];
    num available = p.stockAvailable;
    if (kind == 'receive' || kind == 'return') {
      available += quantity;
    } else if (kind == 'issue') {
      available -= quantity;
    } else if (kind == 'count' || kind == 'adjust') {
      available = quantity;
    }
    _products[i] = p.copyWith(stockAvailable: available < 0 ? 0 : available);
  }

  @override
  Future<MosPosSession> openPosSession() async {
    _session = MosPosSession(id: 'pos-${_seq++}', status: 'open', openingFloatMinor: 50000);
    return _session!;
  }

  @override
  Future<MosPosSession> closePosSession(String sessionId, {int closingCashMinor = 0}) async {
    _session = MosPosSession(id: sessionId, status: 'closed', openingFloatMinor: closingCashMinor);
    return _session!;
  }

  @override
  Future<List<String>> assist(String capability) async {
    final c = capability.toLowerCase();
    if (c.contains('authorize') || c.contains('payment') || c.contains('settle')) {
      throw StateError('AI must never authorize payments');
    }
    return switch (c) {
      'inventory_forecast' || 'reorder' => [
          'Reorder Bar Soap — only 4 units left',
          'Rice 5kg is fast-moving — receive before weekend',
        ],
      'pricing' => [
          'Cooking Oil margin healthy at current cost',
          'Test weekend 5% promo on staples',
        ],
      'briefing' || 'daily' => [
          'Open POS and clear unpaid orders first',
          '${_products.where((p) => p.isLowStock || p.isOutOfStock).length} SKUs need attention',
        ],
      _ => ['Try inventory_forecast, pricing, or briefing'],
    };
  }

  @override
  Future<void> publishToWinga(String productId) async {
    if (!_products.any((p) => p.id == productId)) {
      throw StateError('product not found');
    }
  }
}

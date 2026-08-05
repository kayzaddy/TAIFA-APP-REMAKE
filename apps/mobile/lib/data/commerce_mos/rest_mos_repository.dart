import '../../features/commerce_mos/application/mos_repository.dart';
import '../../features/commerce_mos/application/seed_mos_repository.dart';
import '../../features/commerce_mos/domain/mos_models.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';

/// Live MOS client against `/api/v1/mos/*` with seed soft-fallback.
class RestMosRepository implements MosRepository {
  RestMosRepository(this._client, {MosRepository? fallback})
      : _fallback = fallback ?? SeedMosRepository();

  final TaifaApiClient _client;
  final MosRepository _fallback;
  String? _merchantId;

  Future<T> _guard<T>(Future<T> Function() live, Future<T> Function() soft) async {
    try {
      return await live();
    } on ApiException {
      return soft();
    } on StateError {
      rethrow;
    } catch (_) {
      return soft();
    }
  }

  Future<String> _ensureMerchant() async {
    if (_merchantId != null) return _merchantId!;
    final json = await _client.postJson(
      '/api/v1/mos/bootstrap',
      body: {
        'code': 'taifa-demo-retail',
        'legal_name': 'Taifa Demo Retail Ltd',
        'business_type': 'retail',
      },
    );
    final cm = json['commerce_merchant'] as Map<String, dynamic>? ?? {};
    _merchantId = cm['merchant_id']?.toString();
    if (_merchantId == null || _merchantId!.isEmpty) {
      throw StateError('MOS bootstrap missing merchant_id');
    }
    return _merchantId!;
  }

  String _base(String mid) => '/api/v1/mos/merchants/$mid';

  MosProduct _product(Map<String, dynamic> m) => MosProduct(
        id: m['id']?.toString() ?? '',
        sku: m['sku']?.toString() ?? '',
        name: m['name']?.toString() ?? '',
        priceMinor: (m['price_minor'] as num?)?.toInt() ?? 0,
        kind: m['kind']?.toString() ?? 'physical',
      );

  MosOrder _order(Map<String, dynamic> m) {
    final lines = (m['lines'] as List? ?? [])
        .whereType<Map>()
        .map(
          (e) => MosOrderLine(
            productId: e['product']?.toString() ?? '',
            name: e['description']?.toString() ?? '',
            quantity: (e['quantity'] as num?) ?? 1,
            unitPriceMinor: (e['unit_price_minor'] as num?)?.toInt() ?? 0,
          ),
        )
        .toList();
    return MosOrder(
      id: m['id']?.toString() ?? '',
      status: m['status']?.toString() ?? 'open',
      totalMinor: (m['total_minor'] as num?)?.toInt() ?? 0,
      channel: m['channel']?.toString() ?? 'pos',
      paid: m['paid'] == true,
      paymentRef: m['payment_ref']?.toString() ?? '',
      lines: lines,
      timeline: (m['timeline'] as List? ?? [])
          .map((e) => e is Map ? (e['event']?.toString() ?? '') : e.toString())
          .where((e) => e.isNotEmpty)
          .toList(),
    );
  }

  @override
  Future<MosAnalytics> bootstrap() => _guard(() async {
        final mid = await _ensureMerchant();
        final json = await _client.getJson('${_base(mid)}/analytics/summary');
        return MosAnalytics(
          products: (json['products'] as num?)?.toInt() ?? 0,
          ordersTotal: (json['orders_total'] as num?)?.toInt() ?? 0,
          ordersPaid: (json['orders_paid'] as num?)?.toInt() ?? 0,
          gmvMinor: (json['gmv_minor'] as num?)?.toInt() ?? 0,
          customers: (json['customers'] as num?)?.toInt() ?? 0,
          lowStock: (json['low_stock'] as num?)?.toInt() ?? 0,
          wingaEnabled: json['winga_enabled'] == true,
        );
      }, _fallback.bootstrap);

  @override
  Future<List<MosProduct>> products({String query = ''}) => _guard(() async {
        final mid = await _ensureMerchant();
        final q = query.isEmpty ? '' : '?q=${Uri.encodeQueryComponent(query)}';
        final list = await _client.getJsonList('${_base(mid)}/products$q');
        return list
            .whereType<Map>()
            .map((e) => _product(Map<String, dynamic>.from(e)))
            .toList();
      }, () => _fallback.products(query: query));

  @override
  Future<List<MosOrder>> orders() => _guard(() async {
        final mid = await _ensureMerchant();
        final list = await _client.getJsonList('${_base(mid)}/orders');
        return list
            .whereType<Map>()
            .map((e) => _order(Map<String, dynamic>.from(e)))
            .toList();
      }, _fallback.orders);

  @override
  Future<List<MosSupplier>> suppliers() => _guard(() async {
        final mid = await _ensureMerchant();
        final list = await _client.getJsonList('${_base(mid)}/suppliers');
        return list
            .whereType<Map>()
            .map(
              (e) => MosSupplier(
                id: e['id']?.toString() ?? '',
                code: e['code']?.toString() ?? '',
                name: e['name']?.toString() ?? '',
                rating: ((e['rating_e4'] as num?)?.toDouble() ?? 5000) / 1000,
              ),
            )
            .toList();
      }, _fallback.suppliers);

  @override
  Future<List<MosPurchaseOrder>> purchaseOrders() => _guard(() async {
        final mid = await _ensureMerchant();
        final list = await _client.getJsonList('${_base(mid)}/purchase-orders');
        return list
            .whereType<Map>()
            .map(
              (e) => MosPurchaseOrder(
                id: e['id']?.toString() ?? '',
                supplierName: e['supplier']?.toString() ?? '',
                status: e['status']?.toString() ?? 'draft',
                totalMinor: (e['total_minor'] as num?)?.toInt() ?? 0,
              ),
            )
            .toList();
      }, _fallback.purchaseOrders);

  @override
  Future<List<MosCustomer>> customers() => _guard(() async {
        final mid = await _ensureMerchant();
        final list = await _client.getJsonList('${_base(mid)}/customers');
        return list
            .whereType<Map>()
            .map(
              (e) => MosCustomer(
                id: e['id']?.toString() ?? '',
                displayName: e['display_name']?.toString() ?? '',
                phone: e['phone']?.toString() ?? '',
                loyaltyPoints: (e['loyalty_points'] as num?)?.toInt() ?? 0,
              ),
            )
            .toList();
      }, _fallback.customers);

  @override
  Future<MosAnalytics> analytics() => bootstrap();

  @override
  Future<MosOrder> createOrder({
    required List<({String productId, int quantity})> lines,
    String channel = 'pos',
  }) =>
      _guard(() async {
        final mid = await _ensureMerchant();
        final json = await _client.postJson(
          '${_base(mid)}/orders',
          body: {
            'channel': channel,
            'lines': [
              for (final l in lines)
                {'product_id': l.productId, 'quantity': l.quantity},
            ],
          },
        );
        return _order(json);
      }, () => _fallback.createOrder(lines: lines, channel: channel));

  @override
  Future<MosOrder> payOrder(String orderId, {required String idempotencyKey}) =>
      _guard(() async {
        final mid = await _ensureMerchant();
        final json = await _client.postJson(
          '${_base(mid)}/orders/$orderId/pay',
          body: {},
          idempotencyKey: idempotencyKey,
        );
        return _order(json);
      }, () => _fallback.payOrder(orderId, idempotencyKey: idempotencyKey));

  @override
  Future<MosOrder> fulfillOrder(String orderId) => _guard(() async {
        final mid = await _ensureMerchant();
        final json = await _client.postJson('${_base(mid)}/orders/$orderId/fulfill');
        return _order(json);
      }, () => _fallback.fulfillOrder(orderId));

  @override
  Future<void> adjustStock({
    required String productId,
    required String kind,
    required num quantity,
  }) =>
      _guard(() async {
        final mid = await _ensureMerchant();
        final stock = await _client.getJsonList('${_base(mid)}/stock');
        final wh = stock.isNotEmpty
            ? (stock.first as Map)['warehouse']?.toString()
            : null;
        final warehouses = await _client.getJsonList('${_base(mid)}/warehouses');
        final warehouseId = wh ??
            (warehouses.isNotEmpty
                ? (warehouses.first as Map)['id']?.toString()
                : null);
        if (warehouseId == null) throw StateError('no warehouse');
        await _client.postJson(
          '${_base(mid)}/stock/adjust',
          body: {
            'warehouse_id': warehouseId,
            'product_id': productId,
            'kind': kind,
            'quantity': quantity,
          },
        );
      }, () => _fallback.adjustStock(productId: productId, kind: kind, quantity: quantity));

  @override
  Future<MosPosSession> openPosSession() => _guard(() async {
        final mid = await _ensureMerchant();
        final branches = await _client.getJsonList('${_base(mid)}/branches');
        if (branches.isEmpty) throw StateError('no branch');
        final json = await _client.postJson(
          '${_base(mid)}/pos/sessions',
          body: {
            'branch_id': (branches.first as Map)['id'],
            'opening_float_minor': 50000,
          },
        );
        return MosPosSession(
          id: json['id']?.toString() ?? '',
          status: json['status']?.toString() ?? 'open',
          openingFloatMinor: (json['opening_float_minor'] as num?)?.toInt() ?? 0,
        );
      }, _fallback.openPosSession);

  @override
  Future<MosPosSession> closePosSession(String sessionId, {int closingCashMinor = 0}) =>
      _guard(() async {
        final mid = await _ensureMerchant();
        final json = await _client.postJson(
          '${_base(mid)}/pos/sessions/$sessionId/close',
          body: {'closing_cash_minor': closingCashMinor},
        );
        return MosPosSession(
          id: json['id']?.toString() ?? sessionId,
          status: json['status']?.toString() ?? 'closed',
          openingFloatMinor: closingCashMinor,
        );
      }, () => _fallback.closePosSession(sessionId, closingCashMinor: closingCashMinor));

  @override
  Future<List<String>> assist(String capability) => _guard(() async {
        final mid = await _ensureMerchant();
        final json = await _client.postJson(
          '${_base(mid)}/assist',
          body: {'capability': capability},
        );
        if (json['blocked'] == true) {
          throw StateError('AI must never authorize payments');
        }
        return (json['tips'] as List? ?? []).map((e) => e.toString()).toList();
      }, () => _fallback.assist(capability));

  @override
  Future<void> publishToWinga(String productId) => _guard(() async {
        final mid = await _ensureMerchant();
        await _client.postJson('${_base(mid)}/products/$productId/publish-winga');
      }, () => _fallback.publishToWinga(productId));
}

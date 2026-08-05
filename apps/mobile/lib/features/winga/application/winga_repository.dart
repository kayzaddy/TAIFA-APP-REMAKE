import '../data/winga_catalog.dart';
import '../domain/winga_models.dart';

abstract interface class WingaRepository {
  Future<List<WingaStore>> stores();
  Future<List<WingaProduct>> products({String? category, String? query});
  Future<List<WingaServiceOffer>> services({String? category});
  Future<WingaOrder> placeOrder(WingaOrder draft);
  Future<WingaServiceBooking> bookService(WingaServiceBooking draft);
  Future<WingaShopDraft> submitShop(WingaShopDraft draft);
  Future<WingaMerchantStats> merchantStats();
  Future<List<WingaMerchantOrder>> merchantOrders();
}

class SeedWingaRepository implements WingaRepository {
  final Map<String, WingaOrder> _orders = {};
  final List<String> _orderIds = [];
  WingaShopDraft? _shop;
  int _seq = 0;

  @override
  Future<List<WingaStore>> stores() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return WingaCatalog.stores();
  }

  @override
  Future<List<WingaProduct>> products({String? category, String? query}) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    var list = WingaCatalog.products();
    if (category != null && category.isNotEmpty) {
      list = list.where((p) => p.category == category).toList();
    }
    if (query != null && query.trim().isNotEmpty) {
      final q = query.toLowerCase();
      list = list
          .where(
            (p) =>
                p.name.toLowerCase().contains(q) ||
                p.category.toLowerCase().contains(q) ||
                p.description.toLowerCase().contains(q),
          )
          .toList();
    }
    return list;
  }

  @override
  Future<List<WingaServiceOffer>> services({String? category}) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    var list = WingaCatalog.services();
    if (category != null && category.isNotEmpty) {
      list = list.where((s) => s.category == category).toList();
    }
    return list;
  }

  @override
  Future<WingaOrder> placeOrder(WingaOrder draft) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final id = 'wo-${DateTime.now().millisecondsSinceEpoch}-${_seq++}';
    final order = WingaOrder(
      id: id,
      lines: draft.lines,
      total: draft.total,
      status: WingaOrderStatus.placed,
      createdAt: DateTime.now(),
      paymentRef: draft.paymentRef,
    );
    _orders[id] = order;
    _orderIds.insert(0, id);
    return order;
  }

  @override
  Future<WingaServiceBooking> bookService(WingaServiceBooking draft) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final id = 'ws-${DateTime.now().millisecondsSinceEpoch}-${_seq++}';
    return WingaServiceBooking(
      id: id,
      service: draft.service,
      slotLabel: draft.slotLabel,
      total: draft.total,
      createdAt: DateTime.now(),
      paymentRef: draft.paymentRef,
    );
  }

  @override
  Future<WingaShopDraft> submitShop(WingaShopDraft draft) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _shop = draft.copyWith(status: WingaShopStatus.pending);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _shop = _shop!.copyWith(status: WingaShopStatus.approved);
    return _shop!;
  }

  @override
  Future<WingaMerchantStats> merchantStats() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return WingaMerchantStats(
      salesToday: WingaCatalog.m(1284000),
      openOrders: 3,
      products: WingaCatalog.products().length,
      customers: 186,
    );
  }

  @override
  Future<List<WingaMerchantOrder>> merchantOrders() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return WingaCatalog.merchantOrders();
  }
}

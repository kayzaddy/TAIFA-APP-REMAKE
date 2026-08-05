import '../../wallet/domain/currency.dart';
import '../../wallet/domain/money.dart';
import '../data/merchant_seed.dart';
import '../domain/merchant_models.dart';

abstract interface class MerchantRepository {
  Future<List<MerchantOrder>> listOrders();
  Future<MerchantOrder> advance(String id);
  Future<MerchantStats> stats();
}

class SeedMerchantRepository implements MerchantRepository {
  final Map<String, MerchantOrder> _byId = {
    for (final o in MerchantSeed.orders()) o.id: o,
  };

  @override
  Future<List<MerchantOrder>> listOrders() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final list = _byId.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<MerchantStats> stats() async {
    final orders = await listOrders();
    final open = orders
        .where(
          (o) =>
              o.status == MerchantOrderStatus.newOrder ||
              o.status == MerchantOrderStatus.preparing ||
              o.status == MerchantOrderStatus.ready,
        )
        .length;
    final done = orders
        .where((o) => o.status == MerchantOrderStatus.completed)
        .toList();
    var sales = Money.zero(Currency.tzs);
    for (final o in done) {
      sales = sales + o.total;
    }
    for (final o in orders.where(
      (o) =>
          o.status != MerchantOrderStatus.cancelled &&
          o.status != MerchantOrderStatus.completed,
    )) {
      sales = sales + o.total;
    }
    return MerchantStats(
      todaySales: sales,
      openOrders: open,
      completedToday: done.length,
    );
  }

  @override
  Future<MerchantOrder> advance(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 280));
    final cur = _byId[id]!;
    final next = switch (cur.status) {
      MerchantOrderStatus.newOrder => MerchantOrderStatus.preparing,
      MerchantOrderStatus.preparing => MerchantOrderStatus.ready,
      MerchantOrderStatus.ready => MerchantOrderStatus.completed,
      _ => cur.status,
    };
    final updated = cur.copyWith(status: next);
    _byId[id] = updated;
    return updated;
  }
}

import '../../features/merchant/application/merchant_repository.dart';
import '../../features/merchant/data/merchant_seed.dart';
import '../../features/merchant/domain/merchant_models.dart';
import '../../features/wallet/domain/currency.dart';
import '../../features/wallet/domain/money.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import 'merchant_api_paths.dart';
import 'merchant_order_dto.dart';

/// Live [MerchantRepository]: hydrates demo orders once, then advances via API.
class RestMerchantRepository implements MerchantRepository {
  RestMerchantRepository(this._client);

  final TaifaApiClient _client;
  bool _seeded = false;

  @override
  Future<List<MerchantOrder>> listOrders() async {
    try {
      var list = await _fetch();
      if (list.isEmpty && !_seeded) {
        await _hydrateSeed();
        _seeded = true;
        list = await _fetch();
      }
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
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
    try {
      final current = MerchantOrderDto.toDomain(
        await _client.getJson(MerchantApiPaths.merchantOrder(id)),
      );
      final next = switch (current.status) {
        MerchantOrderStatus.newOrder => MerchantOrderStatus.preparing,
        MerchantOrderStatus.preparing => MerchantOrderStatus.ready,
        MerchantOrderStatus.ready => MerchantOrderStatus.completed,
        _ => current.status,
      };
      final json = await _client.patchJson(
        MerchantApiPaths.merchantOrder(id),
        body: MerchantOrderDto.patchBody(current.copyWith(status: next)),
      );
      return MerchantOrderDto.toDomain(json);
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  Future<List<MerchantOrder>> _fetch() async {
    final list = await _client.getJsonList(MerchantApiPaths.merchantOrders);
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .map(MerchantOrderDto.toDomain)
        .toList();
  }

  Future<void> _hydrateSeed() async {
    for (final order in MerchantSeed.orders()) {
      await _client.postJson(
        MerchantApiPaths.merchantOrders,
        body: MerchantOrderDto.createBody(order),
      );
    }
  }

  String _message(ApiException e) => switch (e) {
    NetworkException() => e.message,
    ApiStatusException(:final message) => message,
    ApiDecodeException() => e.message,
  };
}

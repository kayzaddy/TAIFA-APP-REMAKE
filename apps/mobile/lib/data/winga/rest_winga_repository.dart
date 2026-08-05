import '../../features/winga/application/winga_repository.dart';
import '../../features/winga/domain/winga_models.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import 'winga_api_paths.dart';
import 'winga_dto.dart';

/// Live WINGA writes against commerce APIs; catalog/merchant feeds stay seed.
class RestWingaRepository implements WingaRepository {
  RestWingaRepository(this._client, {WingaRepository? catalog})
    : _catalog = catalog ?? SeedWingaRepository();

  final TaifaApiClient _client;
  final WingaRepository _catalog;
  final Map<String, List<WingaCartLine>> _orderLines = {};
  final Map<String, WingaServiceOffer> _services = {};

  @override
  Future<List<WingaStore>> stores() => _catalog.stores();

  @override
  Future<List<WingaProduct>> products({String? category, String? query}) =>
      _catalog.products(category: category, query: query);

  @override
  Future<List<WingaServiceOffer>> services({String? category}) =>
      _catalog.services(category: category);

  @override
  Future<WingaMerchantStats> merchantStats() => _catalog.merchantStats();

  @override
  Future<List<WingaMerchantOrder>> merchantOrders() =>
      _catalog.merchantOrders();

  @override
  Future<WingaOrder> placeOrder(WingaOrder draft) async {
    try {
      final json = await _client.postJson(
        WingaApiPaths.orders,
        body: WingaDto.orderCreateBody(draft),
      );
      final order = WingaDto.orderToDomain(json, lines: draft.lines);
      _orderLines[order.id] = List<WingaCartLine>.from(draft.lines);
      return order;
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<WingaServiceBooking> bookService(WingaServiceBooking draft) async {
    try {
      final json = await _client.postJson(
        WingaApiPaths.serviceBookings,
        body: WingaDto.serviceCreateBody(draft),
      );
      final booked = WingaDto.serviceToDomain(json, service: draft.service);
      _services[booked.id] = draft.service;
      return booked;
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<WingaShopDraft> submitShop(WingaShopDraft draft) async {
    try {
      final json = await _client.postJson(
        WingaApiPaths.shops,
        body: WingaDto.shopCreateBody(draft),
      );
      return WingaDto.shopToDomain(json);
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  String _message(ApiException e) => switch (e) {
    NetworkException() => e.message,
    ApiStatusException(:final message) => message,
    ApiDecodeException() => e.message,
  };
}

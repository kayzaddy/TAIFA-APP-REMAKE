import '../../features/express/application/express_repository.dart';
import '../../features/express/application/seed_express_repository.dart';
import '../../features/express/domain/express_models.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';

class RestExpressRepository implements ExpressRepository {
  RestExpressRepository(this._client, {ExpressRepository? fallback})
      : _fallback = fallback ?? SeedExpressRepository();

  final TaifaApiClient _client;
  final ExpressRepository _fallback;

  Future<T> _guard<T>(Future<T> Function() live, Future<T> Function() soft) async {
    try {
      return await live();
    } on ApiException {
      return soft();
    } catch (_) {
      return soft();
    }
  }

  @override
  Future<List<ExpressProduct>> searchProducts({
    String query = '',
    String category = '',
  }) =>
      _guard(() async {
        final q = <String, String>{};
        if (query.isNotEmpty) q['q'] = query;
        if (category.isNotEmpty) q['category'] = category;
        final path = q.isEmpty
            ? '/api/v1/express/products'
            : '/api/v1/express/products?${Uri(queryParameters: q).query}';
        final list = await _client.getJsonList(path);
        return list
            .whereType<Map>()
            .map((e) => ExpressProduct.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }, () => _fallback.searchProducts(query: query, category: category));

  @override
  Future<List<ExpressRankedStore>> rankStores({
    required double lat,
    required double lng,
    List<String> products = const [],
    String category = '',
  }) =>
      _guard(() async {
        final params = <String, String>{
          'lat': lat.toString(),
          'lng': lng.toString(),
        };
        if (category.isNotEmpty) params['category'] = category;
        if (products.isNotEmpty) params['q'] = products.join(',');
        final path = '/api/v1/express/rank?${Uri(queryParameters: params).query}';
        final json = await _client.getJson(path);
        final list = json['results'] as List? ?? const [];
        return list
            .whereType<Map>()
            .map((e) => ExpressRankedStore.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }, () => _fallback.rankStores(
            lat: lat,
            lng: lng,
            products: products,
            category: category,
          ));

  @override
  Future<ExpressBasketSuggestion> aiBasket(String prompt) => _guard(() async {
        final json = await _client.postJson(
          '/api/v1/express/ai/basket',
          body: {'prompt': prompt},
        );
        return ExpressBasketSuggestion.fromJson(json);
      }, () => _fallback.aiBasket(prompt));

  @override
  Future<ParsedShoppingList> parseShoppingList({
    required String text,
    double lat = -6.75,
    double lng = 39.28,
  }) =>
      _guard(() async {
        final json = await _client.postJson(
          '/api/v1/express/list/parse',
          body: {'text': text, 'lat': lat, 'lng': lng},
        );
        return ParsedShoppingList.fromJson(json);
      }, () => _fallback.parseShoppingList(text: text, lat: lat, lng: lng));

  @override
  Future<ExpressQuote> quote({
    required List<ExpressBasketItem> items,
    required double lat,
    required double lng,
    String urgency = 'standard',
  }) =>
      _guard(() async {
        final json = await _client.postJson(
          '/api/v1/express/quote',
          body: {
            'items': items.map((e) => e.toJson()).toList(),
            'lat': lat,
            'lng': lng,
            'urgency': urgency,
          },
        );
        return ExpressQuote.fromJson(json);
      }, () => _fallback.quote(items: items, lat: lat, lng: lng, urgency: urgency));

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
  }) =>
      _guard(() async {
        final json = await _client.postJson(
          '/api/v1/express/checkout',
          body: {
            'items': items.map((e) => e.toJson()).toList(),
            'lat': lat,
            'lng': lng,
            'address': address,
            'phone': phone,
            'notes': notes,
            'urgency': urgency,
            'ai_prompt': aiPrompt,
            'payment_timing': paymentTiming,
            'payment_method': paymentMethod,
            'auto_ready': autoReady,
          },
          idempotencyKey:
              idempotencyKey ?? 'xp-${DateTime.now().millisecondsSinceEpoch}',
        );
        return ExpressOrder.fromJson(json);
      }, () => _fallback.checkout(
            items: items,
            lat: lat,
            lng: lng,
            address: address,
            phone: phone,
            notes: notes,
            urgency: urgency,
            aiPrompt: aiPrompt,
            paymentTiming: paymentTiming,
            paymentMethod: paymentMethod,
            autoReady: autoReady,
            idempotencyKey: idempotencyKey,
          ));

  @override
  Future<ExpressOrder> merchantReady(String orderId) => _guard(() async {
        final json = await _client.postJson('/api/v1/express/orders/$orderId/ready');
        return ExpressOrder.fromJson(json);
      }, () => _fallback.merchantReady(orderId));

  @override
  Future<List<ExpressOrder>> listOrders() => _guard(() async {
        final list = await _client.getJsonList('/api/v1/express/orders');
        return list
            .whereType<Map>()
            .map((e) => ExpressOrder.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }, _fallback.listOrders);

  @override
  Future<ExpressOrder> getOrder(String orderId) => _guard(() async {
        final json = await _client.getJson('/api/v1/express/orders/$orderId');
        return ExpressOrder.fromJson(json);
      }, () => _fallback.getOrder(orderId));
}

import '../domain/express_models.dart';

abstract class ExpressRepository {
  Future<List<ExpressProduct>> searchProducts({String query = '', String category = ''});

  Future<List<ExpressRankedStore>> rankStores({
    required double lat,
    required double lng,
    List<String> products = const [],
    String category = '',
  });

  Future<ExpressBasketSuggestion> aiBasket(String prompt);

  Future<ParsedShoppingList> parseShoppingList({
    required String text,
    double lat = -6.75,
    double lng = 39.28,
  });

  Future<ExpressQuote> quote({
    required List<ExpressBasketItem> items,
    required double lat,
    required double lng,
    String urgency = 'standard',
  });

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
  });

  Future<ExpressOrder> merchantReady(String orderId);

  Future<List<ExpressOrder>> listOrders();

  Future<ExpressOrder> getOrder(String orderId);
}

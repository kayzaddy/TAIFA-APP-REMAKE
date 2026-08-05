import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/express/rest_express_repository.dart';
import '../../wallet/application/wallet_providers.dart'
    show apiClientProvider, apiConfigProvider;
import '../domain/express_models.dart';
import 'express_repository.dart';
import 'seed_express_repository.dart';

final expressRepositoryProvider = Provider<ExpressRepository>((ref) {
  final config = ref.watch(apiConfigProvider);
  if (config.useRemoteBackend) {
    return RestExpressRepository(ref.watch(apiClientProvider));
  }
  return SeedExpressRepository();
});

class ExpressUiState {
  const ExpressUiState({
    this.query = '',
    this.category = '',
    this.products = const [],
    this.listText = '',
    this.basket = const [],
    this.unknown = const [],
    this.suggestion,
    this.quote,
    this.lastOrder,
    this.orders = const [],
    this.address = 'Masaki, Dar es Salaam',
    this.notes = '',
    this.urgency = 'standard',
    this.paymentTiming = 'prepaid',
    this.isBusy = false,
    this.message,
    this.error,
  });

  final String query;
  final String category;
  final List<ExpressProduct> products;
  final String listText;
  final List<ExpressBasketItem> basket;
  final List<ExpressBasketItem> unknown;
  final ExpressBasketSuggestion? suggestion;
  final ExpressQuote? quote;
  final ExpressOrder? lastOrder;
  final List<ExpressOrder> orders;
  final String address;
  final String notes;
  final String urgency;
  final String paymentTiming;
  final bool isBusy;
  final String? message;
  final String? error;

  int get basketSubtotal =>
      basket.fold<int>(0, (s, i) => s + i.lineTotalMinor);

  ExpressUiState copyWith({
    String? query,
    String? category,
    List<ExpressProduct>? products,
    String? listText,
    List<ExpressBasketItem>? basket,
    List<ExpressBasketItem>? unknown,
    ExpressBasketSuggestion? suggestion,
    ExpressQuote? quote,
    ExpressOrder? lastOrder,
    List<ExpressOrder>? orders,
    String? address,
    String? notes,
    String? urgency,
    String? paymentTiming,
    bool? isBusy,
    String? message,
    String? error,
    bool clearError = false,
    bool clearSuggestion = false,
    bool clearQuote = false,
  }) {
    return ExpressUiState(
      query: query ?? this.query,
      category: category ?? this.category,
      products: products ?? this.products,
      listText: listText ?? this.listText,
      basket: basket ?? this.basket,
      unknown: unknown ?? this.unknown,
      suggestion: clearSuggestion ? null : (suggestion ?? this.suggestion),
      quote: clearQuote ? null : (quote ?? this.quote),
      lastOrder: lastOrder ?? this.lastOrder,
      orders: orders ?? this.orders,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      urgency: urgency ?? this.urgency,
      paymentTiming: paymentTiming ?? this.paymentTiming,
      isBusy: isBusy ?? this.isBusy,
      message: message ?? this.message,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ExpressController extends Notifier<ExpressUiState> {
  @override
  ExpressUiState build() => const ExpressUiState();

  ExpressRepository get _repo => ref.read(expressRepositoryProvider);

  static const templates = <String, String>{
    'Weekly groceries': 'Milk\nBread\nEggs\nRice\nSugar\nSoap\nCooking Oil\nTomatoes',
    'Breakfast': 'Milk\nBread\nEggs\nButter\nTea',
    'Cleaning': 'Soap\nDetergent\nSponge',
    'Baby': 'Diapers\nBaby wipes\nFormula',
  };

  static const quickChips = [
    'Milk',
    'Bread',
    'Eggs',
    'Rice',
    'Soap',
    'Cooking Oil',
    'Sugar',
    'Tomatoes',
  ];

  Future<void> loadCatalog({String query = '', String category = ''}) async {
    state = state.copyWith(
      isBusy: true,
      query: query,
      category: category,
      clearError: true,
    );
    try {
      final products = await _repo.searchProducts(query: query, category: category);
      state = state.copyWith(products: products, isBusy: false);
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> loadOrders() async {
    try {
      final orders = await _repo.listOrders();
      state = state.copyWith(orders: orders);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void setListText(String v) => state = state.copyWith(listText: v);

  void applyTemplate(String name) {
    final body = templates[name];
    if (body == null) return;
    state = state.copyWith(listText: body, message: '$name template');
  }

  void appendChip(String item) {
    final current = state.listText.trim();
    final next = current.isEmpty ? item : '$current\n$item';
    state = state.copyWith(listText: next);
  }

  void setAddress(String v) => state = state.copyWith(address: v);
  void setNotes(String v) => state = state.copyWith(notes: v);
  void setUrgency(String v) => state = state.copyWith(urgency: v);
  void setPaymentTiming(String v) => state = state.copyWith(paymentTiming: v);

  void setBasket(List<ExpressBasketItem> items) {
    state = state.copyWith(basket: items, clearQuote: true);
  }

  void updateBasketItem(int index, ExpressBasketItem item) {
    final next = List<ExpressBasketItem>.from(state.basket);
    if (index < 0 || index >= next.length) return;
    next[index] = item;
    state = state.copyWith(basket: next, clearQuote: true);
  }

  void removeBasketItem(int index) {
    final next = List<ExpressBasketItem>.from(state.basket)..removeAt(index);
    state = state.copyWith(basket: next, clearQuote: true);
  }

  void clearBasket() =>
      state = state.copyWith(basket: const [], unknown: const [], clearQuote: true);

  void addToBasket(ExpressProduct product, {int qty = 1}) {
    final next = List<ExpressBasketItem>.from(state.basket);
    final idx = next.indexWhere((e) => e.name == product.name);
    if (idx >= 0) {
      next[idx] = next[idx].copyWith(qty: next[idx].qty + qty);
    } else {
      next.add(
        ExpressBasketItem(
          name: product.name,
          qty: qty,
          sku: product.sku,
          productId: product.id,
          priceMinor: product.priceMinor,
          storeName: product.storeName,
        ),
      );
    }
    state = state.copyWith(basket: next, message: '${product.name} added', clearQuote: true);
  }

  Future<bool> parseListToBasket() async {
    final text = state.listText.trim();
    if (text.isEmpty) {
      state = state.copyWith(error: 'Write at least one item');
      return false;
    }
    state = state.copyWith(isBusy: true, clearError: true, message: 'Matching inventory…');
    try {
      final parsed = await _repo.parseShoppingList(text: text);
      state = state.copyWith(
        basket: parsed.matched,
        unknown: parsed.unknown,
        isBusy: false,
        message: parsed.preferredStoreName.isEmpty
            ? '${parsed.matched.length} items matched'
            : '${parsed.matched.length} items · ${parsed.preferredStoreName}',
        clearQuote: true,
      );
      return parsed.matched.isNotEmpty;
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
      return false;
    }
  }

  Future<void> askAi(String prompt) async {
    if (prompt.trim().isEmpty) return;
    state = state.copyWith(isBusy: true, clearError: true, message: 'Building basket…');
    try {
      final suggestion = await _repo.aiBasket(prompt);
      state = state.copyWith(
        suggestion: suggestion,
        basket: suggestion.items,
        isBusy: false,
        message: 'Review AI basket — then CHECKOUT',
        clearQuote: true,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> refreshQuote() async {
    if (state.basket.isEmpty) return;
    try {
      final quote = await _repo.quote(
        items: state.basket,
        lat: -6.75,
        lng: 39.28,
        urgency: state.urgency,
      );
      state = state.copyWith(quote: quote);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<ExpressOrder?> checkout({bool autoReady = true}) async {
    if (state.basket.isEmpty) {
      state = state.copyWith(error: 'Add items first');
      return null;
    }
    state = state.copyWith(
      isBusy: true,
      clearError: true,
      message: 'Orchestrating merchants & delivery…',
    );
    try {
      final order = await _repo.checkout(
        items: state.basket,
        lat: -6.75,
        lng: 39.28,
        address: state.address,
        notes: state.notes,
        urgency: state.urgency,
        aiPrompt: '',
        paymentTiming: state.paymentTiming,
        paymentMethod: 'wallet',
        autoReady: autoReady,
      );
      state = state.copyWith(
        lastOrder: order,
        basket: const [],
        listText: '',
        isBusy: false,
        message: 'Order ${order.publicCode}',
        clearSuggestion: true,
        clearQuote: true,
      );
      await loadOrders();
      return order;
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
      return null;
    }
  }

  Future<void> markReady(String orderId) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final order = await _repo.merchantReady(orderId);
      state = state.copyWith(lastOrder: order, isBusy: false, message: 'Rider dispatched');
      await loadOrders();
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<ExpressOrder?> refreshOrder(String orderId) async {
    try {
      final order = await _repo.getOrder(orderId);
      state = state.copyWith(lastOrder: order);
      return order;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }
}

final expressControllerProvider =
    NotifierProvider<ExpressController, ExpressUiState>(ExpressController.new);

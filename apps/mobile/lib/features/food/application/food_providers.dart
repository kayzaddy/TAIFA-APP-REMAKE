import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/food/rest_food_order_repository.dart';
import '../../wallet/application/wallet_providers.dart'
    show apiClientProvider, apiConfigProvider;
import '../../wallet/domain/currency.dart';
import '../../wallet/domain/money.dart';
import '../domain/food_models.dart';
import 'food_repository.dart';
import 'seed_food_repository.dart';

final restaurantRepositoryProvider = Provider<RestaurantRepository>(
  (ref) => SeedRestaurantRepository(),
);

/// Seed offline, or live commerce API when `TAIFA_USE_REMOTE=true`.
final foodOrderRepositoryProvider = Provider<FoodOrderRepository>((ref) {
  final config = ref.watch(apiConfigProvider);
  if (config.useRemoteBackend) {
    return RestFoodOrderRepository(ref.watch(apiClientProvider));
  }
  return SeedFoodOrderRepository();
});

enum FoodPhase {
  home,
  menu,
  cart,
  checkout,
  tracking,
  delivered,
  receipt,
  history,
}

class FoodUiState {
  const FoodUiState({
    this.phase = FoodPhase.home,
    this.restaurants = const [],
    this.query = '',
    this.selected,
    this.cart = const [],
    this.order,
    this.history = const [],
    this.isBusy = false,
    this.error,
  });

  final FoodPhase phase;
  final List<Restaurant> restaurants;
  final String query;
  final Restaurant? selected;
  final List<CartLine> cart;
  final FoodOrder? order;
  final List<FoodOrder> history;
  final bool isBusy;
  final String? error;

  Money get subtotal {
    var total = Money.zero(Currency.tzs);
    for (final line in cart) {
      total = total + line.lineTotal;
    }
    return total;
  }

  Money get deliveryFee => selected?.deliveryFee ?? Money.zero(Currency.tzs);

  Money get total => subtotal + deliveryFee;

  int get cartCount => cart.fold(0, (a, l) => a + l.quantity);

  FoodUiState copyWith({
    FoodPhase? phase,
    List<Restaurant>? restaurants,
    String? query,
    Restaurant? selected,
    List<CartLine>? cart,
    FoodOrder? order,
    List<FoodOrder>? history,
    bool? isBusy,
    String? error,
    bool clearError = false,
    bool clearOrder = false,
    bool clearSelected = false,
  }) {
    return FoodUiState(
      phase: phase ?? this.phase,
      restaurants: restaurants ?? this.restaurants,
      query: query ?? this.query,
      selected: clearSelected ? null : (selected ?? this.selected),
      cart: cart ?? this.cart,
      order: clearOrder ? null : (order ?? this.order),
      history: history ?? this.history,
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class FoodController extends Notifier<FoodUiState> {
  Timer? _lifecycle;

  RestaurantRepository get _restaurants =>
      ref.read(restaurantRepositoryProvider);
  FoodOrderRepository get _orders => ref.read(foodOrderRepositoryProvider);

  @override
  FoodUiState build() {
    ref.onDispose(() => _lifecycle?.cancel());
    return const FoodUiState();
  }

  Future<void> bootstrap() async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final list = await _restaurants.list();
      final history = await _orders.history();
      state = state.copyWith(
        restaurants: list,
        history: history,
        isBusy: false,
        phase: FoodPhase.home,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> search(String query) async {
    state = state.copyWith(query: query, isBusy: true, clearError: true);
    final list = await _restaurants.list(query: query);
    state = state.copyWith(restaurants: list, isBusy: false);
  }

  void openRestaurant(Restaurant restaurant) {
    state = state.copyWith(
      selected: restaurant,
      phase: FoodPhase.menu,
      cart: const [],
      clearError: true,
      clearOrder: true,
    );
  }

  void backToHome() {
    _lifecycle?.cancel();
    state = state.copyWith(
      phase: FoodPhase.home,
      clearSelected: true,
      cart: const [],
      clearOrder: true,
      clearError: true,
    );
  }

  void openCart() {
    if (state.cart.isEmpty) {
      state = state.copyWith(error: 'Add something delicious first.');
      return;
    }
    state = state.copyWith(phase: FoodPhase.cart, clearError: true);
  }

  void backToMenu() {
    if (state.selected == null) {
      backToHome();
      return;
    }
    state = state.copyWith(phase: FoodPhase.menu, clearError: true);
  }

  void openHistory() {
    state = state.copyWith(phase: FoodPhase.history, clearError: true);
  }

  void addItem(MenuItem item) {
    final lines = [...state.cart];
    final idx = lines.indexWhere((l) => l.item.id == item.id);
    if (idx >= 0) {
      lines[idx] = lines[idx].copyWith(quantity: lines[idx].quantity + 1);
    } else {
      lines.add(CartLine(item: item, quantity: 1));
    }
    state = state.copyWith(cart: lines, clearError: true);
  }

  void setQuantity(String itemId, int quantity) {
    if (quantity <= 0) {
      state = state.copyWith(
        cart: state.cart.where((l) => l.item.id != itemId).toList(),
      );
      return;
    }
    state = state.copyWith(
      cart: [
        for (final l in state.cart)
          if (l.item.id == itemId) l.copyWith(quantity: quantity) else l,
      ],
    );
  }

  void goCheckout() {
    if (state.cart.isEmpty || state.selected == null) return;
    state = state.copyWith(phase: FoodPhase.checkout, clearError: true);
  }

  Future<void> placeOrder() async {
    final restaurant = state.selected;
    if (restaurant == null || state.cart.isEmpty) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final draft = FoodOrder(
        id: 'draft',
        restaurant: restaurant,
        lines: state.cart,
        subtotal: state.subtotal,
        deliveryFee: state.deliveryFee,
        total: state.total,
        status: FoodOrderStatus.placing,
        createdAt: DateTime.now(),
      );
      final placed = await _orders.place(draft);
      state = state.copyWith(
        order: placed,
        isBusy: false,
        phase: FoodPhase.tracking,
        cart: const [],
      );
      _simulateLifecycle(placed);
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  void _simulateLifecycle(FoodOrder start) {
    _lifecycle?.cancel();
    final steps = <(FoodOrderStatus, int, double)>[
      (FoodOrderStatus.preparing, 1200, 0.25),
      (FoodOrderStatus.pickingUp, 1400, 0.45),
      (FoodOrderStatus.onTheWay, 1800, 0.7),
      (FoodOrderStatus.delivered, 1600, 1.0),
    ];
    var i = 0;
    Future<void> tick() async {
      if (!ref.mounted || i >= steps.length) return;
      final step = steps[i++];
      await Future<void>.delayed(Duration(milliseconds: step.$2));
      if (!ref.mounted) return;
      final current = state.order;
      if (current == null) return;
      final next = await _orders.update(
        current.copyWith(
          status: step.$1,
          progress: step.$3,
          etaMinutes: (current.etaMinutes ?? 25) - 5,
        ),
      );
      state = state.copyWith(
        order: next,
        phase: step.$1 == FoodOrderStatus.delivered
            ? FoodPhase.delivered
            : FoodPhase.tracking,
      );
      if (step.$1 != FoodOrderStatus.delivered) {
        unawaited(tick());
      }
    }

    unawaited(tick());
  }

  Future<void> confirmPayment() async {
    final order = state.order;
    if (order == null) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final paid = await _orders.pay(order.id);
      final history = await _orders.history();
      state = state.copyWith(
        order: paid,
        history: history,
        isBusy: false,
        phase: FoodPhase.receipt,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }
}

final foodControllerProvider = NotifierProvider<FoodController, FoodUiState>(
  FoodController.new,
);

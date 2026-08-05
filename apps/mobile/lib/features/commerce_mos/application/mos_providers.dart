import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/commerce_mos/rest_mos_repository.dart';
import '../../wallet/application/wallet_providers.dart'
    show apiClientProvider, apiConfigProvider;
import '../domain/mos_models.dart';
import 'mos_repository.dart';
import 'seed_mos_repository.dart';

final mosRepositoryProvider = Provider<MosRepository>((ref) {
  final config = ref.watch(apiConfigProvider);
  if (config.useRemoteBackend) {
    return RestMosRepository(ref.watch(apiClientProvider));
  }
  return SeedMosRepository();
});

class MosUiState {
  const MosUiState({
    this.products = const [],
    this.orders = const [],
    this.suppliers = const [],
    this.purchaseOrders = const [],
    this.customers = const [],
    this.analytics = const MosAnalytics(),
    this.cart = const [],
    this.posSession,
    this.assistTips = const [],
    this.query = '',
    this.isBusy = false,
    this.offlineHint = false,
    this.error,
    this.onboardingComplete = false,
  });

  final List<MosProduct> products;
  final List<MosOrder> orders;
  final List<MosSupplier> suppliers;
  final List<MosPurchaseOrder> purchaseOrders;
  final List<MosCustomer> customers;
  final MosAnalytics analytics;
  final List<MosCartLine> cart;
  final MosPosSession? posSession;
  final List<String> assistTips;
  final String query;
  final bool isBusy;
  final bool offlineHint;
  final String? error;
  final bool onboardingComplete;

  int get cartTotalMinor =>
      cart.fold<int>(0, (a, c) => a + c.lineTotalMinor);

  List<MosProduct> get lowStockProducts =>
      products.where((p) => p.isLowStock || p.isOutOfStock).toList();

  List<MosOrder> get unpaidOrders =>
      orders.where((o) => !o.paid && o.status != 'cancelled').toList();

  MosUiState copyWith({
    List<MosProduct>? products,
    List<MosOrder>? orders,
    List<MosSupplier>? suppliers,
    List<MosPurchaseOrder>? purchaseOrders,
    List<MosCustomer>? customers,
    MosAnalytics? analytics,
    List<MosCartLine>? cart,
    MosPosSession? posSession,
    List<String>? assistTips,
    String? query,
    bool? isBusy,
    bool? offlineHint,
    String? error,
    bool? onboardingComplete,
    bool clearError = false,
  }) =>
      MosUiState(
        products: products ?? this.products,
        orders: orders ?? this.orders,
        suppliers: suppliers ?? this.suppliers,
        purchaseOrders: purchaseOrders ?? this.purchaseOrders,
        customers: customers ?? this.customers,
        analytics: analytics ?? this.analytics,
        cart: cart ?? this.cart,
        posSession: posSession ?? this.posSession,
        assistTips: assistTips ?? this.assistTips,
        query: query ?? this.query,
        isBusy: isBusy ?? this.isBusy,
        offlineHint: offlineHint ?? this.offlineHint,
        error: clearError ? null : (error ?? this.error),
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      );
}

class MosController extends Notifier<MosUiState> {
  @override
  MosUiState build() => const MosUiState();

  MosRepository get _repo => ref.read(mosRepositoryProvider);

  Future<void> bootstrap() async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final analytics = await _repo.bootstrap();
      final products = await _repo.products();
      final orders = await _repo.orders();
      final suppliers = await _repo.suppliers();
      final pos = await _repo.purchaseOrders();
      final customers = await _repo.customers();
      state = state.copyWith(
        analytics: analytics,
        products: products,
        orders: orders,
        suppliers: suppliers,
        purchaseOrders: pos,
        customers: customers,
        isBusy: false,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString(), offlineHint: true);
    }
  }

  Future<void> search(String query) async {
    state = state.copyWith(query: query, isBusy: true);
    try {
      final products = await _repo.products(query: query);
      state = state.copyWith(products: products, isBusy: false);
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  void addToCart(MosProduct product) {
    final existing = state.cart.where((c) => c.product.id == product.id).toList();
    if (existing.isEmpty) {
      state = state.copyWith(cart: [...state.cart, MosCartLine(product: product, quantity: 1)]);
      return;
    }
    state = state.copyWith(
      cart: [
        for (final c in state.cart)
          if (c.product.id == product.id)
            MosCartLine(product: c.product, quantity: c.quantity + 1)
          else
            c,
      ],
    );
  }

  void clearCart() => state = state.copyWith(cart: const []);

  Future<MosOrder?> checkoutCart() async {
    if (state.cart.isEmpty) return null;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final order = await _repo.createOrder(
        lines: [
          for (final c in state.cart)
            (productId: c.product.id, quantity: c.quantity),
        ],
        channel: 'pos',
      );
      final paid = await _repo.payOrder(
        order.id,
        idempotencyKey: 'mos-pos-${order.id}-${DateTime.now().millisecondsSinceEpoch}',
      );
      final products = await _repo.products(query: state.query);
      final orders = await _repo.orders();
      final analytics = await _repo.analytics();
      state = state.copyWith(
        cart: const [],
        products: products,
        orders: orders,
        analytics: analytics,
        isBusy: false,
      );
      return paid;
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
      return null;
    }
  }

  Future<void> fulfill(String orderId) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      await _repo.fulfillOrder(orderId);
      state = state.copyWith(
        orders: await _repo.orders(),
        products: await _repo.products(query: state.query),
        analytics: await _repo.analytics(),
        isBusy: false,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> receiveStock(String productId, num qty) async {
    await _repo.adjustStock(productId: productId, kind: 'receive', quantity: qty);
    state = state.copyWith(products: await _repo.products(query: state.query));
  }

  Future<void> openPos() async {
    final s = await _repo.openPosSession();
    state = state.copyWith(posSession: s);
  }

  Future<void> closePos({int closingCashMinor = 0}) async {
    final id = state.posSession?.id;
    if (id == null) return;
    final s = await _repo.closePosSession(id, closingCashMinor: closingCashMinor);
    state = state.copyWith(posSession: s);
  }

  Future<void> runAssist(String capability) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final tips = await _repo.assist(capability);
      state = state.copyWith(assistTips: tips, isBusy: false);
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString(), assistTips: const []);
    }
  }

  Future<void> publishWinga(String productId) async {
    await _repo.publishToWinga(productId);
  }

  void completeOnboarding() =>
      state = state.copyWith(onboardingComplete: true);
}

final mosControllerProvider =
    NotifierProvider<MosController, MosUiState>(MosController.new);

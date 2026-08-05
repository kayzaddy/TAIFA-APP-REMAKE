import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/winga/rest_winga_repository.dart';
import '../../wallet/application/wallet_providers.dart';
import '../../wallet/application/wallet_repository.dart';
import '../../wallet/domain/currency.dart';
import '../../wallet/domain/money.dart';
import '../../wallet/domain/payment_method.dart';
import '../../wallet/domain/recipient.dart';
import '../domain/winga_models.dart';
import '../gateways/winga_gateways.dart';
import 'winga_repository.dart';

/// Seed offline, or live WINGA commerce writes when `TAIFA_USE_REMOTE=true`.
final wingaRepositoryProvider = Provider<WingaRepository>((ref) {
  final config = ref.watch(apiConfigProvider);
  if (config.useRemoteBackend) {
    return RestWingaRepository(ref.watch(apiClientProvider));
  }
  return SeedWingaRepository();
});

final wingaAiGatewayProvider = Provider<WingaAiGateway>(
  (ref) => MockWingaAiGateway(),
);

final wingaDeliveryGatewayProvider = Provider<WingaDeliveryGateway>(
  (ref) => MockWingaDeliveryGateway(),
);

enum WingaPhase {
  home,
  marketplace,
  productDetail,
  cart,
  checkout,
  orderConfirm,
  tracking,
  services,
  serviceDetail,
  serviceBook,
  serviceDone,
  openShop,
  merchant,
  merchantOrders,
  merchantAi,
  aiShop,
  negotia,
  wishlist,
}

class WingaUiState {
  const WingaUiState({
    this.phase = WingaPhase.home,
    this.stores = const [],
    this.products = const [],
    this.catalogProducts = const [],
    this.services = const [],
    this.query = '',
    this.categoryFilter,
    this.selectedProduct,
    this.selectedService,
    this.cart = const [],
    this.wishlistIds = const {},
    this.recentIds = const [],
    this.order,
    this.serviceBooking,
    this.shopDraft = const WingaShopDraft(),
    this.merchantStats,
    this.merchantOrders = const [],
    this.aiMessages = const [],
    this.negotiaQuotes = const [],
    this.serviceSlot = 'Today · 3–5 pm',
    this.isBusy = false,
    this.error,
  });

  final WingaPhase phase;
  final List<WingaStore> stores;
  final List<WingaProduct> products;
  final List<WingaProduct> catalogProducts;
  final List<WingaServiceOffer> services;
  final String query;
  final String? categoryFilter;
  final WingaProduct? selectedProduct;
  final WingaServiceOffer? selectedService;
  final List<WingaCartLine> cart;
  final Set<String> wishlistIds;
  final List<String> recentIds;
  final WingaOrder? order;
  final WingaServiceBooking? serviceBooking;
  final WingaShopDraft shopDraft;
  final WingaMerchantStats? merchantStats;
  final List<WingaMerchantOrder> merchantOrders;
  final List<WingaAiMessage> aiMessages;
  final List<NegotiaQuote> negotiaQuotes;
  final String serviceSlot;
  final bool isBusy;
  final String? error;

  Money get cartTotal {
    var t = Money.zero(Currency.tzs);
    for (final l in cart) {
      t = t + l.lineTotal;
    }
    return t;
  }

  int get cartCount => cart.fold(0, (a, l) => a + l.quantity);

  List<WingaProduct> get deals =>
      catalogProducts.where((p) => p.badge == "Today's Deal").toList();

  List<WingaProduct> get trending =>
      catalogProducts.where((p) => p.badge == 'Trending').toList();

  List<WingaProduct> get recommended => catalogProducts
      .where((p) => p.badge == 'Recommended' || p.rating >= 4.7)
      .toList();

  List<WingaProduct> get recentlyViewed {
    final byId = {for (final p in catalogProducts) p.id: p};
    return recentIds.map((id) => byId[id]).whereType<WingaProduct>().toList();
  }

  List<WingaProduct> get wishlist =>
      catalogProducts.where((p) => wishlistIds.contains(p.id)).toList();

  WingaUiState copyWith({
    WingaPhase? phase,
    List<WingaStore>? stores,
    List<WingaProduct>? products,
    List<WingaProduct>? catalogProducts,
    List<WingaServiceOffer>? services,
    String? query,
    String? categoryFilter,
    WingaProduct? selectedProduct,
    WingaServiceOffer? selectedService,
    List<WingaCartLine>? cart,
    Set<String>? wishlistIds,
    List<String>? recentIds,
    WingaOrder? order,
    WingaServiceBooking? serviceBooking,
    WingaShopDraft? shopDraft,
    WingaMerchantStats? merchantStats,
    List<WingaMerchantOrder>? merchantOrders,
    List<WingaAiMessage>? aiMessages,
    List<NegotiaQuote>? negotiaQuotes,
    String? serviceSlot,
    bool? isBusy,
    String? error,
    bool clearCategory = false,
    bool clearProduct = false,
    bool clearService = false,
    bool clearOrder = false,
    bool clearError = false,
  }) {
    return WingaUiState(
      phase: phase ?? this.phase,
      stores: stores ?? this.stores,
      products: products ?? this.products,
      catalogProducts: catalogProducts ?? this.catalogProducts,
      services: services ?? this.services,
      query: query ?? this.query,
      categoryFilter: clearCategory
          ? null
          : (categoryFilter ?? this.categoryFilter),
      selectedProduct: clearProduct
          ? null
          : (selectedProduct ?? this.selectedProduct),
      selectedService: clearService
          ? null
          : (selectedService ?? this.selectedService),
      cart: cart ?? this.cart,
      wishlistIds: wishlistIds ?? this.wishlistIds,
      recentIds: recentIds ?? this.recentIds,
      order: clearOrder ? null : (order ?? this.order),
      serviceBooking: serviceBooking ?? this.serviceBooking,
      shopDraft: shopDraft ?? this.shopDraft,
      merchantStats: merchantStats ?? this.merchantStats,
      merchantOrders: merchantOrders ?? this.merchantOrders,
      aiMessages: aiMessages ?? this.aiMessages,
      negotiaQuotes: negotiaQuotes ?? this.negotiaQuotes,
      serviceSlot: serviceSlot ?? this.serviceSlot,
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class WingaController extends Notifier<WingaUiState> {
  Timer? _trackTimer;

  WingaRepository get _repo => ref.read(wingaRepositoryProvider);
  WingaAiGateway get _ai => ref.read(wingaAiGatewayProvider);
  WingaDeliveryGateway get _delivery => ref.read(wingaDeliveryGatewayProvider);
  WalletRepository get _wallet => ref.read(walletRepositoryProvider);

  @override
  WingaUiState build() {
    ref.onDispose(() => _trackTimer?.cancel());
    return const WingaUiState();
  }

  Future<void> bootstrap() async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final stores = await _repo.stores();
      final products = await _repo.products();
      final services = await _repo.services();
      state = state.copyWith(
        stores: stores,
        products: products,
        catalogProducts: products,
        services: services,
        isBusy: false,
        phase: WingaPhase.home,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  void goHome() => state = state.copyWith(
    phase: WingaPhase.home,
    clearProduct: true,
    clearService: true,
    clearError: true,
  );

  void openMarketplace({String? category}) {
    state = state.copyWith(
      phase: WingaPhase.marketplace,
      categoryFilter: category,
      clearCategory: category == null,
      clearError: true,
    );
    unawaited(_refreshProducts());
  }

  void setQuery(String q) {
    state = state.copyWith(query: q);
    unawaited(_refreshProducts());
  }

  Future<void> _refreshProducts() async {
    final list = await _repo.products(
      category: state.categoryFilter,
      query: state.query,
    );
    if (!ref.mounted) return;
    state = state.copyWith(products: list);
  }

  void openProduct(WingaProduct p) {
    final recent = [
      p.id,
      ...state.recentIds.where((id) => id != p.id),
    ].take(8).toList();
    state = state.copyWith(
      selectedProduct: p,
      recentIds: recent,
      phase: WingaPhase.productDetail,
    );
  }

  void toggleWishlist(String productId) {
    final next = {...state.wishlistIds};
    if (!next.add(productId)) next.remove(productId);
    state = state.copyWith(wishlistIds: next);
  }

  void openWishlist() => state = state.copyWith(phase: WingaPhase.wishlist);

  void addToCart(WingaProduct p, {int qty = 1}) {
    final cart = [...state.cart];
    final i = cart.indexWhere((l) => l.product.id == p.id);
    if (i >= 0) {
      cart[i] = cart[i].copyWith(quantity: cart[i].quantity + qty);
    } else {
      cart.add(WingaCartLine(product: p, quantity: qty));
    }
    state = state.copyWith(cart: cart, phase: WingaPhase.cart);
  }

  void openCart() => state = state.copyWith(phase: WingaPhase.cart);

  void setQty(String productId, int qty) {
    if (qty <= 0) {
      state = state.copyWith(
        cart: state.cart.where((l) => l.product.id != productId).toList(),
      );
      return;
    }
    state = state.copyWith(
      cart: state.cart
          .map((l) => l.product.id == productId ? l.copyWith(quantity: qty) : l)
          .toList(),
    );
  }

  void goCheckout() {
    if (state.cart.isEmpty) return;
    state = state.copyWith(phase: WingaPhase.checkout);
  }

  Future<void> payWithWallet() async {
    if (state.cart.isEmpty) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final total = state.cartTotal;
      final receipt = await _wallet.transfer(
        TransferCommand(
          recipient: const Recipient(
            id: 'winga-commerce',
            name: 'WINGA Commerce',
            handle: '@winga',
            method: TaifaWalletMethod(
              id: 'tw-winga',
              label: 'TAIFA Wallet',
              maskedNumber: '•••• 8841',
            ),
            verified: true,
          ),
          amount: total,
          fee: Money.zero(Currency.tzs),
          idempotencyKey: 'winga-${DateTime.now().millisecondsSinceEpoch}',
          note: 'WINGA marketplace order',
        ),
      );
      final draft = WingaOrder(
        id: 'draft',
        lines: state.cart,
        total: total,
        status: WingaOrderStatus.placed,
        createdAt: DateTime.now(),
        paymentRef: receipt.transaction.id,
      );
      var order = await _repo.placeOrder(draft);
      order = await _delivery.dispatch(order);
      state = state.copyWith(
        order: order,
        cart: const [],
        isBusy: false,
        phase: WingaOrderStatus.driverAssigned == order.status
            ? WingaPhase.orderConfirm
            : WingaPhase.orderConfirm,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  void startTracking() {
    state = state.copyWith(phase: WingaPhase.tracking);
    _trackTimer?.cancel();
    _trackTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      final o = state.order;
      if (o == null || o.status == WingaOrderStatus.completed) {
        _trackTimer?.cancel();
        return;
      }
      final next = await _delivery.advance(o);
      state = state.copyWith(order: next);
      if (next.status == WingaOrderStatus.completed) _trackTimer?.cancel();
    });
  }

  void openServices({String? category}) async {
    state = state.copyWith(isBusy: true, phase: WingaPhase.services);
    final list = await _repo.services(category: category);
    state = state.copyWith(services: list, isBusy: false);
  }

  void openService(WingaServiceOffer s) => state = state.copyWith(
    selectedService: s,
    phase: WingaPhase.serviceDetail,
  );

  void goServiceBook() => state = state.copyWith(phase: WingaPhase.serviceBook);

  void setServiceSlot(String slot) => state = state.copyWith(serviceSlot: slot);

  Future<void> payService() async {
    final s = state.selectedService;
    if (s == null) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final receipt = await _wallet.transfer(
        TransferCommand(
          recipient: Recipient(
            id: 'winga-svc-${s.id}',
            name: s.provider,
            handle: '@winga-services',
            method: const TaifaWalletMethod(
              id: 'tw-winga',
              label: 'TAIFA Wallet',
              maskedNumber: '•••• 8841',
            ),
            verified: true,
          ),
          amount: s.priceFrom,
          fee: Money.zero(Currency.tzs),
          idempotencyKey: 'winga-svc-${DateTime.now().millisecondsSinceEpoch}',
          note: 'WINGA service · ${s.title}',
        ),
      );
      final booking = await _repo.bookService(
        WingaServiceBooking(
          id: 'draft',
          service: s,
          slotLabel: state.serviceSlot,
          total: s.priceFrom,
          createdAt: DateTime.now(),
          paymentRef: receipt.transaction.id,
        ),
      );
      state = state.copyWith(
        serviceBooking: booking,
        isBusy: false,
        phase: WingaPhase.serviceDone,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  void openShopFlow() => state = state.copyWith(
    phase: WingaPhase.openShop,
    shopDraft: const WingaShopDraft(name: 'My TAIFA Shop'),
  );

  void updateShopDraft({String? name, String? category, String? address}) {
    state = state.copyWith(
      shopDraft: state.shopDraft.copyWith(
        name: name,
        category: category,
        address: address,
      ),
    );
  }

  Future<void> submitShop() async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final shop = await _repo.submitShop(state.shopDraft);
      final stats = await _repo.merchantStats();
      final orders = await _repo.merchantOrders();
      state = state.copyWith(
        shopDraft: shop,
        merchantStats: stats,
        merchantOrders: orders,
        isBusy: false,
        phase: WingaPhase.merchant,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> openMerchant() async {
    state = state.copyWith(isBusy: true, phase: WingaPhase.merchant);
    final stats = await _repo.merchantStats();
    final orders = await _repo.merchantOrders();
    state = state.copyWith(
      merchantStats: stats,
      merchantOrders: orders,
      isBusy: false,
    );
  }

  void openMerchantOrders() =>
      state = state.copyWith(phase: WingaPhase.merchantOrders);

  void openMerchantAi() => state = state.copyWith(
    phase: WingaPhase.merchantAi,
    aiMessages: const [],
  );

  void openAiShop() =>
      state = state.copyWith(phase: WingaPhase.aiShop, aiMessages: const []);

  void openNegotia() => state = state.copyWith(
    phase: WingaPhase.negotia,
    aiMessages: const [],
    negotiaQuotes: const [],
  );

  Future<void> sendAiShop(String text) async {
    if (text.trim().isEmpty) return;
    final user = WingaAiMessage(
      id: 'u-${DateTime.now().millisecondsSinceEpoch}',
      isUser: true,
      text: text.trim(),
      at: DateTime.now(),
    );
    state = state.copyWith(
      aiMessages: [...state.aiMessages, user],
      isBusy: true,
    );
    final reply = await _ai.shopAssist(text);
    state = state.copyWith(
      isBusy: false,
      aiMessages: [
        ...state.aiMessages,
        WingaAiMessage(
          id: 'a-${DateTime.now().millisecondsSinceEpoch}',
          isUser: false,
          text: reply,
          at: DateTime.now(),
        ),
      ],
    );
  }

  Future<void> runNegotia(String text) async {
    if (text.trim().isEmpty) return;
    final user = WingaAiMessage(
      id: 'u-${DateTime.now().millisecondsSinceEpoch}',
      isUser: true,
      text: text.trim(),
      at: DateTime.now(),
    );
    state = state.copyWith(
      aiMessages: [...state.aiMessages, user],
      isBusy: true,
    );
    final quotes = await _ai.negotiate(text);
    final summary = StringBuffer('NEGOTIA found ${quotes.length} suppliers.\n');
    for (final q in quotes) {
      summary.writeln(
        '• ${q.supplier}: ${q.unitPrice.format()}/bag × ${q.qty} + transport ${q.transport.format()} '
        '= ${q.grandTotal.format()} (${q.scoreLabel}${q.negotiated ? ', negotiated' : ''})',
      );
    }
    summary.write('Recommended: ${quotes.first.supplier}.');
    state = state.copyWith(
      isBusy: false,
      negotiaQuotes: quotes,
      aiMessages: [
        ...state.aiMessages,
        WingaAiMessage(
          id: 'a-${DateTime.now().millisecondsSinceEpoch}',
          isUser: false,
          text: summary.toString(),
          at: DateTime.now(),
        ),
      ],
    );
  }

  Future<void> sendBusinessAi(String text) async {
    if (text.trim().isEmpty) return;
    final user = WingaAiMessage(
      id: 'u-${DateTime.now().millisecondsSinceEpoch}',
      isUser: true,
      text: text.trim(),
      at: DateTime.now(),
    );
    state = state.copyWith(
      aiMessages: [...state.aiMessages, user],
      isBusy: true,
    );
    final reply = await _ai.businessAssist(text);
    state = state.copyWith(
      isBusy: false,
      aiMessages: [
        ...state.aiMessages,
        WingaAiMessage(
          id: 'a-${DateTime.now().millisecondsSinceEpoch}',
          isUser: false,
          text: reply,
          at: DateTime.now(),
        ),
      ],
    );
  }

  void back() {
    switch (state.phase) {
      case WingaPhase.home:
        break;
      case WingaPhase.productDetail:
        state = state.copyWith(
          phase: WingaPhase.marketplace,
          clearProduct: true,
        );
      case WingaPhase.cart:
      case WingaPhase.marketplace:
      case WingaPhase.services:
      case WingaPhase.openShop:
      case WingaPhase.merchant:
      case WingaPhase.aiShop:
      case WingaPhase.negotia:
      case WingaPhase.wishlist:
        goHome();
      case WingaPhase.checkout:
        openCart();
      case WingaPhase.orderConfirm:
      case WingaPhase.tracking:
        goHome();
      case WingaPhase.serviceDetail:
        openServices();
      case WingaPhase.serviceBook:
        if (state.selectedService != null) openService(state.selectedService!);
      case WingaPhase.serviceDone:
        goHome();
      case WingaPhase.merchantOrders:
      case WingaPhase.merchantAi:
        openMerchant();
    }
  }
}

final wingaControllerProvider = NotifierProvider<WingaController, WingaUiState>(
  WingaController.new,
);

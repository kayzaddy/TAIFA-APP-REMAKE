import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../../../app/theme/taifa_theme.dart';
import '../../../app/theme/taifa_typography.dart';
import '../../../shared/widgets/taifa_logo.dart';
import '../application/winga_providers.dart';
import '../data/winga_catalog.dart';
import '../domain/winga_models.dart';

class WingaScreen extends ConsumerStatefulWidget {
  const WingaScreen({super.key});

  @override
  ConsumerState<WingaScreen> createState() => _WingaScreenState();
}

class _WingaScreenState extends ConsumerState<WingaScreen> {
  final _search = TextEditingController();
  final _ai = TextEditingController();
  final _shopName = TextEditingController(text: 'My TAIFA Shop');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(wingaControllerProvider.notifier).bootstrap();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    _ai.dispose();
    _shopName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wingaControllerProvider);
    final ctrl = ref.read(wingaControllerProvider.notifier);
    final palette = context.taifa;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              state: state,
              ctrl: ctrl,
              onLeave: () {
                if (state.phase == WingaPhase.home) {
                  context.canPop() ? context.pop() : context.go('/home');
                } else {
                  ctrl.back();
                }
              },
            ),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  state.error!,
                  style: const TextStyle(
                    color: TaifaColors.danger,
                    fontSize: 12,
                  ),
                ),
              ),
            Expanded(
              child: AnimatedSwitcher(
                duration: TaifaMotion.base,
                child: switch (state.phase) {
                  WingaPhase.home => _Home(
                    key: const ValueKey('h'),
                    state: state,
                    ctrl: ctrl,
                  ),
                  WingaPhase.marketplace => _Marketplace(
                    key: const ValueKey('m'),
                    state: state,
                    ctrl: ctrl,
                    search: _search,
                  ),
                  WingaPhase.productDetail => _ProductDetail(
                    key: const ValueKey('pd'),
                    state: state,
                    ctrl: ctrl,
                  ),
                  WingaPhase.cart => _Cart(
                    key: const ValueKey('c'),
                    state: state,
                    ctrl: ctrl,
                  ),
                  WingaPhase.checkout => _Checkout(
                    key: const ValueKey('ck'),
                    state: state,
                    ctrl: ctrl,
                  ),
                  WingaPhase.orderConfirm => _OrderConfirm(
                    key: const ValueKey('oc'),
                    state: state,
                    ctrl: ctrl,
                  ),
                  WingaPhase.tracking => _Tracking(
                    key: const ValueKey('tr'),
                    state: state,
                  ),
                  WingaPhase.services => _Services(
                    key: const ValueKey('sv'),
                    state: state,
                    ctrl: ctrl,
                  ),
                  WingaPhase.serviceDetail => _ServiceDetail(
                    key: const ValueKey('sd'),
                    state: state,
                    ctrl: ctrl,
                  ),
                  WingaPhase.serviceBook => _ServiceBook(
                    key: const ValueKey('sb'),
                    state: state,
                    ctrl: ctrl,
                  ),
                  WingaPhase.serviceDone => _ServiceDone(
                    key: const ValueKey('sdone'),
                    state: state,
                  ),
                  WingaPhase.openShop => _OpenShop(
                    key: const ValueKey('os'),
                    state: state,
                    ctrl: ctrl,
                    nameCtrl: _shopName,
                  ),
                  WingaPhase.merchant => _Merchant(
                    key: const ValueKey('md'),
                    state: state,
                    ctrl: ctrl,
                  ),
                  WingaPhase.merchantOrders => _MerchantOrders(
                    key: const ValueKey('mo'),
                    state: state,
                  ),
                  WingaPhase.merchantAi => _AiChat(
                    key: const ValueKey('mai'),
                    state: state,
                    input: _ai,
                    hint: 'Ask about sales, inventory, pricing…',
                    onSend: ctrl.sendBusinessAi,
                  ),
                  WingaPhase.aiShop => _AiChat(
                    key: const ValueKey('ai'),
                    state: state,
                    input: _ai,
                    hint: 'e.g. refrigerator under TSh 900,000',
                    onSend: ctrl.sendAiShop,
                    chips: const [
                      'Fridge under 900k',
                      'Wedding photographer',
                      'School uniforms',
                    ],
                  ),
                  WingaPhase.negotia => _Negotia(
                    key: const ValueKey('neg'),
                    state: state,
                    ctrl: ctrl,
                    input: _ai,
                  ),
                  WingaPhase.wishlist => _Wishlist(
                    key: const ValueKey('w'),
                    state: state,
                    ctrl: ctrl,
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.state,
    required this.ctrl,
    required this.onLeave,
  });
  final WingaUiState state;
  final WingaController ctrl;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final title = switch (state.phase) {
      WingaPhase.home => 'WINGA',
      WingaPhase.marketplace => 'Marketplace',
      WingaPhase.productDetail => state.selectedProduct?.name ?? 'Product',
      WingaPhase.cart => 'Cart',
      WingaPhase.checkout => 'Checkout',
      WingaPhase.orderConfirm => 'Order confirmed',
      WingaPhase.tracking => 'Delivery',
      WingaPhase.services => 'Services',
      WingaPhase.serviceDetail => state.selectedService?.title ?? 'Service',
      WingaPhase.serviceBook => 'Book service',
      WingaPhase.serviceDone => 'Booked',
      WingaPhase.openShop => 'Open Shop',
      WingaPhase.merchant => 'Business Dashboard',
      WingaPhase.merchantOrders => 'Orders',
      WingaPhase.merchantAi => 'Business AI',
      WingaPhase.aiShop => 'AI Shopping',
      WingaPhase.negotia => 'NEGOTIA AI',
      WingaPhase.wishlist => 'Wishlist',
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onLeave,
            icon: Icon(Icons.arrow_back_rounded, color: palette.textPrimary),
          ),
          const TaifaLogo(variant: TaifaLogoVariant.mark, size: 32),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TaifaTypography.sectionTitle(
                palette.textPrimary,
              ).copyWith(fontSize: 18),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (state.phase == WingaPhase.home ||
              state.phase == WingaPhase.marketplace) ...[
            IconButton(
              onPressed: ctrl.openWishlist,
              icon: Icon(
                Icons.favorite_border_rounded,
                color: palette.textMuted,
              ),
            ),
            Badge(
              isLabelVisible: state.cartCount > 0,
              label: Text('${state.cartCount}'),
              child: IconButton(
                onPressed: ctrl.openCart,
                icon: Icon(
                  Icons.shopping_bag_outlined,
                  color: palette.textMuted,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Home extends StatelessWidget {
  const _Home({super.key, required this.state, required this.ctrl});
  final WingaUiState state;
  final WingaController ctrl;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Text(
          'AI Commerce · Tanzania',
          style: TextStyle(color: palette.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 4),
        Text(
          'Shop · Services · Open Shop',
          style: TaifaTypography.sectionTitle(
            palette.textPrimary,
          ).copyWith(fontSize: 22),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Chip(label: 'Marketplace', onTap: () => ctrl.openMarketplace()),
            _Chip(label: 'Services', onTap: () => ctrl.openServices()),
            _Chip(label: 'AI Shopping', onTap: ctrl.openAiShop),
            _Chip(label: 'NEGOTIA', onTap: ctrl.openNegotia),
            _Chip(label: 'Open Shop', onTap: ctrl.openShopFlow),
            _Chip(label: 'Dashboard', onTap: ctrl.openMerchant),
          ],
        ),
        const SizedBox(height: 22),
        _SectionTitle('Featured Stores'),
        const SizedBox(height: 10),
        SizedBox(
          height: 118,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: state.stores.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final s = state.stores[i];
              return _StoreCard(
                store: s,
                onTap: () => ctrl.openMarketplace(category: s.category),
              );
            },
          ),
        ),
        const SizedBox(height: 22),
        _SectionTitle('Categories'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: WingaCatalog.categories
              .map(
                (c) => ActionChip(
                  label: Text(c),
                  onPressed: () => ctrl.openMarketplace(category: c),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 22),
        _SectionTitle("Today's Deals"),
        const SizedBox(height: 10),
        ...state.deals.map(
          (p) => _ProductTile(product: p, onTap: () => ctrl.openProduct(p)),
        ),
        const SizedBox(height: 16),
        _SectionTitle('Recommended Products'),
        const SizedBox(height: 10),
        ...state.recommended
            .take(3)
            .map(
              (p) => _ProductTile(product: p, onTap: () => ctrl.openProduct(p)),
            ),
        const SizedBox(height: 16),
        _SectionTitle('Trending Products'),
        const SizedBox(height: 10),
        ...state.trending.map(
          (p) => _ProductTile(product: p, onTap: () => ctrl.openProduct(p)),
        ),
        const SizedBox(height: 16),
        _SectionTitle('Popular Businesses'),
        const SizedBox(height: 10),
        ...state.stores
            .take(3)
            .map(
              (s) => _ListCard(
                title: s.name,
                subtitle:
                    '${s.category} · ${s.city} · ★ ${s.rating}${s.verified ? ' · Verified' : ''}',
                onTap: () => ctrl.openMarketplace(category: s.category),
              ),
            ),
        const SizedBox(height: 16),
        _SectionTitle('Nearby Businesses'),
        const SizedBox(height: 10),
        ...state.stores
            .where((s) => s.city.contains('Dar'))
            .map(
              (s) => _ListCard(
                title: s.name,
                subtitle: '${s.tagline} · ${s.city}',
                onTap: () => ctrl.openMarketplace(category: s.category),
              ),
            ),
        const SizedBox(height: 16),
        _SectionTitle('Services'),
        const SizedBox(height: 10),
        ...state.services
            .take(4)
            .map(
              (s) => _ListCard(
                title: s.title,
                subtitle: '${s.provider} · from ${s.priceFrom.format()}',
                onTap: () => ctrl.openService(s),
              ),
            ),
        if (state.recentlyViewed.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionTitle('Recently Viewed'),
          const SizedBox(height: 10),
          ...state.recentlyViewed.map(
            (p) => _ProductTile(product: p, onTap: () => ctrl.openProduct(p)),
          ),
        ],
        const SizedBox(height: 16),
        _SectionTitle('AI Shopping'),
        const SizedBox(height: 10),
        _ListCard(
          title: 'Ask WINGA AI',
          subtitle: 'Compare prices · find pros · shop in Kiswahili',
          onTap: ctrl.openAiShop,
        ),
        const SizedBox(height: 10),
        _ListCard(
          title: 'NEGOTIA AI',
          subtitle: 'Bulk procurement · quotes · transport estimates',
          onTap: ctrl.openNegotia,
        ),
        const SizedBox(height: 10),
        _ListCard(
          title: 'Open Shop',
          subtitle: 'Create a digital business on TAIFA',
          onTap: ctrl.openShopFlow,
        ),
        const SizedBox(height: 10),
        _ListCard(
          title: 'Business Dashboard',
          subtitle: 'Orders · inventory · Business AI',
          onTap: ctrl.openMerchant,
        ),
      ],
    );
  }
}

class _Marketplace extends StatelessWidget {
  const _Marketplace({
    super.key,
    required this.state,
    required this.ctrl,
    required this.search,
  });
  final WingaUiState state;
  final WingaController ctrl;
  final TextEditingController search;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final list = state.categoryFilter == null && state.query.isEmpty
        ? state.products
        : state.products;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        TextField(
          controller: search,
          onChanged: ctrl.setQuery,
          decoration: InputDecoration(
            hintText: 'Search products',
            prefixIcon: Icon(Icons.search_rounded, color: palette.textMuted),
            filled: true,
            fillColor: palette.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (state.categoryFilter != null)
          Align(
            alignment: Alignment.centerLeft,
            child: InputChip(
              label: Text(state.categoryFilter!),
              onDeleted: () => ctrl.openMarketplace(),
            ),
          ),
        const SizedBox(height: 8),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'No products match.',
              style: TextStyle(color: palette.textMuted),
            ),
          )
        else
          ...list.map(
            (p) => _ProductTile(product: p, onTap: () => ctrl.openProduct(p)),
          ),
      ],
    );
  }
}

class _ProductDetail extends StatelessWidget {
  const _ProductDetail({super.key, required this.state, required this.ctrl});
  final WingaUiState state;
  final WingaController ctrl;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final p = state.selectedProduct!;
    final related = state.catalogProducts
        .where((x) => x.category == p.category && x.id != p.id)
        .take(3);
    final wished = state.wishlistIds.contains(p.id);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          p.name,
          style: TaifaTypography.sectionTitle(
            palette.textPrimary,
          ).copyWith(fontSize: 22),
        ),
        Text(
          '${p.category} · ★ ${p.rating} (${p.reviewCount} reviews)',
          style: TextStyle(color: palette.textMuted),
        ),
        const SizedBox(height: 12),
        Text(
          p.price.format(),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
            fontSize: 24,
          ),
        ),
        if (p.compareAt != null)
          Text(
            p.compareAt!.format(),
            style: TextStyle(
              color: palette.textMuted,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        const SizedBox(height: 12),
        Text(
          p.description,
          style: TextStyle(color: palette.textPrimary, height: 1.4),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: () => ctrl.addToCart(p),
                style: FilledButton.styleFrom(
                  backgroundColor: TaifaColors.emerald700,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Add to cart'),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              onPressed: () => ctrl.toggleWishlist(p.id),
              icon: Icon(
                wished ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _SectionTitle('Related Products'),
        const SizedBox(height: 8),
        ...related.map(
          (r) => _ProductTile(product: r, onTap: () => ctrl.openProduct(r)),
        ),
      ],
    );
  }
}

class _Cart extends StatelessWidget {
  const _Cart({super.key, required this.state, required this.ctrl});
  final WingaUiState state;
  final WingaController ctrl;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    if (state.cart.isEmpty) {
      return Center(
        child: Text(
          'Cart is empty.',
          style: TextStyle(color: palette.textMuted),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        ...state.cart.map(
          (l) => Material(
            color: palette.surface,
            borderRadius: BorderRadius.circular(14),
            child: ListTile(
              title: Text(
                l.product.name,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
              ),
              subtitle: Text(
                l.lineTotal.format(),
                style: TextStyle(color: palette.textMuted),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => ctrl.setQty(l.product.id, l.quantity - 1),
                    icon: const Icon(Icons.remove),
                  ),
                  Text('${l.quantity}'),
                  IconButton(
                    onPressed: () => ctrl.setQty(l.product.id, l.quantity + 1),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Total ${state.cartTotal.format()}',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: ctrl.goCheckout,
          style: FilledButton.styleFrom(
            backgroundColor: TaifaColors.emerald700,
            minimumSize: const Size.fromHeight(48),
          ),
          child: const Text('Checkout'),
        ),
      ],
    );
  }
}

class _Checkout extends StatelessWidget {
  const _Checkout({super.key, required this.state, required this.ctrl});
  final WingaUiState state;
  final WingaController ctrl;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          'Pay with TAIFA Wallet',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${state.cartCount} items · ${state.cartTotal.format()}',
          style: TextStyle(color: palette.textMuted),
        ),
        const SizedBox(height: 8),
        Text(
          'Delivery via Mobility mock dispatch',
          style: TextStyle(color: palette.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: state.isBusy ? null : ctrl.payWithWallet,
          style: FilledButton.styleFrom(
            backgroundColor: TaifaColors.emerald700,
            minimumSize: const Size.fromHeight(48),
          ),
          child: Text(
            state.isBusy ? 'Paying…' : 'Pay ${state.cartTotal.format()}',
          ),
        ),
      ],
    );
  }
}

class _OrderConfirm extends StatelessWidget {
  const _OrderConfirm({super.key, required this.state, required this.ctrl});
  final WingaUiState state;
  final WingaController ctrl;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final o = state.order!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Order confirmed',
          style: TaifaTypography.sectionTitle(
            palette.textPrimary,
          ).copyWith(fontSize: 22),
        ),
        Text('${o.paymentRef}', style: TextStyle(color: palette.textMuted)),
        Text(
          '${o.total.format()} · ${o.status.label}',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: palette.textPrimary,
          ),
        ),
        if (o.courierName != null)
          Text(
            'Courier · ${o.courierName} · ${o.etaLabel}',
            style: TextStyle(color: palette.textMuted),
          ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: ctrl.startTracking,
          style: FilledButton.styleFrom(
            backgroundColor: TaifaColors.emerald700,
            minimumSize: const Size.fromHeight(48),
          ),
          child: const Text('Track delivery'),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () => context.go('/home'),
          child: const Text('Back to Home'),
        ),
      ],
    );
  }
}

class _Tracking extends StatelessWidget {
  const _Tracking({super.key, required this.state});
  final WingaUiState state;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final o = state.order!;
    final steps = WingaOrderStatus.values;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          o.status.label,
          style: TaifaTypography.sectionTitle(
            palette.textPrimary,
          ).copyWith(fontSize: 22),
        ),
        Text(
          '${o.courierName ?? 'Courier'} · ${o.etaLabel ?? ''}',
          style: TextStyle(color: palette.textMuted),
        ),
        const SizedBox(height: 20),
        ...steps.map((s) {
          final done = s.index <= o.status.index;
          return ListTile(
            leading: Icon(
              done ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: done ? TaifaColors.emerald500 : palette.textMuted,
            ),
            title: Text(
              s.label,
              style: TextStyle(
                color: palette.textPrimary,
                fontWeight: done ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _Services extends StatelessWidget {
  const _Services({super.key, required this.state, required this.ctrl});
  final WingaUiState state;
  final WingaController ctrl;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: WingaCatalog.serviceCategories
              .map(
                (c) => ActionChip(
                  label: Text(c),
                  onPressed: () => ctrl.openServices(category: c),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        ...state.services.map(
          (s) => _ListCard(
            title: s.title,
            subtitle:
                '${s.category} · ${s.provider} · from ${s.priceFrom.format()} · ★ ${s.rating}',
            onTap: () => ctrl.openService(s),
          ),
        ),
      ],
    );
  }
}

class _ServiceDetail extends StatelessWidget {
  const _ServiceDetail({super.key, required this.state, required this.ctrl});
  final WingaUiState state;
  final WingaController ctrl;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final s = state.selectedService!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          s.title,
          style: TaifaTypography.sectionTitle(
            palette.textPrimary,
          ).copyWith(fontSize: 22),
        ),
        Text(
          '${s.provider} · ${s.city}',
          style: TextStyle(color: palette.textMuted),
        ),
        const SizedBox(height: 12),
        Text(
          'From ${s.priceFrom.format()}',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: ctrl.goServiceBook,
          style: FilledButton.styleFrom(
            backgroundColor: TaifaColors.emerald700,
            minimumSize: const Size.fromHeight(48),
          ),
          child: const Text('Book'),
        ),
      ],
    );
  }
}

class _ServiceBook extends StatelessWidget {
  const _ServiceBook({super.key, required this.state, required this.ctrl});
  final WingaUiState state;
  final WingaController ctrl;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Choose a slot',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ...WingaCatalog.serviceSlots.map(
          (slot) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: state.serviceSlot == slot
                  ? TaifaColors.emerald500.withValues(alpha: 0.15)
                  : palette.surface,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: () => ctrl.setServiceSlot(slot),
                borderRadius: BorderRadius.circular(14),
                child: ListTile(
                  title: Text(
                    slot,
                    style: TextStyle(color: palette.textPrimary),
                  ),
                  trailing: Icon(
                    state.serviceSlot == slot
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color: state.serviceSlot == slot
                        ? TaifaColors.emerald500
                        : palette.textMuted,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: state.isBusy ? null : ctrl.payService,
          style: FilledButton.styleFrom(
            backgroundColor: TaifaColors.emerald700,
            minimumSize: const Size.fromHeight(48),
          ),
          child: Text(
            state.isBusy
                ? 'Paying…'
                : 'Pay with wallet · ${state.selectedService?.priceFrom.format()}',
          ),
        ),
      ],
    );
  }
}

class _ServiceDone extends StatelessWidget {
  const _ServiceDone({super.key, required this.state});
  final WingaUiState state;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final b = state.serviceBooking!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Service booked',
          style: TaifaTypography.sectionTitle(
            palette.textPrimary,
          ).copyWith(fontSize: 22),
        ),
        Text(
          b.service.title,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
          ),
        ),
        Text(
          '${b.slotLabel} · ${b.paymentRef}',
          style: TextStyle(color: palette.textMuted),
        ),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: () => context.go('/home'),
          child: const Text('Back to Home'),
        ),
      ],
    );
  }
}

class _OpenShopState extends State<_OpenShop> {
  late final TextEditingController _address;

  @override
  void initState() {
    super.initState();
    _address = TextEditingController(text: widget.state.shopDraft.address);
  }

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final state = widget.state;
    final ctrl = widget.ctrl;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Create your digital business',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: widget.nameCtrl,
          decoration: const InputDecoration(labelText: 'Business name'),
          onChanged: (v) => ctrl.updateShopDraft(name: v),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: state.shopDraft.category,
          items: WingaCatalog.categories
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (v) {
            if (v != null) ctrl.updateShopDraft(category: v);
          },
          decoration: const InputDecoration(labelText: 'Category'),
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: const InputDecoration(labelText: 'Address'),
          controller: _address,
          onChanged: (v) => ctrl.updateShopDraft(address: v),
        ),
        const SizedBox(height: 8),
        Text(
          'Logo · ${state.shopDraft.logoEmoji} (mock upload)',
          style: TextStyle(color: palette.textMuted),
        ),
        Text(
          'Verification · pending mock approval',
          style: TextStyle(color: palette.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: state.isBusy ? null : ctrl.submitShop,
          style: FilledButton.styleFrom(
            backgroundColor: TaifaColors.emerald700,
            minimumSize: const Size.fromHeight(48),
          ),
          child: Text(state.isBusy ? 'Submitting…' : 'Submit for approval'),
        ),
      ],
    );
  }
}

class _OpenShop extends StatefulWidget {
  const _OpenShop({
    super.key,
    required this.state,
    required this.ctrl,
    required this.nameCtrl,
  });
  final WingaUiState state;
  final WingaController ctrl;
  final TextEditingController nameCtrl;

  @override
  State<_OpenShop> createState() => _OpenShopState();
}

class _Merchant extends StatelessWidget {
  const _Merchant({super.key, required this.state, required this.ctrl});
  final WingaUiState state;
  final WingaController ctrl;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final s = state.merchantStats;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          state.shopDraft.name.isEmpty ? 'Your store' : state.shopDraft.name,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
            fontSize: 18,
          ),
        ),
        Text(
          'Status · ${state.shopDraft.status.name}',
          style: TextStyle(color: palette.textMuted),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatBox(
                label: 'Sales',
                value: s?.salesToday.format() ?? '—',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatBox(label: 'Orders', value: '${s?.openOrders ?? 0}'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatBox(label: 'Products', value: '${s?.products ?? 0}'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatBox(
                label: 'Customers',
                value: '${s?.customers ?? 0}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ListCard(
          title: 'Orders',
          subtitle: 'Packing · new · dispatched',
          onTap: ctrl.openMerchantOrders,
        ),
        _ListCard(
          title: 'Products & inventory',
          subtitle: 'Mock catalog linked to WINGA',
          onTap: () => ctrl.openMarketplace(),
        ),
        _ListCard(
          title: 'Promotions & coupons',
          subtitle: 'UNIFORM10 · flash deals (demo)',
          onTap: ctrl.openMerchantAi,
        ),
        _ListCard(
          title: 'Reports & analytics',
          subtitle: 'Ask Business AI for insights',
          onTap: ctrl.openMerchantAi,
        ),
        _ListCard(
          title: 'Business AI',
          subtitle: 'Sales · stock · pricing · marketing',
          onTap: ctrl.openMerchantAi,
        ),
      ],
    );
  }
}

class _MerchantOrders extends StatelessWidget {
  const _MerchantOrders({super.key, required this.state});
  final WingaUiState state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: state.merchantOrders
          .map(
            (o) => _ListCard(
              title: '${o.customer} · ${o.statusLabel}',
              subtitle: '${o.itemsSummary} · ${o.total.format()}',
              onTap: () {},
            ),
          )
          .toList(),
    );
  }
}

class _AiChat extends StatelessWidget {
  const _AiChat({
    super.key,
    required this.state,
    required this.input,
    required this.hint,
    required this.onSend,
    this.chips = const [],
  });
  final WingaUiState state;
  final TextEditingController input;
  final String hint;
  final Future<void> Function(String) onSend;
  final List<String> chips;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return Column(
      children: [
        if (chips.isNotEmpty)
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: chips
                  .map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(c),
                        onPressed: () {
                          input.text = c;
                          onSend(c);
                        },
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        Expanded(
          child: state.aiMessages.isEmpty
              ? Center(
                  child: Text(
                    'Ask WINGA — mock AI commerce brain',
                    style: TextStyle(color: palette.textMuted),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.aiMessages.length,
                  itemBuilder: (_, i) {
                    final m = state.aiMessages[i];
                    return Align(
                      alignment: m.isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
                        ),
                        decoration: BoxDecoration(
                          color: m.isUser
                              ? TaifaColors.emerald700
                              : palette.surface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          m.text,
                          style: TextStyle(
                            color: m.isUser
                                ? Colors.white
                                : palette.textPrimary,
                            height: 1.35,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: input,
                  decoration: InputDecoration(
                    hintText: hint,
                    filled: true,
                    fillColor: palette.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (v) {
                    onSend(v);
                    input.clear();
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: state.isBusy
                    ? null
                    : () {
                        onSend(input.text);
                        input.clear();
                      },
                style: IconButton.styleFrom(
                  backgroundColor: TaifaColors.emerald700,
                ),
                icon: const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Negotia extends StatelessWidget {
  const _Negotia({
    super.key,
    required this.state,
    required this.ctrl,
    required this.input,
  });
  final WingaUiState state;
  final WingaController ctrl;
  final TextEditingController input;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Autonomous procurement — mock suppliers & quotes',
            style: TextStyle(color: palette.textMuted, fontSize: 12),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...state.aiMessages.map(
                (m) => Align(
                  alignment: m.isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: m.isUser
                          ? TaifaColors.emerald700
                          : palette.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      m.text,
                      style: TextStyle(
                        color: m.isUser ? Colors.white : palette.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              ...state.negotiaQuotes.map(
                (q) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(14),
                    child: ListTile(
                      title: Text(
                        q.supplier,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: palette.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        '${q.unitPrice.format()} × ${q.qty} + ${q.transport.format()} transport\n${q.scoreLabel}${q.negotiated ? ' · negotiated' : ''}',
                        style: TextStyle(
                          color: palette.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      isThreeLine: true,
                      trailing: Text(
                        q.grandTotal.format(),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: TaifaColors.emerald500,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: input,
                  decoration: InputDecoration(
                    hintText: 'e.g. I need 500 bags of cement',
                    filled: true,
                    fillColor: palette.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              IconButton.filled(
                onPressed: state.isBusy
                    ? null
                    : () {
                        ctrl.runNegotia(
                          input.text.isEmpty
                              ? '500 bags of cement'
                              : input.text,
                        );
                        input.clear();
                      },
                style: IconButton.styleFrom(
                  backgroundColor: TaifaColors.emerald700,
                ),
                icon: const Icon(Icons.auto_awesome),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Wishlist extends StatelessWidget {
  const _Wishlist({super.key, required this.state, required this.ctrl});
  final WingaUiState state;
  final WingaController ctrl;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    if (state.wishlist.isEmpty) {
      return Center(
        child: Text(
          'No favorites yet.',
          style: TextStyle(color: palette.textMuted),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: state.wishlist
          .map(
            (p) => _ProductTile(product: p, onTap: () => ctrl.openProduct(p)),
          )
          .toList(),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w800,
        color: context.taifa.textPrimary,
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(label: Text(label), onPressed: onTap);
  }
}

class _StoreCard extends StatelessWidget {
  const _StoreCard({required this.store, required this.onTap});
  final WingaStore store;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return SizedBox(
      width: 160,
      child: Material(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${store.city} · ★ ${store.rating}',
                  style: TextStyle(color: palette.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product, required this.onTap});
  final WingaProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: ListTile(
            title: Text(
              product.name,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
            ),
            subtitle: Text(
              '${product.price.format()}${product.badge != null ? ' · ${product.badge}' : ''}',
              style: TextStyle(color: palette.textMuted, fontSize: 12),
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: palette.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _ListCard extends StatelessWidget {
  const _ListCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: ListTile(
            title: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: TextStyle(color: palette.textMuted, fontSize: 12),
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: palette.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: palette.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: palette.textPrimary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

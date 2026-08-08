import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../../../app/theme/taifa_theme.dart';
import '../../../app/theme/taifa_typography.dart';
import '../../../shared/widgets/taifa_logo.dart';
import '../application/food_providers.dart';
import '../domain/food_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Food — Demo Complete delivery experience (mock catalog, cart, dispatch).
class FoodScreen extends ConsumerStatefulWidget {
  const FoodScreen({super.key});

  @override
  ConsumerState<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends ConsumerState<FoodScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(foodControllerProvider.notifier).bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(foodControllerProvider);
    final ctrl = ref.read(foodControllerProvider.notifier);
    final palette = context.taifa;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              title: switch (state.phase) {
                FoodPhase.home => 'TAIFA Food',
                FoodPhase.menu => state.selected?.name ?? 'Menu',
                FoodPhase.cart => 'Your cart',
                FoodPhase.checkout => 'Checkout',
                FoodPhase.tracking => 'Tracking',
                FoodPhase.delivered => 'Delivered',
                FoodPhase.receipt => 'Receipt',
                FoodPhase.history => 'Orders',
              },
              onBack: () {
                switch (state.phase) {
                  case FoodPhase.home:
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  case FoodPhase.menu:
                    ctrl.backToHome();
                  case FoodPhase.cart:
                    ctrl.backToMenu();
                  case FoodPhase.checkout:
                    ctrl.openCart();
                  case FoodPhase.history:
                    ctrl.backToHome();
                  default:
                    ctrl.backToHome();
                }
              },
              onHistory: ctrl.openHistory,
              cartCount: state.cartCount,
              onCart:
                  state.phase == FoodPhase.menu || state.phase == FoodPhase.home
                  ? ctrl.openCart
                  : null,
            ),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Text(
                  state.error!,
                  style: const TextStyle(
                    color: Color(0xFFFF8A80),
                    fontSize: 12,
                  ),
                ),
              ),
            Expanded(
              child: AnimatedSwitcher(
                duration: TaifaMotion.base,
                child: _Body(
                  key: ValueKey(state.phase),
                  state: state,
                  ctrl: ctrl,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.onBack,
    required this.onHistory,
    required this.cartCount,
    this.onCart,
  });

  final String title;
  final VoidCallback onBack;
  final VoidCallback onHistory;
  final int cartCount;
  final VoidCallback? onCart;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(LucideIcons.arrowLeft, color: palette.textPrimary),
          ),
          const TaifaLogo(variant: TaifaLogoVariant.mark, size: 32),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: palette.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
          ),
          IconButton(
            onPressed: onHistory,
            icon: Icon(LucideIcons.receipt, color: palette.textMuted),
          ),
          if (onCart != null)
            Stack(
              children: [
                IconButton(
                  onPressed: onCart,
                  icon: Icon(
                    LucideIcons.shoppingBag,
                    color: palette.textPrimary,
                  ),
                ),
                if (cartCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: TaifaColors.gold500,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$cartCount',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: TaifaColors.black900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({super.key, required this.state, required this.ctrl});
  final FoodUiState state;
  final FoodController ctrl;

  @override
  Widget build(BuildContext context) {
    return switch (state.phase) {
      FoodPhase.home => _HomeView(state: state, ctrl: ctrl),
      FoodPhase.menu => _MenuView(state: state, ctrl: ctrl),
      FoodPhase.cart => _CartView(state: state, ctrl: ctrl),
      FoodPhase.checkout => _CheckoutView(state: state, ctrl: ctrl),
      FoodPhase.tracking => _TrackingView(state: state),
      FoodPhase.delivered => _DeliveredView(state: state, ctrl: ctrl),
      FoodPhase.receipt => _ReceiptView(state: state, ctrl: ctrl),
      FoodPhase.history => _HistoryView(state: state, ctrl: ctrl),
    };
  }
}

const _tones = [
  Color(0xFF0E5A44),
  Color(0xFF1A3A5C),
  Color(0xFF5A2E0E),
  Color(0xFF2E3A1A),
];

class _HomeView extends StatelessWidget {
  const _HomeView({required this.state, required this.ctrl});
  final FoodUiState state;
  final FoodController ctrl;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          'Order food nearby',
          style: TaifaTypography.sectionTitle(
            palette.textPrimary,
          ).copyWith(fontSize: 26),
        ),
        const SizedBox(height: 6),
        Text(
          'Demo catalog · mock courier tracking · wallet pay',
          style: TextStyle(color: palette.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 14),
        TextField(
          onChanged: ctrl.search,
          style: TextStyle(color: palette.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search restaurants or cuisine',
            hintStyle: TextStyle(color: palette.textMuted),
            prefixIcon: Icon(LucideIcons.search, color: palette.textMuted),
            filled: true,
            fillColor: palette.surfaceAlt,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (state.isBusy)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: CircularProgressIndicator(color: TaifaColors.gold400),
            ),
          )
        else if (state.restaurants.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'No restaurants match that search.',
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.textMuted),
            ),
          )
        else
          ...state.restaurants.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RestaurantCard(
                restaurant: r,
                onTap: () => ctrl.openRestaurant(r),
              ),
            ),
          ),
      ],
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  const _RestaurantCard({required this.restaurant, required this.onTap});
  final Restaurant restaurant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final tone = _tones[restaurant.imageTone % _tones.length];
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.border),
          color: palette.surface,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 96,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [tone, tone.withValues(alpha: 0.55)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(14),
              alignment: Alignment.bottomLeft,
              child: Row(
                children: [
                  if (restaurant.featured)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: TaifaColors.gold500,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'FEATURED',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: TaifaColors.black900,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    restaurant.cuisine,
                    style: TextStyle(color: palette.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '★ ${restaurant.rating.toStringAsFixed(1)} · ${restaurant.etaMinutes} min · Delivery ${restaurant.deliveryFee.format()}',
                    style: TextStyle(
                      color: palette.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuView extends StatelessWidget {
  const _MenuView({required this.state, required this.ctrl});
  final FoodUiState state;
  final FoodController ctrl;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final r = state.selected!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        Text(r.cuisine, style: TextStyle(color: palette.textMuted)),
        const SizedBox(height: 4),
        Text(
          '★ ${r.rating} · ${r.etaMinutes} min',
          style: TextStyle(
            color: palette.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        for (final item in r.menu)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 6),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (item.popular)
                  const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Text(
                      'Popular',
                      style: TextStyle(
                        color: TaifaColors.gold400,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Text(
              item.description,
              style: TextStyle(color: palette.textMuted, fontSize: 12),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.price.format(),
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 28,
                  child: FilledButton(
                    onPressed: () => ctrl.addItem(item),
                    style: FilledButton.styleFrom(
                      backgroundColor: TaifaColors.emerald700,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text(
                      'Add',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CartView extends StatelessWidget {
  const _CartView({required this.state, required this.ctrl});
  final FoodUiState state;
  final FoodController ctrl;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: [
          Expanded(
            child: state.cart.isEmpty
                ? Center(
                    child: Text(
                      'Cart is empty',
                      style: TextStyle(color: palette.textMuted),
                    ),
                  )
                : ListView.separated(
                    itemCount: state.cart.length,
                    separatorBuilder: (_, _) => Divider(color: palette.border),
                    itemBuilder: (_, i) {
                      final line = state.cart[i];
                      return Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  line.item.name,
                                  style: TextStyle(
                                    color: palette.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  line.lineTotal.format(),
                                  style: TextStyle(
                                    color: palette.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => ctrl.setQuantity(
                              line.item.id,
                              line.quantity - 1,
                            ),
                            icon: Icon(
                              LucideIcons.circleMinus,
                              color: palette.textMuted,
                            ),
                          ),
                          Text(
                            '${line.quantity}',
                            style: TextStyle(
                              color: palette.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          IconButton(
                            onPressed: () => ctrl.setQuantity(
                              line.item.id,
                              line.quantity + 1,
                            ),
                            icon: const Icon(
                              LucideIcons.circlePlus,
                              color: TaifaColors.gold400,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          _Totals(
            subtotal: state.subtotal.format(),
            fee: state.deliveryFee.format(),
            total: state.total.format(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: state.cart.isEmpty ? null : ctrl.goCheckout,
              style: FilledButton.styleFrom(
                backgroundColor: TaifaColors.gold500,
                foregroundColor: TaifaColors.black900,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Checkout',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutView extends StatelessWidget {
  const _CheckoutView({required this.state, required this.ctrl});
  final FoodUiState state;
  final FoodController ctrl;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Deliver to',
            style: TextStyle(color: palette.textMuted, fontSize: 12),
          ),
          Text(
            'Masaki Peninsula · Home',
            style: TextStyle(
              color: palette.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Pay with',
            style: TextStyle(color: palette.textMuted, fontSize: 12),
          ),
          Text(
            'TAIFA Wallet',
            style: TextStyle(
              color: palette.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 20),
          _Totals(
            subtotal: state.subtotal.format(),
            fee: state.deliveryFee.format(),
            total: state.total.format(),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: state.isBusy ? null : ctrl.placeOrder,
              style: FilledButton.styleFrom(
                backgroundColor: TaifaColors.emerald700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                state.isBusy
                    ? 'Placing…'
                    : 'Place order · ${state.total.format()}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingView extends StatelessWidget {
  const _TrackingView({required this.state});
  final FoodUiState state;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final order = state.order!;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 24),
          const CircularProgressIndicator(color: TaifaColors.gold400),
          const SizedBox(height: 20),
          Text(
            order.status.label,
            style: TaifaTypography.sectionTitle(
              palette.textPrimary,
            ).copyWith(fontSize: 22),
          ),
          const SizedBox(height: 8),
          Text(
            '${order.restaurant.name} · Courier ${order.courierName ?? '…'}',
            style: TextStyle(color: palette.textMuted),
          ),
          if (order.etaMinutes != null) ...[
            const SizedBox(height: 6),
            Text(
              'ETA ~ ${order.etaMinutes} min',
              style: const TextStyle(
                color: TaifaColors.gold400,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: order.progress.clamp(0.05, 1),
              minHeight: 8,
              backgroundColor: palette.surfaceAlt,
              color: TaifaColors.ocean400,
            ),
          ),
          const SizedBox(height: 28),
          _StatusSteps(status: order.status),
        ],
      ),
    );
  }
}

class _StatusSteps extends StatelessWidget {
  const _StatusSteps({required this.status});
  final FoodOrderStatus status;

  @override
  Widget build(BuildContext context) {
    final steps = [
      FoodOrderStatus.confirmed,
      FoodOrderStatus.preparing,
      FoodOrderStatus.pickingUp,
      FoodOrderStatus.onTheWay,
      FoodOrderStatus.delivered,
    ];
    final idx = steps.indexOf(status);
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          ListTile(
            dense: true,
            leading: Icon(
              i <= idx ? LucideIcons.circleCheckBig : LucideIcons.circle,
              color: i <= idx ? TaifaColors.gold400 : context.taifa.border,
            ),
            title: Text(
              steps[i].label,
              style: TextStyle(
                color: context.taifa.textPrimary,
                fontWeight: i == idx ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

class _DeliveredView extends StatelessWidget {
  const _DeliveredView({required this.state, required this.ctrl});
  final FoodUiState state;
  final FoodController ctrl;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final order = state.order!;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(
            LucideIcons.circleCheckBig,
            color: TaifaColors.emerald500,
            size: 64,
          ),
          const SizedBox(height: 12),
          Text(
            'Enjoy your meal',
            style: TaifaTypography.sectionTitle(
              palette.textPrimary,
            ).copyWith(fontSize: 24),
          ),
          const SizedBox(height: 8),
          Text(
            order.restaurant.name,
            style: TextStyle(color: palette.textMuted),
          ),
          const SizedBox(height: 8),
          Text(
            order.total.format(),
            style: TaifaTypography.balance(palette.textPrimary),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: ctrl.confirmPayment,
              style: FilledButton.styleFrom(
                backgroundColor: TaifaColors.gold500,
                foregroundColor: TaifaColors.black900,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Pay with TAIFA Wallet',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptView extends StatelessWidget {
  const _ReceiptView({required this.state, required this.ctrl});
  final FoodUiState state;
  final FoodController ctrl;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final order = state.order!;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order receipt',
            style: TaifaTypography.sectionTitle(
              palette.textPrimary,
            ).copyWith(fontSize: 22),
          ),
          const SizedBox(height: 16),
          _kv('Restaurant', order.restaurant.name, palette),
          _kv('Items', '${order.lines.length}', palette),
          _kv('Total', order.total.format(), palette),
          _kv('Payment', order.paymentRef ?? '—', palette),
          _kv('Status', order.status.label, palette),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: ctrl.backToHome,
              style: FilledButton.styleFrom(
                backgroundColor: TaifaColors.emerald700,
              ),
              child: const Text(
                'Order again',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v, TaifaPalette p) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(k, style: TextStyle(color: p.textMuted)),
        ),
        Expanded(
          child: Text(
            v,
            style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _HistoryView extends StatelessWidget {
  const _HistoryView({required this.state, required this.ctrl});
  final FoodUiState state;
  final FoodController ctrl;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final items = state.history;
    return items.isEmpty
        ? Center(
            child: Text(
              'No orders yet.',
              style: TextStyle(color: palette.textMuted),
            ),
          )
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => Divider(color: palette.border),
            itemBuilder: (_, i) {
              final o = items[i];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  o.restaurant.name,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  o.status.label,
                  style: TextStyle(color: palette.textMuted, fontSize: 12),
                ),
                trailing: Text(
                  o.total.format(),
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              );
            },
          );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({
    required this.subtotal,
    required this.fee,
    required this.total,
  });
  final String subtotal;
  final String fee;
  final String total;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    Widget row(String k, String v, {bool bold = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(k, style: TextStyle(color: palette.textMuted)),
          ),
          Text(
            v,
            style: TextStyle(
              color: palette.textPrimary,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
    return Column(
      children: [
        row('Subtotal', subtotal),
        row('Delivery', fee),
        const SizedBox(height: 4),
        row('Total', total, bold: true),
      ],
    );
  }
}

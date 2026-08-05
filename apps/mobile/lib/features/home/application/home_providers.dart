import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../ecosystem/application/ecosystem_modules_provider.dart';
import '../../ecosystem/domain/super_app_module_registry.dart';
import '../domain/home_models.dart';

/// Repository boundary for Home data. Today it returns curated seed data; the
/// same interface will later be backed by the wallet + catalog services over
/// versioned REST/WebSocket. Feature code depends on the interface, never the
/// implementation — so swapping to live APIs requires no widget changes.
abstract class HomeRepository {
  Future<WalletSummary> walletSummary();
  List<QuickAction> quickActions();
  List<ServiceItem> services();
  PromoOffer featuredOffer();
}

class SeedHomeRepository implements HomeRepository {
  const SeedHomeRepository();

  @override
  Future<WalletSummary> walletSummary() async => const WalletSummary(
    greetingName: 'Amani',
    balanceLabel: 'TSh 2,847,500',
    secondaryLabel: '≈ \$1,140 USD',
    maskedNumber: '•••• 8841',
  );

  @override
  List<QuickAction> quickActions() => const [
    QuickAction(id: 'send', label: 'Send', icon: Icons.north_east_rounded),
    QuickAction(
      id: 'scan',
      label: 'Scan QR',
      icon: Icons.qr_code_scanner_rounded,
    ),
    QuickAction(id: 'topup', label: 'Top Up', icon: Icons.add_rounded),
    QuickAction(id: 'bills', label: 'Bills', icon: Icons.receipt_long_rounded),
  ];

  @override
  List<ServiceItem> services() => const [
    ServiceItem(
      id: 'ride',
      label: 'Ride',
      icon: Icons.local_taxi_rounded,
      tint: TaifaColors.gold400,
      route: '/mobility',
    ),
    ServiceItem(
      id: 'pay',
      label: 'Pay',
      icon: Icons.payments_rounded,
      tint: TaifaColors.ocean500,
      route: '/pay',
    ),
    ServiceItem(
      id: 'winga',
      label: 'Winga',
      icon: Icons.shopping_bag_rounded,
      tint: TaifaColors.emerald500,
      route: '/winga',
    ),
    ServiceItem(
      id: 'commerce',
      label: 'Shop',
      icon: Icons.storefront_rounded,
      tint: TaifaColors.emerald600,
      route: '/commerce',
    ),
    ServiceItem(
      id: 'express',
      label: 'Express',
      icon: Icons.bolt_rounded,
      tint: TaifaColors.gold500,
      route: '/express',
    ),
    ServiceItem(
      id: 'food',
      label: 'Food',
      icon: Icons.restaurant_rounded,
      tint: TaifaColors.dangerSoft,
      route: '/food',
    ),
    ServiceItem(
      id: 'hotels',
      label: 'Hotels',
      icon: Icons.hotel_rounded,
      tint: TaifaColors.ocean400,
      route: '/stays',
    ),
    ServiceItem(
      id: 'flights',
      label: 'Flights',
      icon: Icons.flight_rounded,
      tint: TaifaColors.violetSoft,
      route: '/flights',
    ),
    ServiceItem(
      id: 'tourism',
      label: 'Tourism',
      icon: Icons.landscape_rounded,
      tint: TaifaColors.gold400,
      route: '/tourism',
    ),
    ServiceItem(
      id: 'gov',
      label: 'Gov',
      icon: Icons.account_balance_rounded,
      tint: TaifaColors.ocean400,
      route: '/gov',
    ),
    ServiceItem(
      id: 'health',
      label: 'Health',
      icon: Icons.local_hospital_rounded,
      tint: TaifaColors.dangerSoft,
      route: '/health',
    ),
    ServiceItem(
      id: 'agriculture',
      label: 'Agri',
      icon: Icons.agriculture_rounded,
      tint: TaifaColors.emerald500,
      route: '/agriculture',
    ),
    ServiceItem(
      id: 'education',
      label: 'Educ.',
      icon: Icons.school_rounded,
      tint: TaifaColors.violetSoft,
      route: '/education',
    ),
    ServiceItem(
      id: 'housing',
      label: 'Home',
      icon: Icons.cottage_rounded,
      tint: TaifaColors.emerald500,
      route: '/housing',
    ),
    ServiceItem(
      id: 'services',
      label: 'Enable',
      icon: Icons.apps_rounded,
      tint: TaifaColors.ocean400,
      route: '/my-services',
    ),
    ServiceItem(
      id: 'more',
      label: 'More',
      icon: Icons.grid_view_rounded,
      tint: TaifaColors.gold400,
      route: '/menu',
    ),
  ];

  @override
  PromoOffer featuredOffer() => const PromoOffer(
    title: 'Zanzibar Weekend',
    subtitle: 'Flights from TSh 145,000 · 2 nights',
    badge: '-30%',
  );
}

final homeRepositoryProvider = Provider<HomeRepository>(
  (ref) => const SeedHomeRepository(),
);

final walletSummaryProvider = FutureProvider<WalletSummary>(
  (ref) => ref.watch(homeRepositoryProvider).walletSummary(),
);

final quickActionsProvider = Provider<List<QuickAction>>(
  (ref) => ref.watch(homeRepositoryProvider).quickActions(),
);

final servicesProvider = Provider<List<ServiceItem>>((ref) {
  final modules = ref.watch(enabledModulesProvider).modules;
  if (modules.isEmpty) {
    return const SeedHomeRepository().services();
  }
  return SuperAppModuleRegistry.homeServices(modules);
});

final featuredOfferProvider = Provider<PromoOffer>(
  (ref) => ref.watch(homeRepositoryProvider).featuredOffer(),
);

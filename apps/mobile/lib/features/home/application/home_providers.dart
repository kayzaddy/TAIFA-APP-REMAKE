import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../ecosystem/application/ecosystem_modules_provider.dart';
import '../../ecosystem/domain/super_app_module_registry.dart';
import '../domain/home_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
    QuickAction(id: 'send', label: 'Send', icon: LucideIcons.arrowUpRight),
    QuickAction(
      id: 'scan',
      label: 'Scan QR',
      icon: LucideIcons.scanLine,
    ),
    QuickAction(id: 'topup', label: 'Top Up', icon: LucideIcons.plus),
    QuickAction(id: 'bills', label: 'Bills', icon: LucideIcons.receipt),
  ];

  @override
  List<ServiceItem> services() => const [
    ServiceItem(
      id: 'ride',
      label: 'Ride',
      icon: LucideIcons.carTaxiFront,
      tint: TaifaColors.gold400,
      route: '/mobility',
    ),
    ServiceItem(
      id: 'pay',
      label: 'Pay',
      icon: LucideIcons.banknote,
      tint: TaifaColors.ocean500,
      route: '/pay',
    ),
    ServiceItem(
      id: 'winga',
      label: 'Winga',
      icon: LucideIcons.shoppingBag,
      tint: TaifaColors.emerald500,
      route: '/winga',
    ),
    ServiceItem(
      id: 'commerce',
      label: 'Shop',
      icon: LucideIcons.store,
      tint: TaifaColors.emerald600,
      route: '/commerce',
    ),
    ServiceItem(
      id: 'express',
      label: 'Express',
      icon: LucideIcons.zap,
      tint: TaifaColors.gold500,
      route: '/express',
    ),
    ServiceItem(
      id: 'food',
      label: 'Food',
      icon: LucideIcons.utensils,
      tint: TaifaColors.dangerSoft,
      route: '/food',
    ),
    ServiceItem(
      id: 'hotels',
      label: 'Hotels',
      icon: LucideIcons.bed,
      tint: TaifaColors.ocean400,
      route: '/stays',
    ),
    ServiceItem(
      id: 'flights',
      label: 'Flights',
      icon: LucideIcons.plane,
      tint: TaifaColors.violetSoft,
      route: '/flights',
    ),
    ServiceItem(
      id: 'tourism',
      label: 'Tourism',
      icon: LucideIcons.mountain,
      tint: TaifaColors.gold400,
      route: '/tourism',
    ),
    ServiceItem(
      id: 'gov',
      label: 'Gov',
      icon: LucideIcons.landmark,
      tint: TaifaColors.ocean400,
      route: '/gov',
    ),
    ServiceItem(
      id: 'health',
      label: 'Health',
      icon: LucideIcons.briefcaseMedical,
      tint: TaifaColors.dangerSoft,
      route: '/health',
    ),
    ServiceItem(
      id: 'agriculture',
      label: 'Agri',
      icon: LucideIcons.sprout,
      tint: TaifaColors.emerald500,
      route: '/agriculture',
    ),
    ServiceItem(
      id: 'education',
      label: 'Educ.',
      icon: LucideIcons.graduationCap,
      tint: TaifaColors.violetSoft,
      route: '/education',
    ),
    ServiceItem(
      id: 'housing',
      label: 'Home',
      icon: LucideIcons.house,
      tint: TaifaColors.emerald500,
      route: '/housing',
    ),
    ServiceItem(
      id: 'services',
      label: 'Enable',
      icon: LucideIcons.layoutGrid,
      tint: TaifaColors.ocean400,
      route: '/my-services',
    ),
    ServiceItem(
      id: 'more',
      label: 'More',
      icon: LucideIcons.layoutGrid,
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

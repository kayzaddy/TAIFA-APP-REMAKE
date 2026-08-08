import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../ecosystem/application/ecosystem_modules_provider.dart';
import '../domain/ecosystem_catalog.dart';
import '../domain/feature_flags.dart';
import '../domain/qr_resolver.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

final superAppFlagsProvider = Provider<SuperAppFlags>((ref) => SuperAppFlags.current);

final qrResolverProvider = Provider<QrResolver>((ref) => const QrResolver());

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String value) => state = value;

  void clear() => state = '';
}

final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

final searchResultsProvider = Provider<List<EcosystemEntry>>((ref) {
  final q = ref.watch(searchQueryProvider);
  final enabledRoutes = ref.watch(enabledModulesProvider).enabledRoutes;
  return EcosystemCatalog.search(q, allowedRoutes: enabledRoutes);
});

class JourneyShortcut {
  const JourneyShortcut({
    required this.title,
    required this.subtitle,
    required this.route,
    required this.icon,
    required this.tint,
  });

  final String title;
  final String subtitle;
  final String route;
  final IconData icon;
  final Color tint;
}

/// Personalized home rail — orchestrates existing routes (seed heuristics).
final homeJourneyProvider = Provider<List<JourneyShortcut>>((ref) {
  return const [
    JourneyShortcut(
      title: 'Scan & pay',
      subtitle: 'Universal QR',
      route: '/scan',
      icon: LucideIcons.scanLine,
      tint: TaifaColors.ocean500,
    ),
    JourneyShortcut(
      title: 'Tap & Pay',
      subtitle: 'NFC contactless',
      route: '/tap',
      icon: LucideIcons.wifi,
      tint: TaifaColors.emerald600,
    ),
    JourneyShortcut(
      title: 'Book a ride',
      subtitle: 'Mobility',
      route: '/mobility',
      icon: LucideIcons.carTaxiFront,
      tint: TaifaColors.gold400,
    ),
    JourneyShortcut(
      title: 'Winga deals',
      subtitle: 'Marketplace',
      route: '/winga',
      icon: LucideIcons.shoppingBag,
      tint: TaifaColors.emerald500,
    ),
    JourneyShortcut(
      title: 'Pay merchant',
      subtitle: 'MAP',
      route: '/map/pay',
      icon: LucideIcons.store,
      tint: TaifaColors.ocean400,
    ),
    JourneyShortcut(
      title: 'Ask AI',
      subtitle: 'Assist only',
      route: '/ai',
      icon: LucideIcons.sparkles,
      tint: TaifaColors.violetSoft,
    ),
    JourneyShortcut(
      title: 'Orders & food',
      subtitle: 'Commerce',
      route: '/food',
      icon: LucideIcons.utensils,
      tint: TaifaColors.dangerSoft,
    ),
  ];
});

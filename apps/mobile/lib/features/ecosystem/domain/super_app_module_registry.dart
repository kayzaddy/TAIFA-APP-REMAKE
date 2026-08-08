import 'package:flutter/material.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../home/domain/home_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Visual + routing metadata for Super App modules (merged with API enablement).
class SuperAppModuleMeta {
  const SuperAppModuleMeta({
    required this.code,
    required this.name,
    required this.route,
    required this.category,
    required this.icon,
    required this.tint,
    this.subtitle = '',
    this.defaultEnabled = false,
    this.sortOrder = 100,
    this.showOnHome = true,
  });

  final String code;
  final String name;
  final String route;
  final String category;
  final IconData icon;
  final Color tint;
  final String subtitle;
  final bool defaultEnabled;
  final int sortOrder;
  final bool showOnHome;

  bool get isCore => category == 'core';
  bool get isOps => category == 'ops';
}

class EnabledSuperAppModule {
  const EnabledSuperAppModule({
    required this.meta,
    required this.enabled,
  });

  final SuperAppModuleMeta meta;
  final bool enabled;
}

/// Canonical module registry — mirrors backend `ecosystem/catalog.py` MODULES.
class SuperAppModuleRegistry {
  const SuperAppModuleRegistry._();

  static const _catalog = <SuperAppModuleMeta>[
    SuperAppModuleMeta(code: 'home', name: 'Home', route: '/home', category: 'core', icon: LucideIcons.house, tint: TaifaColors.emerald500, defaultEnabled: true, sortOrder: 1, showOnHome: false),
    SuperAppModuleMeta(code: 'wallet', name: 'Wallet', route: '/wallet', category: 'core', icon: LucideIcons.wallet, tint: TaifaColors.emerald500, defaultEnabled: true, sortOrder: 2, showOnHome: false),
    SuperAppModuleMeta(code: 'ai', name: 'AI', route: '/ai', category: 'core', icon: LucideIcons.sparkles, tint: TaifaColors.emerald500, defaultEnabled: true, sortOrder: 3, showOnHome: false),
    SuperAppModuleMeta(code: 'notifications', name: 'Notifications', route: '/notifications', category: 'core', icon: LucideIcons.bell, tint: TaifaColors.dangerSoft, defaultEnabled: true, sortOrder: 4, showOnHome: false),
    SuperAppModuleMeta(code: 'settings', name: 'Settings', route: '/settings', category: 'core', icon: LucideIcons.settings, tint: TaifaColors.gold400, defaultEnabled: true, sortOrder: 5, showOnHome: false),
    SuperAppModuleMeta(code: 'profile', name: 'Profile', route: '/profile', category: 'core', icon: LucideIcons.user, tint: TaifaColors.emerald500, defaultEnabled: true, sortOrder: 6, showOnHome: false),
    SuperAppModuleMeta(code: 'mobility', name: 'Ride', route: '/mobility', category: 'service', icon: LucideIcons.carTaxiFront, tint: TaifaColors.gold400, subtitle: 'Mobility', defaultEnabled: true, sortOrder: 10),
    SuperAppModuleMeta(code: 'food', name: 'Food', route: '/food', category: 'service', icon: LucideIcons.utensils, tint: TaifaColors.dangerSoft, subtitle: 'Delivery', defaultEnabled: true, sortOrder: 11),
    SuperAppModuleMeta(code: 'express', name: 'Express', route: '/express', category: 'service', icon: LucideIcons.zap, tint: TaifaColors.gold500, subtitle: 'Shopping list', defaultEnabled: true, sortOrder: 12),
    SuperAppModuleMeta(code: 'driver', name: 'Driver', route: '/driver', category: 'service', icon: LucideIcons.car, tint: TaifaColors.ocean400, subtitle: 'Jobs', defaultEnabled: false, sortOrder: 13, showOnHome: false),
    SuperAppModuleMeta(code: 'mobility_driver', name: 'Mobility Driver', route: '/mobility-driver', category: 'service', icon: LucideIcons.bike, tint: TaifaColors.gold400, subtitle: 'Station rides', defaultEnabled: false, sortOrder: 14, showOnHome: false),
    SuperAppModuleMeta(code: 'mobility_registry', name: 'Mobility Registry', route: '/mobility-registry', category: 'service', icon: LucideIcons.shieldCheck, tint: TaifaColors.emerald500, subtitle: 'Registration', defaultEnabled: false, sortOrder: 15, showOnHome: false),
    SuperAppModuleMeta(code: 'flights', name: 'Flights', route: '/flights', category: 'service', icon: LucideIcons.plane, tint: TaifaColors.violetSoft, subtitle: 'Tickets', defaultEnabled: false, sortOrder: 16),
    SuperAppModuleMeta(code: 'jobs', name: 'Jobs', route: '/jobs', category: 'service', icon: LucideIcons.briefcase, tint: TaifaColors.ocean400, subtitle: 'Logistics', defaultEnabled: false, sortOrder: 17, showOnHome: false),
    SuperAppModuleMeta(code: 'pay', name: 'Pay', route: '/pay', category: 'service', icon: LucideIcons.banknote, tint: TaifaColors.ocean500, subtitle: 'QR · send · top up', defaultEnabled: true, sortOrder: 20),
    SuperAppModuleMeta(code: 'tap', name: 'Tap & Pay', route: '/tap', category: 'service', icon: LucideIcons.wifi, tint: TaifaColors.emerald600, subtitle: 'NFC', defaultEnabled: false, sortOrder: 21),
    SuperAppModuleMeta(code: 'map', name: 'Accept', route: '/map', category: 'service', icon: LucideIcons.qrCode, tint: TaifaColors.ocean500, subtitle: 'MAP · QR', defaultEnabled: true, sortOrder: 22, showOnHome: false),
    SuperAppModuleMeta(code: 'winga', name: 'Winga', route: '/winga', category: 'service', icon: LucideIcons.shoppingBag, tint: TaifaColors.emerald500, subtitle: 'Brokerage', defaultEnabled: true, sortOrder: 23),
    SuperAppModuleMeta(code: 'commerce', name: 'Shop', route: '/commerce', category: 'service', icon: LucideIcons.store, tint: TaifaColors.emerald600, subtitle: 'Commerce MOS', defaultEnabled: true, sortOrder: 24),
    SuperAppModuleMeta(code: 'merchant', name: 'Merchant', route: '/merchant', category: 'service', icon: LucideIcons.store, tint: TaifaColors.gold400, subtitle: 'Kitchen', defaultEnabled: false, sortOrder: 25, showOnHome: false),
    SuperAppModuleMeta(code: 'stays', name: 'Hotels', route: '/stays', category: 'service', icon: LucideIcons.bed, tint: TaifaColors.ocean400, subtitle: 'Stays', defaultEnabled: false, sortOrder: 30),
    SuperAppModuleMeta(code: 'tourism', name: 'Tourism', route: '/tourism', category: 'service', icon: LucideIcons.mountain, tint: TaifaColors.gold400, subtitle: 'Experiences', defaultEnabled: false, sortOrder: 31),
    SuperAppModuleMeta(code: 'health', name: 'Health', route: '/health', category: 'service', icon: LucideIcons.briefcaseMedical, tint: TaifaColors.dangerSoft, subtitle: 'Clinics', defaultEnabled: false, sortOrder: 32),
    SuperAppModuleMeta(code: 'education', name: 'Educ.', route: '/education', category: 'service', icon: LucideIcons.graduationCap, tint: TaifaColors.violetSoft, subtitle: 'Fees', defaultEnabled: false, sortOrder: 33),
    SuperAppModuleMeta(code: 'agriculture', name: 'Agri', route: '/agriculture', category: 'service', icon: LucideIcons.sprout, tint: TaifaColors.emerald500, subtitle: 'Farms', defaultEnabled: false, sortOrder: 34),
    SuperAppModuleMeta(code: 'government', name: 'Gov', route: '/gov', category: 'service', icon: LucideIcons.landmark, tint: TaifaColors.ocean400, subtitle: 'Huduma', defaultEnabled: false, sortOrder: 35),
    SuperAppModuleMeta(code: 'housing', name: 'Home', route: '/housing', category: 'service', icon: LucideIcons.house, tint: TaifaColors.emerald500, subtitle: 'Rentals', defaultEnabled: false, sortOrder: 36),
    SuperAppModuleMeta(code: 'wealth', name: 'Wealth', route: '/wealth', category: 'service', icon: LucideIcons.piggyBank, tint: TaifaColors.gold400, subtitle: 'Harambee', defaultEnabled: false, sortOrder: 37, showOnHome: false),
    SuperAppModuleMeta(code: 'insurance', name: 'Insurance', route: '/insurance', category: 'service', icon: LucideIcons.shieldPlus, tint: TaifaColors.violetSoft, subtitle: 'Cover', defaultEnabled: false, sortOrder: 38, showOnHome: false),
    SuperAppModuleMeta(code: 'family', name: 'Family', route: '/family', category: 'service', icon: LucideIcons.users, tint: TaifaColors.gold400, subtitle: 'Shared wallet', defaultEnabled: false, sortOrder: 39, showOnHome: false),
    SuperAppModuleMeta(code: 'huduma', name: 'Huduma', route: '/huduma', category: 'service', icon: LucideIcons.wrench, tint: TaifaColors.ocean400, subtitle: 'Home services', defaultEnabled: false, sortOrder: 40, showOnHome: false),
    SuperAppModuleMeta(code: 'chat', name: 'Chat', route: '/chat', category: 'service', icon: LucideIcons.messageCircle, tint: TaifaColors.emerald500, subtitle: 'Social', defaultEnabled: false, sortOrder: 41, showOnHome: false),
    SuperAppModuleMeta(code: 'nfc', name: 'NFC', route: '/nfc', category: 'service', icon: LucideIcons.wifi, tint: TaifaColors.ocean400, subtitle: 'Translate', defaultEnabled: false, sortOrder: 42, showOnHome: false),
    SuperAppModuleMeta(code: 'search', name: 'Search', route: '/search', category: 'service', icon: LucideIcons.search, tint: TaifaColors.emerald500, subtitle: 'Discovery', defaultEnabled: true, sortOrder: 43, showOnHome: false),
    SuperAppModuleMeta(code: 'station_ops', name: 'Station Ops', route: '/station-ops', category: 'ops', icon: LucideIcons.store, tint: TaifaColors.emerald500, subtitle: 'Queue', defaultEnabled: false, sortOrder: 80, showOnHome: false),
    SuperAppModuleMeta(code: 'city_ops', name: 'City Ops', route: '/city-ops', category: 'ops', icon: LucideIcons.map, tint: TaifaColors.ocean400, subtitle: 'Map & SOS', defaultEnabled: false, sortOrder: 81, showOnHome: false),
    SuperAppModuleMeta(code: 'fleet_ops', name: 'Fleet Ops', route: '/fleet-ops', category: 'ops', icon: LucideIcons.truck, tint: TaifaColors.violetSoft, subtitle: 'Fleet intel', defaultEnabled: false, sortOrder: 82, showOnHome: false),
    SuperAppModuleMeta(code: 'regional_ops', name: 'Regional Ops', route: '/regional-ops', category: 'ops', icon: LucideIcons.landmark, tint: TaifaColors.gold400, subtitle: 'District', defaultEnabled: false, sortOrder: 83, showOnHome: false),
    SuperAppModuleMeta(code: 'national_ops', name: 'National Ops', route: '/national-ops', category: 'ops', icon: LucideIcons.globe, tint: TaifaColors.ocean400, subtitle: 'Command center', defaultEnabled: false, sortOrder: 84, showOnHome: false),
    SuperAppModuleMeta(code: 'ai_ops', name: 'AI Command', route: '/ai-ops', category: 'ops', icon: LucideIcons.brain, tint: TaifaColors.violetSoft, subtitle: 'Models & agents', defaultEnabled: false, sortOrder: 85, showOnHome: false),
    SuperAppModuleMeta(code: 'continental_ops', name: 'Continental Ops', route: '/continental-ops', category: 'ops', icon: LucideIcons.globe, tint: TaifaColors.emerald500, subtitle: 'Pan-African', defaultEnabled: false, sortOrder: 86, showOnHome: false),
    SuperAppModuleMeta(code: 'registry_admin', name: 'Registry Admin', route: '/mobility-registry/admin', category: 'ops', icon: LucideIcons.clipboardList, tint: TaifaColors.violetSoft, subtitle: 'Compliance', defaultEnabled: false, sortOrder: 87, showOnHome: false),
    SuperAppModuleMeta(code: 'admin', name: 'Admin', route: '/admin', category: 'ops', icon: LucideIcons.shieldCheck, tint: TaifaColors.violetSoft, subtitle: 'Platform', defaultEnabled: false, sortOrder: 88, showOnHome: false),
    SuperAppModuleMeta(code: 'ops', name: 'Ops', route: '/ops', category: 'ops', icon: LucideIcons.heartPulse, tint: TaifaColors.dangerSoft, subtitle: 'Live control', defaultEnabled: false, sortOrder: 89, showOnHome: false),
  ];

  static final Map<String, SuperAppModuleMeta> byCode = {
    for (final m in _catalog) m.code: m,
  };

  static SuperAppModuleMeta? metaForCode(String code) => byCode[code];

  static SuperAppModuleMeta metaForRoute(String route) {
    return _catalog.firstWhere(
      (m) => m.route == route,
      orElse: () => SuperAppModuleMeta(
        code: route,
        name: route,
        route: route,
        category: 'service',
        icon: LucideIcons.layoutGrid,
        tint: TaifaColors.ocean400,
      ),
    );
  }

  static List<EnabledSuperAppModule> fromApiRows(List<Map<String, dynamic>> rows) {
    final merged = <EnabledSuperAppModule>[];
    for (final row in rows) {
      final code = '${row['code'] ?? ''}';
      final meta = byCode[code];
      if (meta == null) continue;
      merged.add(
        EnabledSuperAppModule(
          meta: meta.copyWithName('${row['name'] ?? meta.name}'),
          enabled: row['enabled'] == true,
        ),
      );
    }
    for (final meta in _catalog) {
      if (merged.any((m) => m.meta.code == meta.code)) continue;
      merged.add(EnabledSuperAppModule(meta: meta, enabled: meta.defaultEnabled));
    }
    merged.sort((a, b) => a.meta.sortOrder.compareTo(b.meta.sortOrder));
    return merged;
  }

  static List<EnabledSuperAppModule> localDefaults() {
    return _catalog
        .map((m) => EnabledSuperAppModule(meta: m, enabled: m.defaultEnabled))
        .toList();
  }

  static List<ServiceItem> homeServices(List<EnabledSuperAppModule> modules) {
    final tiles = modules
        .where((m) => m.enabled && m.meta.category == 'service' && m.meta.showOnHome)
        .map(
          (m) => ServiceItem(
            id: m.meta.code,
            label: m.meta.name,
            icon: m.meta.icon,
            tint: m.meta.tint,
            route: m.meta.route,
          ),
        )
        .toList();
    tiles.addAll(const [
      ServiceItem(
        id: 'my_services',
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
    ]);
    return tiles;
  }

  static Set<String> enabledRoutes(List<EnabledSuperAppModule> modules) {
    return modules.where((m) => m.enabled).map((m) => m.meta.route).toSet();
  }
}

extension on SuperAppModuleMeta {
  SuperAppModuleMeta copyWithName(String name) {
    return SuperAppModuleMeta(
      code: code,
      name: name,
      route: route,
      category: category,
      icon: icon,
      tint: tint,
      subtitle: subtitle,
      defaultEnabled: defaultEnabled,
      sortOrder: sortOrder,
      showOnHome: showOnHome,
    );
  }
}

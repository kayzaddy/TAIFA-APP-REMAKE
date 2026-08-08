import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'shell/app_shell.dart';
import '../features/ai/presentation/ai_screen.dart';
import '../features/ai_ops/presentation/ai_ops_screen.dart';
import '../features/continental/presentation/continental_ops_screen.dart';
import '../features/chat/presentation/chat_screen.dart';
import '../features/driver/presentation/driver_screen.dart';
import '../features/education/presentation/education_screen.dart';
import '../features/flights/presentation/flights_screen.dart';
import '../features/food/presentation/food_screen.dart';
import '../features/gov/presentation/gov_screen.dart';
import '../features/health/presentation/health_screen.dart';
import '../features/hotels/presentation/hotels_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/housing/presentation/housing_screen.dart';
import '../features/jobs/presentation/jobs_screen.dart';
import '../features/menu/presentation/menu_screen.dart';
import '../features/taifa_merchant/merchant_routes.dart';
import '../features/commerce_mos/presentation/commerce_mos_hub_screen.dart';
import '../features/commerce_mos/presentation/onboarding/commerce_onboarding_screen.dart';
import '../features/commerce_mos/presentation/merchant/merchant_desk_app.dart';
import '../features/commerce_mos/presentation/pos/pos_app.dart';
import '../features/commerce_mos/presentation/warehouse/warehouse_app.dart';
import '../features/commerce_mos/presentation/procurement/procurement_app.dart';
import '../features/commerce_mos/presentation/customer/customer_shop_app.dart';
import '../features/commerce_mos/presentation/management/management_app.dart';
import '../features/merchant_acceptance/presentation/map_hub_screen.dart';
import '../features/merchant_acceptance/presentation/map_merchant_screen.dart';
import '../features/merchant_acceptance/presentation/map_customer_pay_screen.dart';
import '../features/super_app/presentation/universal_search_screen.dart';
import '../features/super_app/presentation/universal_qr_screen.dart';
import '../features/super_app/presentation/universal_pay_hub_screen.dart';
import '../features/tap_pay/presentation/tap_pay_screen.dart';
import '../features/tap_pay/presentation/tap_funding_screen.dart';
import '../features/express/presentation/express_hub_screen.dart';
import '../features/express/presentation/write_shopping_list_screen.dart';
import '../features/express/presentation/basket_review_screen.dart';
import '../features/express/presentation/express_track_screen.dart';
import '../features/city_ops/presentation/city_ops_screen.dart';
import '../features/fleet_ops/presentation/fleet_ops_screen.dart';
import '../features/mobility_driver/presentation/mobility_driver_screen.dart';
import '../features/mobility/presentation/mobility_screen.dart';
import '../features/mobility_transit/presentation/transit_admin_screen.dart';
import '../features/mobility_transit/presentation/transit_assistant_screen.dart';
import '../features/mobility_transit/presentation/transit_family_screen.dart';
import '../features/mobility_transit/presentation/transit_lost_found_screen.dart';
import '../features/mobility_transit/presentation/transit_live_map_screen.dart';
import '../features/mobility_transit/presentation/transit_home_screen.dart';
import '../features/mobility_transit/presentation/transit_notifications_screen.dart';
import '../features/mobility_transit/presentation/transit_planner_screen.dart';
import '../features/mobility_transit/presentation/transit_profile_screen.dart';
import '../features/mobility_transit/presentation/transit_qr_screen.dart';
import '../features/mobility_transit/presentation/transit_station_screen.dart';
import '../features/mobility_registry/presentation/registry_screen.dart';
import '../features/mobility_registry/presentation/registry_admin_screen.dart';
import '../features/national_ops/presentation/national_ops_screen.dart';
import '../features/nfc/presentation/nfc_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/regional_ops/presentation/regional_supervisor_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/station_ops/presentation/station_ops_screen.dart';
import '../features/tourism/presentation/tourism_screen.dart';
import '../features/wallet/presentation/send_money_screen.dart';
import '../features/wallet/presentation/top_up_screen.dart';
import '../features/wallet/presentation/wallet_screen.dart';
import '../features/wallet/presentation/social/contacts_screen.dart';
import '../features/wallet/presentation/social/money_requests_screen.dart';
import '../features/wallet/presentation/social/my_qr_screen.dart';
import '../features/wallet/presentation/social/payment_links_screen.dart';
import '../features/wallet/presentation/social/payment_notifications_screen.dart';
import '../features/wallet/presentation/social/payment_profile_screen.dart';
import '../features/wallet/presentation/social/recurring_payments_screen.dart';
import '../features/wallet/presentation/social/spending_analytics_screen.dart';
import '../features/wallet/presentation/social/spending_cap_screen.dart';
import '../features/wallet/presentation/social/split_bills_screen.dart';
import '../features/wallet/presentation/social/transaction_search_screen.dart';
import '../features/wealth/presentation/wealth_screen.dart';
import '../features/insurance/presentation/insurance_screen.dart';
import '../features/family/presentation/family_screen.dart';
import '../features/huduma/presentation/huduma_screen.dart';
import '../features/admin/presentation/admin_screen.dart';
import '../features/agriculture/presentation/agriculture_screen.dart';
import '../features/ops/presentation/ops_screen.dart';
import '../features/ecosystem/presentation/my_services_screen.dart';
import '../features/winga/presentation/winga_screen.dart';
import '../features/winga/presentation/winga_hub_screen.dart';
import '../features/winga/presentation/customer/customer_app.dart';
import '../features/winga/presentation/broker/broker_app.dart';
import '../features/winga/presentation/provider/provider_app.dart';
import '../features/winga/presentation/onboarding/onboarding_screen.dart';
import '../features/winga/presentation/opportunity/opportunity_feed_screen.dart';
import '../features/winga_property/presentation/winga_property_screen.dart';
import '../features/winga_property/presentation/winga_property_ops_console_screen.dart';

/// Central route table. Cold start lands on the animated splash; each primary
/// tab is a GoRouter branch so state and the back stack are preserved per tab.
class TaifaRouter {
  const TaifaRouter._();

  static final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  static final _homeKey = GlobalKey<NavigatorState>(debugLabel: 'home');
  static final _mobilityKey = GlobalKey<NavigatorState>(debugLabel: 'mobility');
  static final _aiKey = GlobalKey<NavigatorState>(debugLabel: 'ai');
  static final _walletKey = GlobalKey<NavigatorState>(debugLabel: 'wallet');
  static final _menuKey = GlobalKey<NavigatorState>(debugLabel: 'menu');

  static final GoRouter router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(
        path: '/food',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const FoodScreen(),
      ),
      GoRoute(
        path: '/stays',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const HotelsScreen(),
      ),
      GoRoute(
        path: '/flights',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const FlightsScreen(),
      ),
      GoRoute(
        path: '/tourism',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const TourismScreen(),
      ),
      GoRoute(
        path: '/nfc',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const NfcScreen(),
      ),
      GoRoute(
        path: '/profile',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/gov',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const GovScreen(),
      ),
      GoRoute(
        path: '/health',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const HealthScreen(),
      ),
      GoRoute(
        path: '/education',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const EducationScreen(),
      ),
      GoRoute(
        path: '/merchant',
        parentNavigatorKey: _rootKey,
        redirect: (_, __) => '/taifa-merchant/login',
      ),
      GoRoute(
        path: '/commerce',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const CommerceMosHubScreen(),
        routes: [
          GoRoute(
            path: 'onboarding',
            parentNavigatorKey: _rootKey,
            builder: (_, _) => const CommerceOnboardingScreen(),
          ),
          GoRoute(
            path: 'desk',
            parentNavigatorKey: _rootKey,
            builder: (_, _) => const CommerceMerchantDeskApp(),
          ),
          GoRoute(
            path: 'pos',
            parentNavigatorKey: _rootKey,
            builder: (_, _) => const CommercePosApp(),
          ),
          GoRoute(
            path: 'warehouse',
            parentNavigatorKey: _rootKey,
            builder: (_, _) => const CommerceWarehouseApp(),
          ),
          GoRoute(
            path: 'procurement',
            parentNavigatorKey: _rootKey,
            builder: (_, _) => const CommerceProcurementApp(),
          ),
          GoRoute(
            path: 'shop',
            parentNavigatorKey: _rootKey,
            builder: (_, _) => const CommerceCustomerApp(),
          ),
          GoRoute(
            path: 'management',
            parentNavigatorKey: _rootKey,
            builder: (_, _) => const CommerceManagementApp(),
          ),
        ],
      ),
      GoRoute(
        path: '/map',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const MapHubScreen(),
        routes: [
          GoRoute(
            path: 'merchant',
            parentNavigatorKey: _rootKey,
            builder: (_, _) => const MapMerchantScreen(),
          ),
          GoRoute(
            path: 'pay',
            parentNavigatorKey: _rootKey,
            builder: (context, state) => MapCustomerPayScreen(
              initialCode: state.extra is String
                  ? state.extra as String
                  : state.uri.queryParameters['code'],
            ),
          ),
          GoRoute(
            path: 'pay/:token',
            parentNavigatorKey: _rootKey,
            builder: (context, state) => MapCustomerPayScreen(
              initialCode: state.pathParameters['token'],
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/search',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => UniversalSearchScreen(
          initialQuery: state.extra is String
              ? state.extra as String
              : state.uri.queryParameters['q'],
        ),
      ),
      GoRoute(
        path: '/scan',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const UniversalQrScreen(),
      ),
      GoRoute(
        path: '/pay',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const UniversalPayHubScreen(),
      ),
      GoRoute(
        path: '/tap',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const TapPayScreen(),
        routes: [
          GoRoute(
            path: 'funding',
            parentNavigatorKey: _rootKey,
            builder: (_, _) => const TapFundingScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/express',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const ExpressHubScreen(),
        routes: [
          GoRoute(
            path: 'list',
            parentNavigatorKey: _rootKey,
            builder: (_, _) => const WriteShoppingListScreen(),
          ),
          GoRoute(
            path: 'basket',
            parentNavigatorKey: _rootKey,
            builder: (_, _) => const BasketReviewScreen(),
          ),
          GoRoute(
            path: 'track/:orderId',
            parentNavigatorKey: _rootKey,
            builder: (context, state) => ExpressTrackScreen(
              orderId: state.pathParameters['orderId'] ?? '',
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/driver',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const DriverScreen(),
      ),
      GoRoute(
        path: '/mobility-driver',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const MobilityDriverScreen(),
      ),
      GoRoute(
        path: '/mobility/transit',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const TransitHomeScreen(),
      ),
      GoRoute(
        path: '/mobility/transit/live',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const TransitLiveMapScreen(),
      ),
      GoRoute(
        path: '/mobility/transit/plan',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const TransitPlannerScreen(),
      ),
      GoRoute(
        path: '/mobility/transit/station/:stopCode',
        parentNavigatorKey: _rootKey,
        builder: (_, state) => TransitStationScreen(
          stopCode: state.pathParameters['stopCode'] ?? '',
        ),
      ),
      GoRoute(
        path: '/mobility/transit/ticket',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const TransitQrScreen(),
      ),
      GoRoute(
        path: '/mobility/transit/profile',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const TransitProfileScreen(),
      ),
      GoRoute(
        path: '/mobility/transit/notifications',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const TransitNotificationsScreen(),
      ),
      GoRoute(
        path: '/mobility/transit/admin',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const TransitAdminScreen(),
      ),
      GoRoute(
        path: '/mobility/transit/assistant',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const TransitAssistantScreen(),
      ),
      GoRoute(
        path: '/mobility/transit/family',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const TransitFamilyScreen(),
      ),
      GoRoute(
        path: '/mobility/transit/lost-found',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const TransitLostFoundScreen(),
      ),
      GoRoute(
        path: '/station-ops',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const StationOpsScreen(),
      ),
      GoRoute(
        path: '/city-ops',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const CityOpsScreen(),
      ),
      GoRoute(
        path: '/fleet-ops',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const FleetOpsScreen(),
      ),
      GoRoute(
        path: '/regional-ops',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const RegionalSupervisorScreen(),
      ),
      GoRoute(
        path: '/national-ops',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const NationalOpsScreen(),
      ),
      GoRoute(
        path: '/ai-ops',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const AiOpsScreen(),
      ),
      GoRoute(
        path: '/continental-ops',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const ContinentalOpsScreen(),
      ),
      GoRoute(
        path: '/my-services',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const MyServicesScreen(),
      ),      GoRoute(
        path: '/agriculture',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const AgricultureScreen(),
      ),
      GoRoute(
        path: '/mobility-registry',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const RegistryScreen(),
      ),
      GoRoute(
        path: '/mobility-registry/admin',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const RegistryAdminScreen(),
      ),
      GoRoute(
        path: '/chat',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const ChatScreen(),
      ),
      GoRoute(
        path: '/housing',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const HousingScreen(),
      ),
      GoRoute(
        path: '/winga-property',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const WingaPropertyScreen(),
      ),
      GoRoute(
        path: '/winga-property/ops',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const WingaPropertyOpsConsoleScreen(),
      ),
      GoRoute(
        path: '/wealth',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const WealthScreen(),
      ),
      GoRoute(
        path: '/jobs',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const JobsScreen(),
      ),
      GoRoute(
        path: '/insurance',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const InsuranceScreen(),
      ),
      GoRoute(
        path: '/family',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const FamilyScreen(),
      ),
      GoRoute(
        path: '/huduma',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const HudumaScreen(),
      ),
      GoRoute(
        path: '/admin',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const AdminScreen(),
      ),
      GoRoute(
        path: '/ops',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const OpsScreen(),
      ),
      GoRoute(
        path: '/winga',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const WingaHubScreen(),
        routes: [
          GoRoute(
            path: 'onboarding',
            parentNavigatorKey: _rootKey,
            builder: (_, _) => const WingaOnboardingScreen(),
          ),
          GoRoute(
            path: 'opportunities',
            parentNavigatorKey: _rootKey,
            builder: (_, _) => const WingaOpportunityFeedScreen(),
          ),
          GoRoute(
            path: 'customer',
            parentNavigatorKey: _rootKey,
            builder: (_, _) => const WingaCustomerApp(),
          ),
          GoRoute(
            path: 'broker',
            parentNavigatorKey: _rootKey,
            builder: (_, _) => const WingaBrokerApp(),
          ),
          GoRoute(
            path: 'provider',
            parentNavigatorKey: _rootKey,
            builder: (_, _) => const WingaProviderApp(),
          ),
          GoRoute(
            path: 'marketplace',
            parentNavigatorKey: _rootKey,
            builder: (_, _) => const WingaScreen(),
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _homeKey,
            routes: [
              GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _mobilityKey,
            routes: [
              GoRoute(
                path: '/mobility',
                builder: (_, _) => const MobilityScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _aiKey,
            routes: [
              GoRoute(
                path: '/ai',
                builder: (_, _) => const AiAssistantScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _walletKey,
            routes: [
              GoRoute(
                path: '/wallet',
                builder: (_, _) => const WalletScreen(),
                routes: [
                  GoRoute(
                    path: 'send',
                    parentNavigatorKey: _rootKey,
                    builder: (_, _) => const SendMoneyScreen(),
                  ),
                  GoRoute(
                    path: 'topup',
                    parentNavigatorKey: _rootKey,
                    builder: (_, _) => const TopUpScreen(),
                  ),
                  GoRoute(
                    path: 'links',
                    parentNavigatorKey: _rootKey,
                    builder: (_, _) => const PaymentLinksScreen(),
                  ),
                  GoRoute(
                    path: 'pay/:slug',
                    parentNavigatorKey: _rootKey,
                    builder: (_, state) => PayLinkScreen(slug: state.pathParameters['slug']!),
                  ),
                  GoRoute(
                    path: 'qr',
                    parentNavigatorKey: _rootKey,
                    builder: (_, _) => const MyQrScreen(),
                  ),
                  GoRoute(
                    path: 'requests',
                    parentNavigatorKey: _rootKey,
                    builder: (_, _) => const MoneyRequestsScreen(),
                  ),
                  GoRoute(
                    path: 'bills',
                    parentNavigatorKey: _rootKey,
                    builder: (_, _) => const SplitBillsScreen(),
                  ),
                  GoRoute(
                    path: 'bills/:billId',
                    parentNavigatorKey: _rootKey,
                    builder: (_, state) => BillDetailScreen(billId: state.pathParameters['billId']!),
                  ),
                  GoRoute(
                    path: 'recurring',
                    parentNavigatorKey: _rootKey,
                    builder: (_, _) => const RecurringPaymentsScreen(),
                  ),
                  GoRoute(
                    path: 'contacts',
                    parentNavigatorKey: _rootKey,
                    builder: (_, _) => const ContactsScreen(),
                  ),
                  GoRoute(
                    path: 'notifications',
                    parentNavigatorKey: _rootKey,
                    builder: (_, _) => const PaymentNotificationsScreen(),
                  ),
                  GoRoute(
                    path: 'history',
                    parentNavigatorKey: _rootKey,
                    builder: (_, _) => const TransactionSearchScreen(),
                  ),
                  GoRoute(
                    path: 'analytics',
                    parentNavigatorKey: _rootKey,
                    builder: (_, _) => const SpendingAnalyticsScreen(),
                  ),
                  GoRoute(
                    path: 'spending-cap',
                    parentNavigatorKey: _rootKey,
                    builder: (_, _) => const SpendingCapScreen(),
                  ),
                  GoRoute(
                    path: 'profile',
                    parentNavigatorKey: _rootKey,
                    builder: (_, _) => const PaymentProfileScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _menuKey,
            routes: [
              GoRoute(path: '/menu', builder: (_, _) => const MenuScreen()),
            ],
          ),
        ],
      ),
      ...taifaMerchantRoutes,
    ],
  );
}

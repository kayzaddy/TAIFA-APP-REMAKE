import 'package:go_router/go_router.dart';

import 'presentation/auth/merchant_login_screen.dart';
import 'presentation/auth/merchant_signup_screen.dart';
import 'presentation/branches/merchant_branches_screen.dart';
import 'presentation/dashboard/merchant_dashboard_screen.dart';
import 'presentation/devices/merchant_devices_screen.dart';
import 'presentation/employees/merchant_employees_screen.dart';
import 'presentation/notifications/merchant_notifications_screen.dart';
import 'presentation/payments/merchant_payment_links_screen.dart';
import 'presentation/payments/merchant_payments_hub_screen.dart';
import 'presentation/payments/merchant_qr_payments_screen.dart';
import 'presentation/payments/merchant_softpos_screen.dart';
import 'presentation/payments/merchant_transactions_screen.dart';
import 'presentation/profile/merchant_profile_screen.dart';
import 'presentation/settings/merchant_settings_screen.dart';
import 'presentation/shell/merchant_workspace_shell.dart';

List<RouteBase> taifaMerchantRoutes = [
  GoRoute(
    path: '/taifa-merchant/login',
    builder: (context, _) => const MerchantLoginScreen(),
  ),
  GoRoute(
    path: '/taifa-merchant/signup',
    builder: (context, _) => const MerchantSignupScreen(),
  ),
  GoRoute(
    path: '/taifa-merchant/register-business',
    builder: (context, _) => const MerchantRegisterBusinessScreen(),
  ),
  ShellRoute(
    builder: (context, state, child) => MerchantWorkspaceShell(child: child),
    routes: [
      GoRoute(
        path: '/taifa-merchant/dashboard',
        builder: (context, _) => const MerchantDashboardScreen(),
      ),
      GoRoute(
        path: '/taifa-merchant/profile',
        builder: (context, _) => const MerchantProfileScreen(),
      ),
      GoRoute(
        path: '/taifa-merchant/settings',
        builder: (context, _) => const MerchantSettingsScreen(),
      ),
      GoRoute(
        path: '/taifa-merchant/notifications',
        builder: (context, _) => const MerchantNotificationsScreen(),
      ),
    ],
  ),
  GoRoute(
    path: '/taifa-merchant/branches',
    builder: (context, _) => const MerchantBranchesScreen(),
  ),
  GoRoute(
    path: '/taifa-merchant/employees',
    builder: (context, _) => const MerchantEmployeesScreen(),
  ),
  GoRoute(
    path: '/taifa-merchant/devices',
    builder: (context, _) => const MerchantDevicesScreen(),
  ),
  GoRoute(
    path: '/taifa-merchant/payments',
    builder: (context, _) => const MerchantPaymentsHubScreen(),
  ),
  GoRoute(
    path: '/taifa-merchant/payments/softpos',
    builder: (context, _) => const MerchantSoftposScreen(),
  ),
  GoRoute(
    path: '/taifa-merchant/payments/qr',
    builder: (context, _) => const MerchantQrPaymentsScreen(),
  ),
  GoRoute(
    path: '/taifa-merchant/payments/links',
    builder: (context, _) => const MerchantPaymentLinksScreen(),
  ),
  GoRoute(
    path: '/taifa-merchant/payments/transactions',
    builder: (context, _) => const MerchantTransactionsScreen(),
  ),
  GoRoute(
    path: '/taifa-merchant/payments/analytics',
    builder: (context, _) => const MerchantPaymentAnalyticsScreen(),
  ),
];

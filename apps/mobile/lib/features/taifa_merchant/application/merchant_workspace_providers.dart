import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../core/merchant_api_client.dart';
import '../data/models/merchant_workspace_models.dart';

final merchantDashboardSnapshotProvider = FutureProvider.autoDispose<MerchantDashboardSnapshot>((ref) async {
  final raw = await ref.watch(merchantApiClientProvider).dashboard();
  final countsRaw = raw['counts'] as Map<String, dynamic>? ?? {};
  final notifications = (raw['notifications'] as List<dynamic>? ?? [])
      .map((e) => MerchantNotificationItem.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
  final timeline = (raw['activity_timeline'] as List<dynamic>? ?? [])
      .map((e) => MerchantActivityItem.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
  return MerchantDashboardSnapshot(
    businessStatus: raw['business_status']?.toString() ?? '',
    verificationStatus: raw['verification_status']?.toString() ?? '',
    merchantHealth: raw['merchant_health']?.toString() ?? '',
    counts: MerchantCounts(
      branches: countsRaw['branches'] as int? ?? 0,
      employees: countsRaw['employees'] as int? ?? 0,
      devices: countsRaw['devices'] as int? ?? 0,
    ),
    notifications: notifications,
    activityTimeline: timeline,
    pendingTasks: (raw['pending_tasks'] as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList(),
    placeholders: Map<String, dynamic>.from(raw['placeholders'] as Map? ?? {}),
    systemStatus: Map<String, dynamic>.from(raw['system_status'] as Map? ?? {}),
  );
});

final merchantSettingsProvider = FutureProvider.autoDispose<MerchantSettingsSnapshot>((ref) async {
  final raw = await ref.watch(merchantApiClientProvider).getSettings();
  return MerchantSettingsSnapshot.fromJson(raw);
});

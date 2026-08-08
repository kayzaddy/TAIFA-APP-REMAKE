import 'package:freezed_annotation/freezed_annotation.dart';

part 'merchant_workspace_models.freezed.dart';
part 'merchant_workspace_models.g.dart';

@freezed
abstract class MerchantCounts with _$MerchantCounts {
  const factory MerchantCounts({
    @Default(0) int branches,
    @Default(0) int employees,
    @Default(0) int devices,
  }) = _MerchantCounts;

  factory MerchantCounts.fromJson(Map<String, dynamic> json) => _$MerchantCountsFromJson(json);
}

@freezed
abstract class MerchantActivityItem with _$MerchantActivityItem {
  const factory MerchantActivityItem({
    required String id,
    @JsonKey(name: 'activity_type') required String activityType,
    required String summary,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _MerchantActivityItem;

  factory MerchantActivityItem.fromJson(Map<String, dynamic> json) =>
      _$MerchantActivityItemFromJson(json);
}

@freezed
abstract class MerchantNotificationItem with _$MerchantNotificationItem {
  const factory MerchantNotificationItem({
    required String id,
    required String category,
    required String title,
    @Default('') String body,
    @JsonKey(name: 'is_read') @Default(false) bool isRead,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _MerchantNotificationItem;

  factory MerchantNotificationItem.fromJson(Map<String, dynamic> json) =>
      _$MerchantNotificationItemFromJson(json);
}

@freezed
abstract class MerchantDashboardSnapshot with _$MerchantDashboardSnapshot {
  const factory MerchantDashboardSnapshot({
    @Default('') String businessStatus,
    @Default('') String verificationStatus,
    @Default('') String merchantHealth,
    MerchantCounts? counts,
    @Default([]) List<MerchantNotificationItem> notifications,
    @Default([]) List<MerchantActivityItem> activityTimeline,
    @Default([]) List<Map<String, dynamic>> pendingTasks,
    @Default({}) Map<String, dynamic> placeholders,
    @Default({}) Map<String, dynamic> systemStatus,
  }) = _MerchantDashboardSnapshot;

  factory MerchantDashboardSnapshot.fromJson(Map<String, dynamic> json) =>
      _$MerchantDashboardSnapshotFromJson(json);
}

@freezed
abstract class MerchantSettingsSnapshot with _$MerchantSettingsSnapshot {
  const factory MerchantSettingsSnapshot({
    @Default('sw') String language,
    @Default('TZS') String currency,
    @Default('Africa/Dar_es_Salaam') String timezone,
    @JsonKey(name: 'payment_preferences') @Default({}) Map<String, dynamic> paymentPreferences,
    @JsonKey(name: 'receipt_branding') @Default({}) Map<String, dynamic> receiptBranding,
    @JsonKey(name: 'tax_settings') @Default({}) Map<String, dynamic> taxSettings,
  }) = _MerchantSettingsSnapshot;

  factory MerchantSettingsSnapshot.fromJson(Map<String, dynamic> json) =>
      _$MerchantSettingsSnapshotFromJson(json);
}

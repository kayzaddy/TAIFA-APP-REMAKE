// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'merchant_workspace_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MerchantCounts _$MerchantCountsFromJson(Map<String, dynamic> json) =>
    _MerchantCounts(
      branches: (json['branches'] as num?)?.toInt() ?? 0,
      employees: (json['employees'] as num?)?.toInt() ?? 0,
      devices: (json['devices'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$MerchantCountsToJson(_MerchantCounts instance) =>
    <String, dynamic>{
      'branches': instance.branches,
      'employees': instance.employees,
      'devices': instance.devices,
    };

_MerchantActivityItem _$MerchantActivityItemFromJson(
  Map<String, dynamic> json,
) => _MerchantActivityItem(
  id: json['id'] as String,
  activityType: json['activity_type'] as String,
  summary: json['summary'] as String,
  createdAt: json['created_at'] as String?,
);

Map<String, dynamic> _$MerchantActivityItemToJson(
  _MerchantActivityItem instance,
) => <String, dynamic>{
  'id': instance.id,
  'activity_type': instance.activityType,
  'summary': instance.summary,
  'created_at': instance.createdAt,
};

_MerchantNotificationItem _$MerchantNotificationItemFromJson(
  Map<String, dynamic> json,
) => _MerchantNotificationItem(
  id: json['id'] as String,
  category: json['category'] as String,
  title: json['title'] as String,
  body: json['body'] as String? ?? '',
  isRead: json['is_read'] as bool? ?? false,
  createdAt: json['created_at'] as String?,
);

Map<String, dynamic> _$MerchantNotificationItemToJson(
  _MerchantNotificationItem instance,
) => <String, dynamic>{
  'id': instance.id,
  'category': instance.category,
  'title': instance.title,
  'body': instance.body,
  'is_read': instance.isRead,
  'created_at': instance.createdAt,
};

_MerchantDashboardSnapshot _$MerchantDashboardSnapshotFromJson(
  Map<String, dynamic> json,
) => _MerchantDashboardSnapshot(
  businessStatus: json['businessStatus'] as String? ?? '',
  verificationStatus: json['verificationStatus'] as String? ?? '',
  merchantHealth: json['merchantHealth'] as String? ?? '',
  counts: json['counts'] == null
      ? null
      : MerchantCounts.fromJson(json['counts'] as Map<String, dynamic>),
  notifications:
      (json['notifications'] as List<dynamic>?)
          ?.map(
            (e) => MerchantNotificationItem.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const [],
  activityTimeline:
      (json['activityTimeline'] as List<dynamic>?)
          ?.map((e) => MerchantActivityItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  pendingTasks:
      (json['pendingTasks'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ??
      const [],
  placeholders: json['placeholders'] as Map<String, dynamic>? ?? const {},
  systemStatus: json['systemStatus'] as Map<String, dynamic>? ?? const {},
);

Map<String, dynamic> _$MerchantDashboardSnapshotToJson(
  _MerchantDashboardSnapshot instance,
) => <String, dynamic>{
  'businessStatus': instance.businessStatus,
  'verificationStatus': instance.verificationStatus,
  'merchantHealth': instance.merchantHealth,
  'counts': instance.counts,
  'notifications': instance.notifications,
  'activityTimeline': instance.activityTimeline,
  'pendingTasks': instance.pendingTasks,
  'placeholders': instance.placeholders,
  'systemStatus': instance.systemStatus,
};

_MerchantSettingsSnapshot _$MerchantSettingsSnapshotFromJson(
  Map<String, dynamic> json,
) => _MerchantSettingsSnapshot(
  language: json['language'] as String? ?? 'sw',
  currency: json['currency'] as String? ?? 'TZS',
  timezone: json['timezone'] as String? ?? 'Africa/Dar_es_Salaam',
  paymentPreferences:
      json['payment_preferences'] as Map<String, dynamic>? ?? const {},
  receiptBranding:
      json['receipt_branding'] as Map<String, dynamic>? ?? const {},
  taxSettings: json['tax_settings'] as Map<String, dynamic>? ?? const {},
);

Map<String, dynamic> _$MerchantSettingsSnapshotToJson(
  _MerchantSettingsSnapshot instance,
) => <String, dynamic>{
  'language': instance.language,
  'currency': instance.currency,
  'timezone': instance.timezone,
  'payment_preferences': instance.paymentPreferences,
  'receipt_branding': instance.receiptBranding,
  'tax_settings': instance.taxSettings,
};

class TapFundingSource {
  const TapFundingSource({
    required this.kind,
    required this.ref,
    required this.label,
    this.enabled = true,
    this.available = true,
    this.reason = '',
    this.balanceMinor,
  });

  final String kind;
  final String ref;
  final String label;
  final bool enabled;
  final bool available;
  final String reason;
  final int? balanceMinor;

  factory TapFundingSource.fromJson(Map<String, dynamic> m) => TapFundingSource(
        kind: m['kind']?.toString() ?? 'wallet',
        ref: m['ref']?.toString() ?? '',
        label: m['label']?.toString() ?? '',
        enabled: m['enabled'] != false,
        available: m['available'] != false,
        reason: m['reason']?.toString() ?? '',
        balanceMinor: (m['balance_minor'] as num?)?.toInt(),
      );
}

class TapFundingPrefs {
  const TapFundingPrefs({
    required this.priority,
    this.autoRoute = true,
    this.requireConfirmation = false,
    this.authPolicy = 'risk_based',
    this.lowRiskThresholdMinor = 50000,
  });

  final List<TapFundingSource> priority;
  final bool autoRoute;
  final bool requireConfirmation;
  final String authPolicy;
  final int lowRiskThresholdMinor;

  factory TapFundingPrefs.fromJson(Map<String, dynamic> m) {
    final raw = m['priority'] as List? ?? [];
    return TapFundingPrefs(
      priority: raw
          .whereType<Map>()
          .map((e) => TapFundingSource.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      autoRoute: m['auto_route'] != false,
      requireConfirmation: m['require_confirmation'] == true,
      authPolicy: m['auth_policy']?.toString() ?? 'risk_based',
      lowRiskThresholdMinor: (m['low_risk_threshold_minor'] as num?)?.toInt() ?? 50000,
    );
  }
}

class TapSession {
  const TapSession({
    required this.publicCode,
    required this.status,
    required this.amountMinor,
    required this.merchantDisplay,
    this.currency = 'TZS',
    this.channel = 'nfc',
    this.authRequired = true,
    this.authCompleted = false,
    this.paymentRef = '',
    this.receiptCode = '',
    this.failureReason = '',
    this.selectedFunding,
    this.intentCode = '',
  });

  final String publicCode;
  final String status;
  final int amountMinor;
  final String currency;
  final String channel;
  final String merchantDisplay;
  final bool authRequired;
  final bool authCompleted;
  final String paymentRef;
  final String receiptCode;
  final String failureReason;
  final TapFundingSource? selectedFunding;
  final String intentCode;

  bool get isSuccess => status == 'succeeded';
  bool get needsAuth => authRequired && !authCompleted;

  factory TapSession.fromJson(Map<String, dynamic> m) {
    final funding = m['selected_funding'];
    return TapSession(
      publicCode: m['public_code']?.toString() ?? '',
      status: m['status']?.toString() ?? 'detected',
      amountMinor: (m['amount_minor'] as num?)?.toInt() ?? 0,
      currency: m['currency']?.toString() ?? 'TZS',
      channel: m['channel']?.toString() ?? 'nfc',
      merchantDisplay: m['merchant_display']?.toString() ?? '',
      authRequired: m['auth_required'] == true,
      authCompleted: m['auth_completed'] == true,
      paymentRef: m['payment_ref']?.toString() ?? '',
      receiptCode: m['receipt_code']?.toString() ?? '',
      failureReason: m['failure_reason']?.toString() ?? '',
      intentCode: m['intent_code']?.toString() ?? '',
      selectedFunding: funding is Map
          ? TapFundingSource.fromJson(Map<String, dynamic>.from(funding))
          : null,
    );
  }
}

class TapStartResult {
  const TapStartResult({required this.session, this.routing});

  final TapSession session;
  final Map<String, dynamic>? routing;
}

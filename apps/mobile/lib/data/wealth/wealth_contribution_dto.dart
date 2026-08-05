import '../../features/wallet/domain/currency.dart';
import '../../features/wallet/domain/money.dart';
import '../../features/wealth/data/wealth_catalog.dart';
import '../../features/wealth/domain/wealth_models.dart';

/// Maps `/api/v1/commerce/wealth-contributions` JSON ↔ domain [WealthContribution].
class WealthContributionDto {
  const WealthContributionDto._();

  static WealthContribution toDomain(
    Map<String, dynamic> json, {
    HarambeeCircle? circle,
  }) {
    final currency = Currency.fromCode(json['currency'] as String? ?? 'TZS');
    final circleId = json['circle_id'] as String? ?? '';
    final amount = Money(
      (json['amount_minor'] as num?)?.toInt() ?? 0,
      currency,
    );
    final pay = (json['payment_ref'] as String?)?.trim();

    return WealthContribution(
      id: json['id'].toString(),
      circle:
          circle ??
          _resolveCircle(
            circleId,
            json['circle_name'] as String? ?? 'Circle',
            json['purpose'] as String? ?? '',
            amount,
          ),
      amount: amount,
      status: statusFromApi(json['status'] as String? ?? 'paid'),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      paymentRef: (pay == null || pay.isEmpty) ? null : pay,
    );
  }

  static Map<String, dynamic> createBody(WealthContribution draft) => {
    'circle_id': draft.circle.id,
    'circle_name': draft.circle.name,
    'purpose': draft.circle.purpose,
    'amount_minor': draft.amount.minorUnits,
    'currency': draft.amount.currency.code,
    'status': statusToApi(draft.status),
    if (draft.paymentRef != null && draft.paymentRef!.isNotEmpty)
      'payment_ref': draft.paymentRef,
  };

  static String statusToApi(ContributionStatus status) => switch (status) {
    ContributionStatus.drafting || ContributionStatus.confirmed => 'confirmed',
    ContributionStatus.paid => 'paid',
  };

  static ContributionStatus statusFromApi(String raw) => switch (raw) {
    'confirmed' => ContributionStatus.confirmed,
    _ => ContributionStatus.paid,
  };

  static HarambeeCircle _resolveCircle(
    String id,
    String name,
    String purpose,
    Money amount,
  ) {
    try {
      return WealthCatalog.circles().firstWhere((c) => c.id == id);
    } catch (_) {
      return HarambeeCircle(
        id: id.isEmpty ? 'hrb-unknown' : id,
        name: name,
        purpose: purpose,
        target: amount,
        raised: amount,
        members: 1,
      );
    }
  }
}

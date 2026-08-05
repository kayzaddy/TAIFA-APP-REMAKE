import '../../wallet/domain/currency.dart';
import '../../wallet/domain/money.dart';
import 'tourism_connectivity_models.dart';

/// Travel insurance offer shown at tourism checkout (TAIFA-TOUR-006).
class TourismTravelInsuranceQuote {
  const TourismTravelInsuranceQuote({
    required this.planId,
    required this.planName,
    required this.provider,
    required this.premiumMinor,
    required this.coverageMinor,
    this.currency = 'TZS',
  });

  final String planId;
  final String planName;
  final String provider;
  final int premiumMinor;
  final int coverageMinor;
  final String currency;

  Money get premium => Money(premiumMinor, Currency.tzs);

  factory TourismTravelInsuranceQuote.fromJson(Map<String, dynamic> json) =>
      TourismTravelInsuranceQuote(
        planId: '${json['plan_id']}',
        planName: '${json['plan_name']}',
        provider: '${json['provider'] ?? ''}',
        premiumMinor: (json['premium_minor'] as num?)?.toInt() ?? 0,
        coverageMinor: (json['coverage_minor'] as num?)?.toInt() ?? 0,
        currency: '${json['currency'] ?? 'TZS'}',
      );
}

class TourismCartLine {
  const TourismCartLine({
    required this.section,
    required this.kind,
    required this.refId,
    required this.title,
    required this.amountMinor,
    required this.currency,
    this.paid = false,
    this.optional = false,
    this.provider = '',
  });

  final String section;
  final String kind;
  final String refId;
  final String title;
  final int amountMinor;
  final String currency;
  final bool paid;
  final bool optional;
  final String provider;

  Money get amount => Money(amountMinor, Currency.tzs);

  factory TourismCartLine.fromJson(Map<String, dynamic> json) => TourismCartLine(
        section: '${json['section']}',
        kind: '${json['kind']}',
        refId: '${json['ref_id']}',
        title: '${json['title']}',
        amountMinor: (json['amount_minor'] as num?)?.toInt() ?? 0,
        currency: '${json['currency'] ?? 'TZS'}',
        paid: json['paid'] == true,
        optional: json['optional'] == true,
        provider: '${json['provider'] ?? ''}',
      );
}

class TourismCart {
  const TourismCart({
    required this.tripId,
    required this.lines,
    required this.travelSubtotalMinor,
    required this.protectionSubtotalMinor,
    required this.totalMinor,
    this.insuranceQuote,
    this.esimQuote,
    this.connectivitySubtotalMinor = 0,
    this.currency = 'TZS',
  });

  final String tripId;
  final List<TourismCartLine> lines;
  final int travelSubtotalMinor;
  final int protectionSubtotalMinor;
  final int totalMinor;
  final TourismTravelInsuranceQuote? insuranceQuote;
  final TourismEsimQuote? esimQuote;
  final int connectivitySubtotalMinor;
  final String currency;

  List<TourismCartLine> get travelLines =>
      lines.where((l) => l.section == 'travel').toList();

  factory TourismCart.fromJson(Map<String, dynamic> json) => TourismCart(
        tripId: '${json['trip_id']}',
        lines: (json['lines'] as List?)
                ?.whereType<Map>()
                .map((e) => TourismCartLine.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            const [],
        travelSubtotalMinor: (json['travel_subtotal_minor'] as num?)?.toInt() ?? 0,
        protectionSubtotalMinor:
            (json['protection_subtotal_minor'] as num?)?.toInt() ?? 0,
        connectivitySubtotalMinor:
            (json['connectivity_subtotal_minor'] as num?)?.toInt() ?? 0,
        totalMinor: (json['total_minor'] as num?)?.toInt() ?? 0,
        insuranceQuote: json['insurance_quote'] is Map
            ? TourismTravelInsuranceQuote.fromJson(
                Map<String, dynamic>.from(json['insurance_quote'] as Map),
              )
            : null,
        esimQuote: json['esim_quote'] is Map
            ? TourismEsimQuote.fromJson(
                Map<String, dynamic>.from(json['esim_quote'] as Map),
              )
            : null,
        currency: '${json['currency'] ?? 'TZS'}',
      );
}

class TourismCheckout {
  const TourismCheckout({
    required this.id,
    required this.tripId,
    required this.status,
    required this.includeInsurance,
    required this.lines,
    required this.travelSubtotalMinor,
    required this.protectionSubtotalMinor,
    required this.totalMinor,
    this.includeEsim = false,
    this.connectivitySubtotalMinor = 0,
    this.insurancePolicyId,
    this.esimOrderId,
    this.esimActivation,
    this.paymentRef,
    this.currency = 'TZS',
  });

  final String id;
  final String tripId;
  final String status;
  final bool includeInsurance;
  final bool includeEsim;
  final List<TourismCartLine> lines;
  final int travelSubtotalMinor;
  final int protectionSubtotalMinor;
  final int connectivitySubtotalMinor;
  final int totalMinor;
  final String? insurancePolicyId;
  final String? esimOrderId;
  final TourismEsimActivation? esimActivation;
  final String? paymentRef;
  final String currency;

  bool get isPaid => status == 'paid';

  Money get total => Money(totalMinor, Currency.tzs);

  factory TourismCheckout.fromJson(Map<String, dynamic> json) => TourismCheckout(
        id: '${json['id']}',
        tripId: '${json['trip_id']}',
        status: '${json['status']}',
        includeInsurance: json['include_insurance'] == true,
        includeEsim: json['include_esim'] == true,
        lines: (json['lines'] as List?)
                ?.whereType<Map>()
                .map((e) => TourismCartLine.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            const [],
        travelSubtotalMinor: (json['travel_subtotal_minor'] as num?)?.toInt() ?? 0,
        protectionSubtotalMinor:
            (json['protection_subtotal_minor'] as num?)?.toInt() ?? 0,
        connectivitySubtotalMinor:
            (json['connectivity_subtotal_minor'] as num?)?.toInt() ?? 0,
        totalMinor: (json['total_minor'] as num?)?.toInt() ?? 0,
        insurancePolicyId: json['insurance_policy_id']?.toString(),
        esimOrderId: json['esim_order_id']?.toString(),
        paymentRef: json['payment_ref']?.toString(),
        currency: '${json['currency'] ?? 'TZS'}',
      );
}

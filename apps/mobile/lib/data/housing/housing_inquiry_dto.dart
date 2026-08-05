import '../../features/housing/data/housing_catalog.dart';
import '../../features/housing/domain/housing_models.dart';
import '../../features/wallet/domain/currency.dart';
import '../../features/wallet/domain/money.dart';

/// Maps `/api/v1/commerce/housing-inquiries` JSON ↔ domain [HousingInquiry].
class HousingInquiryDto {
  const HousingInquiryDto._();

  static HousingInquiry toDomain(
    Map<String, dynamic> json, {
    HousingListing? listing,
  }) {
    final currency = Currency.fromCode(json['currency'] as String? ?? 'TZS');
    final listingId = json['listing_id'] as String? ?? '';
    final rent = Money(
      (json['monthly_rent_minor'] as num?)?.toInt() ?? 0,
      currency,
    );
    final deposit = Money(
      (json['deposit_minor'] as num?)?.toInt() ?? 0,
      currency,
    );
    final pay = (json['payment_ref'] as String?)?.trim();
    final viewingRaw = json['viewing_at'] as String?;

    return HousingInquiry(
      id: json['id'].toString(),
      listing:
          listing ??
          _resolveListing(
            listingId,
            json['listing_title'] as String? ?? 'Listing',
            json['area'] as String? ?? '',
            (json['beds'] as num?)?.toInt() ?? 1,
            (json['baths'] as num?)?.toInt() ?? 1,
            rent,
            deposit,
          ),
      status: statusFromApi(json['status'] as String? ?? 'scheduled'),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      viewingAt: viewingRaw == null || viewingRaw.isEmpty
          ? null
          : DateTime.tryParse(viewingRaw),
      paymentRef: (pay == null || pay.isEmpty) ? null : pay,
    );
  }

  static Map<String, dynamic> createBody(HousingInquiry draft) => {
    'listing_id': draft.listing.id,
    'listing_title': draft.listing.title,
    'area': draft.listing.area,
    'beds': draft.listing.beds,
    'baths': draft.listing.baths,
    'monthly_rent_minor': draft.listing.monthlyRent.minorUnits,
    'deposit_minor': draft.listing.deposit.minorUnits,
    'currency': draft.listing.deposit.currency.code,
    if (draft.viewingAt != null)
      'viewing_at': draft.viewingAt!.toUtc().toIso8601String(),
  };

  static Map<String, dynamic> patchBody(HousingInquiry inquiry) {
    final body = <String, dynamic>{'status': statusToApi(inquiry.status)};
    if (inquiry.viewingAt != null) {
      body['viewing_at'] = inquiry.viewingAt!.toUtc().toIso8601String();
    }
    return body;
  }

  static String statusToApi(HousingInquiryStatus status) => switch (status) {
    HousingInquiryStatus.drafting ||
    HousingInquiryStatus.submitted => 'submitted',
    HousingInquiryStatus.scheduled => 'scheduled',
    HousingInquiryStatus.depositPaid => 'deposit_paid',
    HousingInquiryStatus.cancelled => 'cancelled',
  };

  static HousingInquiryStatus statusFromApi(String raw) => switch (raw) {
    'submitted' => HousingInquiryStatus.submitted,
    'deposit_paid' => HousingInquiryStatus.depositPaid,
    'cancelled' => HousingInquiryStatus.cancelled,
    _ => HousingInquiryStatus.scheduled,
  };

  static HousingListing _resolveListing(
    String id,
    String title,
    String area,
    int beds,
    int baths,
    Money rent,
    Money deposit,
  ) {
    try {
      return HousingCatalog.all().firstWhere((l) => l.id == id);
    } catch (_) {
      return HousingListing(
        id: id.isEmpty ? 'hs-unknown' : id,
        title: title,
        area: area,
        beds: beds,
        baths: baths,
        monthlyRent: rent,
        deposit: deposit,
        tagline: '',
      );
    }
  }
}

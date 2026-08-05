import '../../wallet/domain/money.dart';

class HousingListing {
  const HousingListing({
    required this.id,
    required this.title,
    required this.area,
    required this.beds,
    required this.baths,
    required this.monthlyRent,
    required this.deposit,
    required this.tagline,
  });

  final String id;
  final String title;
  final String area;
  final int beds;
  final int baths;
  final Money monthlyRent;
  final Money deposit;
  final String tagline;
}

enum HousingInquiryStatus {
  drafting,
  submitted,
  scheduled,
  depositPaid,
  cancelled,
}

extension HousingInquiryStatusX on HousingInquiryStatus {
  String get label => switch (this) {
    HousingInquiryStatus.drafting => 'Draft',
    HousingInquiryStatus.submitted => 'Submitted',
    HousingInquiryStatus.scheduled => 'Viewing scheduled',
    HousingInquiryStatus.depositPaid => 'Deposit paid',
    HousingInquiryStatus.cancelled => 'Cancelled',
  };
}

class HousingInquiry {
  const HousingInquiry({
    required this.id,
    required this.listing,
    required this.status,
    required this.createdAt,
    this.viewingAt,
    this.paymentRef,
  });

  final String id;
  final HousingListing listing;
  final HousingInquiryStatus status;
  final DateTime createdAt;
  final DateTime? viewingAt;
  final String? paymentRef;

  HousingInquiry copyWith({
    HousingInquiryStatus? status,
    DateTime? viewingAt,
    String? paymentRef,
  }) {
    return HousingInquiry(
      id: id,
      listing: listing,
      status: status ?? this.status,
      createdAt: createdAt,
      viewingAt: viewingAt ?? this.viewingAt,
      paymentRef: paymentRef ?? this.paymentRef,
    );
  }
}

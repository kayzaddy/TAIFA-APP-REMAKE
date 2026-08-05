import '../../wallet/domain/money.dart';

class TourExperience {
  const TourExperience({
    required this.id,
    required this.title,
    required this.region,
    required this.durationLabel,
    required this.rating,
    required this.price,
    required this.highlights,
    required this.imageTone,
    this.featured = false,
    this.tagline = '',
  });

  final String id;
  final String title;
  final String region;
  final String durationLabel;
  final double rating;
  final Money price;
  final List<String> highlights;
  final int imageTone;
  final bool featured;
  final String tagline;
}

enum TourBookingStatus { drafting, reserved, confirmed, paid, cancelled }

extension TourBookingStatusX on TourBookingStatus {
  String get label => switch (this) {
    TourBookingStatus.drafting => 'Draft',
    TourBookingStatus.reserved => 'Reserved',
    TourBookingStatus.confirmed => 'Confirmed',
    TourBookingStatus.paid => 'Paid',
    TourBookingStatus.cancelled => 'Cancelled',
  };
}

class TourBooking {
  const TourBooking({
    required this.id,
    required this.tour,
    required this.guests,
    required this.date,
    required this.total,
    required this.status,
    required this.createdAt,
    this.confirmationCode,
    this.paymentRef,
  });

  final String id;
  final TourExperience tour;
  final int guests;
  final DateTime date;
  final Money total;
  final TourBookingStatus status;
  final DateTime createdAt;
  final String? confirmationCode;
  final String? paymentRef;

  TourBooking copyWith({
    TourBookingStatus? status,
    String? confirmationCode,
    String? paymentRef,
  }) {
    return TourBooking(
      id: id,
      tour: tour,
      guests: guests,
      date: date,
      total: total,
      status: status ?? this.status,
      createdAt: createdAt,
      confirmationCode: confirmationCode ?? this.confirmationCode,
      paymentRef: paymentRef ?? this.paymentRef,
    );
  }
}

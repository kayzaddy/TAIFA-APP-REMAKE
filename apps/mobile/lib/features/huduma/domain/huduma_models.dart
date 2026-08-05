import '../../wallet/domain/money.dart';

class HudumaService {
  const HudumaService({
    required this.id,
    required this.title,
    required this.category,
    required this.provider,
    required this.price,
    required this.etaLabel,
    required this.rating,
  });

  final String id;
  final String title;
  final String category;
  final String provider;
  final Money price;
  final String etaLabel;
  final double rating;
}

enum HudumaBookingStatus { drafting, scheduled, paid }

extension HudumaBookingStatusX on HudumaBookingStatus {
  String get label => switch (this) {
    HudumaBookingStatus.drafting => 'Draft',
    HudumaBookingStatus.scheduled => 'Scheduled',
    HudumaBookingStatus.paid => 'Paid',
  };
}

class HudumaBooking {
  const HudumaBooking({
    required this.id,
    required this.service,
    required this.status,
    required this.slotLabel,
    required this.createdAt,
    this.paymentRef,
  });

  final String id;
  final HudumaService service;
  final HudumaBookingStatus status;
  final String slotLabel;
  final DateTime createdAt;
  final String? paymentRef;

  HudumaBooking copyWith({HudumaBookingStatus? status, String? paymentRef}) {
    return HudumaBooking(
      id: id,
      service: service,
      status: status ?? this.status,
      slotLabel: slotLabel,
      createdAt: createdAt,
      paymentRef: paymentRef ?? this.paymentRef,
    );
  }
}

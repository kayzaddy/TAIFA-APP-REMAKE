import '../../wallet/domain/money.dart';

class Airport {
  const Airport({required this.code, required this.city, required this.name});
  final String code;
  final String city;
  final String name;
}

class FlightOffer {
  const FlightOffer({
    required this.id,
    required this.airline,
    required this.flightNumber,
    required this.origin,
    required this.destination,
    required this.departAt,
    required this.arriveAt,
    required this.durationMinutes,
    required this.price,
    this.cabin = 'Economy',
    this.stops = 0,
    this.popular = false,
  });

  final String id;
  final String airline;
  final String flightNumber;
  final Airport origin;
  final Airport destination;
  final DateTime departAt;
  final DateTime arriveAt;
  final int durationMinutes;
  final Money price;
  final String cabin;
  final int stops;
  final bool popular;
}

enum FlightBookingStatus { drafting, held, ticketed, paid, cancelled }

extension FlightBookingStatusX on FlightBookingStatus {
  String get label => switch (this) {
    FlightBookingStatus.drafting => 'Draft',
    FlightBookingStatus.held => 'Seat held',
    FlightBookingStatus.ticketed => 'Ticketed',
    FlightBookingStatus.paid => 'Paid',
    FlightBookingStatus.cancelled => 'Cancelled',
  };
}

class FlightBooking {
  const FlightBooking({
    required this.id,
    required this.offer,
    required this.passengers,
    required this.total,
    required this.status,
    required this.createdAt,
    this.pnr,
    this.paymentRef,
  });

  final String id;
  final FlightOffer offer;
  final int passengers;
  final Money total;
  final FlightBookingStatus status;
  final DateTime createdAt;
  final String? pnr;
  final String? paymentRef;

  FlightBooking copyWith({
    FlightBookingStatus? status,
    String? pnr,
    String? paymentRef,
  }) {
    return FlightBooking(
      id: id,
      offer: offer,
      passengers: passengers,
      total: total,
      status: status ?? this.status,
      createdAt: createdAt,
      pnr: pnr ?? this.pnr,
      paymentRef: paymentRef ?? this.paymentRef,
    );
  }
}

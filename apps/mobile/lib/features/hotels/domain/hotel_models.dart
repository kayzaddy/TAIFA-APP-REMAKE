import '../../wallet/domain/money.dart';

class RoomType {
  const RoomType({
    required this.id,
    required this.name,
    required this.description,
    required this.nightlyRate,
    required this.maxGuests,
    required this.amenities,
    this.popular = false,
  });

  final String id;
  final String name;
  final String description;
  final Money nightlyRate;
  final int maxGuests;
  final List<String> amenities;
  final bool popular;
}

class Hotel {
  const Hotel({
    required this.id,
    required this.name,
    required this.area,
    required this.rating,
    required this.stars,
    required this.fromNightly,
    required this.imageTone,
    required this.rooms,
    this.featured = false,
    this.tagline = '',
  });

  final String id;
  final String name;
  final String area;
  final double rating;
  final int stars;
  final Money fromNightly;
  final int imageTone;
  final List<RoomType> rooms;
  final bool featured;
  final String tagline;
}

enum StayBookingStatus {
  drafting,
  reserved,
  confirmed,
  checkedIn,
  completed,
  paid,
  cancelled,
}

extension StayBookingStatusX on StayBookingStatus {
  String get label => switch (this) {
    StayBookingStatus.drafting => 'Draft',
    StayBookingStatus.reserved => 'Reserved',
    StayBookingStatus.confirmed => 'Confirmed',
    StayBookingStatus.checkedIn => 'Checked in',
    StayBookingStatus.completed => 'Stay complete',
    StayBookingStatus.paid => 'Paid',
    StayBookingStatus.cancelled => 'Cancelled',
  };
}

class StayBooking {
  const StayBooking({
    required this.id,
    required this.hotel,
    required this.room,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
    required this.nights,
    required this.nightlyRate,
    required this.taxes,
    required this.total,
    required this.status,
    required this.createdAt,
    this.confirmationCode,
    this.paymentRef,
  });

  final String id;
  final Hotel hotel;
  final RoomType room;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guests;
  final int nights;
  final Money nightlyRate;
  final Money taxes;
  final Money total;
  final StayBookingStatus status;
  final DateTime createdAt;
  final String? confirmationCode;
  final String? paymentRef;

  StayBooking copyWith({
    StayBookingStatus? status,
    String? confirmationCode,
    String? paymentRef,
  }) {
    return StayBooking(
      id: id,
      hotel: hotel,
      room: room,
      checkIn: checkIn,
      checkOut: checkOut,
      guests: guests,
      nights: nights,
      nightlyRate: nightlyRate,
      taxes: taxes,
      total: total,
      status: status ?? this.status,
      createdAt: createdAt,
      confirmationCode: confirmationCode ?? this.confirmationCode,
      paymentRef: paymentRef ?? this.paymentRef,
    );
  }
}

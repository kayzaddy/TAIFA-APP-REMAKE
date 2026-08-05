import '../../features/flights/data/flight_catalog.dart';
import '../../features/flights/domain/flight_models.dart';
import '../../features/wallet/domain/currency.dart';
import '../../features/wallet/domain/money.dart';

/// Maps `/api/v1/commerce/flight-bookings` JSON ↔ domain [FlightBooking].
class FlightBookingDto {
  const FlightBookingDto._();

  static FlightBooking toDomain(
    Map<String, dynamic> json, {
    FlightOffer? offer,
  }) {
    final currency = Currency.fromCode(json['currency'] as String? ?? 'TZS');
    final total = Money((json['total_minor'] as num?)?.toInt() ?? 0, currency);
    final airline = json['airline'] as String? ?? '';
    final flightNumber = json['flight_number'] as String? ?? '';
    final originCode = json['origin_code'] as String? ?? '';
    final destCode = json['destination_code'] as String? ?? '';
    final departAt =
        DateTime.tryParse(json['depart_at'] as String? ?? '') ?? DateTime.now();
    final passengers = (json['passengers'] as num?)?.toInt() ?? 1;
    final pnr = (json['pnr'] as String?)?.trim();
    final pay = (json['payment_ref'] as String?)?.trim();

    final resolvedOffer =
        offer ??
        _synthesizeOffer(
          airline: airline,
          flightNumber: flightNumber,
          originCode: originCode,
          destCode: destCode,
          departAt: departAt,
          total: total,
          passengers: passengers,
        );

    return FlightBooking(
      id: json['id'].toString(),
      offer: resolvedOffer,
      passengers: passengers,
      total: total,
      status: statusFromApi(json['status'] as String? ?? 'ticketed'),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      pnr: (pnr == null || pnr.isEmpty) ? null : pnr,
      paymentRef: (pay == null || pay.isEmpty) ? null : pay,
    );
  }

  static Map<String, dynamic> createBody(FlightBooking draft) => {
    'airline': draft.offer.airline,
    'flight_number': draft.offer.flightNumber,
    'origin_code': draft.offer.origin.code,
    'destination_code': draft.offer.destination.code,
    'depart_at': draft.offer.departAt.toUtc().toIso8601String(),
    'passengers': draft.passengers,
    'total_minor': draft.total.minorUnits,
    'currency': draft.total.currency.code,
    if (draft.pnr != null && draft.pnr!.isNotEmpty) 'pnr': draft.pnr,
  };

  static Map<String, dynamic> patchBody(FlightBooking booking) {
    final body = <String, dynamic>{'status': statusToApi(booking.status)};
    if (booking.pnr != null && booking.pnr!.isNotEmpty) {
      body['pnr'] = booking.pnr;
    }
    return body;
  }

  static String statusToApi(FlightBookingStatus status) => switch (status) {
    FlightBookingStatus.drafting || FlightBookingStatus.held => 'held',
    FlightBookingStatus.ticketed => 'ticketed',
    FlightBookingStatus.paid => 'paid',
    FlightBookingStatus.cancelled => 'cancelled',
  };

  static FlightBookingStatus statusFromApi(String raw) => switch (raw) {
    'held' => FlightBookingStatus.held,
    'paid' => FlightBookingStatus.paid,
    'cancelled' => FlightBookingStatus.cancelled,
    _ => FlightBookingStatus.ticketed,
  };

  static Airport _airport(String code) {
    for (final a in FlightCatalog.airports()) {
      if (a.code == code) return a;
    }
    return Airport(code: code, city: code, name: code);
  }

  static FlightOffer _synthesizeOffer({
    required String airline,
    required String flightNumber,
    required String originCode,
    required String destCode,
    required DateTime departAt,
    required Money total,
    required int passengers,
  }) {
    final perPax = passengers <= 0
        ? total
        : Money(total.minorUnits ~/ passengers, total.currency);
    return FlightOffer(
      id: 'flt-remote-$flightNumber',
      airline: airline,
      flightNumber: flightNumber,
      origin: _airport(originCode),
      destination: _airport(destCode),
      departAt: departAt,
      arriveAt: departAt.add(const Duration(hours: 1)),
      durationMinutes: 60,
      price: perPax,
    );
  }
}

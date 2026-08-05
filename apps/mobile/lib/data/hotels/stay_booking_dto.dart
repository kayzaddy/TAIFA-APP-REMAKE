import '../../features/hotels/data/hotel_catalog.dart';
import '../../features/hotels/domain/hotel_models.dart';
import '../../features/wallet/domain/currency.dart';
import '../../features/wallet/domain/money.dart';

/// Maps `/api/v1/commerce/stay-bookings` JSON ↔ domain [StayBooking].
class StayBookingDto {
  const StayBookingDto._();

  static StayBooking toDomain(
    Map<String, dynamic> json, {
    Hotel? hotel,
    RoomType? room,
  }) {
    final currency = Currency.fromCode(json['currency'] as String? ?? 'TZS');
    final hotelId = json['hotel_id'] as String? ?? '';
    final hotelName = json['hotel_name'] as String? ?? 'Hotel';
    final roomName = json['room_name'] as String? ?? 'Room';
    final nightly = Money(
      (json['nightly_rate_minor'] as num?)?.toInt() ?? 0,
      currency,
    );
    final resolvedHotel = hotel ?? _resolveHotel(hotelId, hotelName, currency);
    final resolvedRoom = room ?? _resolveRoom(resolvedHotel, roomName, nightly);

    final conf = (json['confirmation_code'] as String?)?.trim();
    final pay = (json['payment_ref'] as String?)?.trim();

    return StayBooking(
      id: json['id'].toString(),
      hotel: resolvedHotel,
      room: resolvedRoom,
      checkIn: _parseDate(json['check_in'] as String?),
      checkOut: _parseDate(json['check_out'] as String?),
      guests: (json['guests'] as num?)?.toInt() ?? 2,
      nights: (json['nights'] as num?)?.toInt() ?? 1,
      nightlyRate: nightly,
      taxes: Money((json['taxes_minor'] as num?)?.toInt() ?? 0, currency),
      total: Money((json['total_minor'] as num?)?.toInt() ?? 0, currency),
      status: statusFromApi(json['status'] as String? ?? 'confirmed'),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      confirmationCode: (conf == null || conf.isEmpty) ? null : conf,
      paymentRef: (pay == null || pay.isEmpty) ? null : pay,
    );
  }

  static Map<String, dynamic> createBody(StayBooking draft) => {
    'hotel_id': draft.hotel.id,
    'hotel_name': draft.hotel.name,
    'room_name': draft.room.name,
    'check_in': _formatDate(draft.checkIn),
    'check_out': _formatDate(draft.checkOut),
    'guests': draft.guests,
    'nights': draft.nights,
    'nightly_rate_minor': draft.nightlyRate.minorUnits,
    'taxes_minor': draft.taxes.minorUnits,
    'total_minor': draft.total.minorUnits,
    'currency': draft.total.currency.code,
    if (draft.confirmationCode != null && draft.confirmationCode!.isNotEmpty)
      'confirmation_code': draft.confirmationCode,
  };

  static Map<String, dynamic> patchBody(StayBooking booking) {
    final body = <String, dynamic>{'status': statusToApi(booking.status)};
    if (booking.confirmationCode != null &&
        booking.confirmationCode!.isNotEmpty) {
      body['confirmation_code'] = booking.confirmationCode;
    }
    return body;
  }

  static String statusToApi(StayBookingStatus status) => switch (status) {
    StayBookingStatus.drafting || StayBookingStatus.reserved => 'reserved',
    StayBookingStatus.confirmed => 'confirmed',
    StayBookingStatus.checkedIn => 'checked_in',
    StayBookingStatus.completed => 'completed',
    StayBookingStatus.paid => 'paid',
    StayBookingStatus.cancelled => 'cancelled',
  };

  static StayBookingStatus statusFromApi(String raw) => switch (raw) {
    'reserved' => StayBookingStatus.reserved,
    'checked_in' => StayBookingStatus.checkedIn,
    'completed' => StayBookingStatus.completed,
    'paid' => StayBookingStatus.paid,
    'cancelled' => StayBookingStatus.cancelled,
    _ => StayBookingStatus.confirmed,
  };

  static String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static DateTime _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return DateTime.now();
    return DateTime.tryParse(raw) ?? DateTime.now();
  }

  static Hotel _resolveHotel(String id, String name, Currency currency) {
    try {
      return HotelCatalog.all().firstWhere((h) => h.id == id);
    } catch (_) {
      return Hotel(
        id: id.isEmpty ? 'htl-unknown' : id,
        name: name,
        area: '',
        rating: 4.5,
        stars: 4,
        fromNightly: Money.zero(currency),
        imageTone: 0,
        rooms: const [],
      );
    }
  }

  static RoomType _resolveRoom(Hotel hotel, String roomName, Money nightly) {
    for (final r in hotel.rooms) {
      if (r.name == roomName || r.id == roomName) return r;
    }
    return RoomType(
      id: 'room-unknown',
      name: roomName,
      description: '',
      nightlyRate: nightly,
      maxGuests: 2,
      amenities: const [],
    );
  }
}

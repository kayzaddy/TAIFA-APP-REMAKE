import '../../features/tourism/data/tourism_catalog.dart';
import '../../features/tourism/domain/tourism_models.dart';
import '../../features/wallet/domain/currency.dart';
import '../../features/wallet/domain/money.dart';

/// Maps `/api/v1/commerce/tour-bookings` JSON ↔ domain [TourBooking].
class TourBookingDto {
  const TourBookingDto._();

  static TourBooking toDomain(
    Map<String, dynamic> json, {
    TourExperience? tour,
  }) {
    final currency = Currency.fromCode(json['currency'] as String? ?? 'TZS');
    final tourId = json['tour_id'] as String? ?? '';
    final tourTitle = json['tour_title'] as String? ?? 'Experience';
    final guests = (json['guests'] as num?)?.toInt() ?? 2;
    final total = Money((json['total_minor'] as num?)?.toInt() ?? 0, currency);
    final conf = (json['confirmation_code'] as String?)?.trim();
    final pay = (json['payment_ref'] as String?)?.trim();

    return TourBooking(
      id: json['id'].toString(),
      tour: tour ?? _resolveTour(tourId, tourTitle, total, guests, currency),
      guests: guests,
      date: _parseDate(json['experience_date'] as String?),
      total: total,
      status: statusFromApi(json['status'] as String? ?? 'confirmed'),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      confirmationCode: (conf == null || conf.isEmpty) ? null : conf,
      paymentRef: (pay == null || pay.isEmpty) ? null : pay,
    );
  }

  static Map<String, dynamic> createBody(TourBooking draft) => {
    'tour_id': draft.tour.id,
    'tour_title': draft.tour.title,
    'experience_date': _formatDate(draft.date),
    'guests': draft.guests,
    'total_minor': draft.total.minorUnits,
    'currency': draft.total.currency.code,
    if (draft.confirmationCode != null && draft.confirmationCode!.isNotEmpty)
      'confirmation_code': draft.confirmationCode,
  };

  static Map<String, dynamic> patchBody(TourBooking booking) {
    final body = <String, dynamic>{'status': statusToApi(booking.status)};
    if (booking.confirmationCode != null &&
        booking.confirmationCode!.isNotEmpty) {
      body['confirmation_code'] = booking.confirmationCode;
    }
    return body;
  }

  static String statusToApi(TourBookingStatus status) => switch (status) {
    TourBookingStatus.drafting || TourBookingStatus.reserved => 'reserved',
    TourBookingStatus.confirmed => 'confirmed',
    TourBookingStatus.paid => 'paid',
    TourBookingStatus.cancelled => 'cancelled',
  };

  static TourBookingStatus statusFromApi(String raw) => switch (raw) {
    'reserved' => TourBookingStatus.reserved,
    'paid' => TourBookingStatus.paid,
    'cancelled' => TourBookingStatus.cancelled,
    _ => TourBookingStatus.confirmed,
  };

  static String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static DateTime _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return DateTime.now();
    return DateTime.tryParse(raw) ?? DateTime.now();
  }

  static TourExperience _resolveTour(
    String id,
    String title,
    Money total,
    int guests,
    Currency currency,
  ) {
    try {
      return TourismCatalog.all().firstWhere((t) => t.id == id);
    } catch (_) {
      final perGuest = guests <= 0
          ? total
          : Money(total.minorUnits ~/ guests, currency);
      return TourExperience(
        id: id.isEmpty ? 'tour-unknown' : id,
        title: title,
        region: '',
        durationLabel: '',
        rating: 4.5,
        price: perGuest,
        highlights: const [],
        imageTone: 0,
      );
    }
  }
}

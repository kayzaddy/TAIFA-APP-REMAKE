import '../../features/huduma/data/huduma_catalog.dart';
import '../../features/huduma/domain/huduma_models.dart';
import '../../features/wallet/domain/currency.dart';
import '../../features/wallet/domain/money.dart';

/// Maps `/api/v1/commerce/huduma-bookings` JSON ↔ domain [HudumaBooking].
class HudumaBookingDto {
  const HudumaBookingDto._();

  static HudumaBooking toDomain(
    Map<String, dynamic> json, {
    HudumaService? service,
  }) {
    final currency = Currency.fromCode(json['currency'] as String? ?? 'TZS');
    final serviceId = json['service_id'] as String? ?? '';
    final price = Money((json['price_minor'] as num?)?.toInt() ?? 0, currency);
    final pay = (json['payment_ref'] as String?)?.trim();

    return HudumaBooking(
      id: json['id'].toString(),
      service:
          service ??
          _resolveService(
            serviceId,
            json['service_title'] as String? ?? 'Service',
            json['category'] as String? ?? '',
            json['provider'] as String? ?? '',
            price,
          ),
      status: statusFromApi(json['status'] as String? ?? 'paid'),
      slotLabel: json['slot_label'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      paymentRef: (pay == null || pay.isEmpty) ? null : pay,
    );
  }

  static Map<String, dynamic> createBody(HudumaBooking draft) => {
    'service_id': draft.service.id,
    'service_title': draft.service.title,
    'category': draft.service.category,
    'provider': draft.service.provider,
    'slot_label': draft.slotLabel,
    'price_minor': draft.service.price.minorUnits,
    'currency': draft.service.price.currency.code,
    'status': statusToApi(draft.status),
    if (draft.paymentRef != null && draft.paymentRef!.isNotEmpty)
      'payment_ref': draft.paymentRef,
  };

  static String statusToApi(HudumaBookingStatus status) => switch (status) {
    HudumaBookingStatus.drafting ||
    HudumaBookingStatus.scheduled => 'scheduled',
    HudumaBookingStatus.paid => 'paid',
  };

  static HudumaBookingStatus statusFromApi(String raw) => switch (raw) {
    'scheduled' => HudumaBookingStatus.scheduled,
    'cancelled' => HudumaBookingStatus.drafting,
    _ => HudumaBookingStatus.paid,
  };

  static HudumaService _resolveService(
    String id,
    String title,
    String category,
    String provider,
    Money price,
  ) {
    try {
      return HudumaCatalog.services().firstWhere((s) => s.id == id);
    } catch (_) {
      return HudumaService(
        id: id.isEmpty ? 'hdm-unknown' : id,
        title: title,
        category: category,
        provider: provider,
        price: price,
        etaLabel: '',
        rating: 4.5,
      );
    }
  }
}

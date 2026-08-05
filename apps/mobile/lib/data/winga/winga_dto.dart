import '../../features/winga/domain/winga_models.dart';
import '../../features/wallet/domain/currency.dart';
import '../../features/wallet/domain/money.dart';

/// Maps WINGA commerce JSON ↔ domain types (catalog overlays stay client-side).
class WingaDto {
  const WingaDto._();

  static WingaOrder orderToDomain(
    Map<String, dynamic> json, {
    List<WingaCartLine>? lines,
  }) {
    final currency = Currency.fromCode(json['currency'] as String? ?? 'TZS');
    final pay = (json['payment_ref'] as String?)?.trim();
    final courier = (json['courier_name'] as String?)?.trim();
    final eta = (json['eta_label'] as String?)?.trim();
    return WingaOrder(
      id: json['id'].toString(),
      lines: lines ?? const [],
      total: Money((json['total_minor'] as num?)?.toInt() ?? 0, currency),
      status: orderStatusFromApi(json['status'] as String? ?? 'placed'),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      paymentRef: (pay == null || pay.isEmpty) ? null : pay,
      courierName: (courier == null || courier.isEmpty) ? null : courier,
      etaLabel: (eta == null || eta.isEmpty) ? null : eta,
    );
  }

  static Map<String, dynamic> orderCreateBody(WingaOrder draft) => {
    'total_minor': draft.total.minorUnits,
    'currency': draft.total.currency.code,
    'item_count': draft.lines.fold<int>(0, (a, l) => a + l.quantity),
    'summary': draft.lines.map((l) => l.product.name).take(3).join(', '),
    if (draft.paymentRef != null) 'payment_ref': draft.paymentRef,
    if (draft.courierName != null) 'courier_name': draft.courierName,
    if (draft.etaLabel != null) 'eta_label': draft.etaLabel,
  };

  static Map<String, dynamic> orderPatchBody(WingaOrder order) => {
    'status': orderStatusToApi(order.status),
    if (order.paymentRef != null) 'payment_ref': order.paymentRef,
    if (order.courierName != null) 'courier_name': order.courierName,
    if (order.etaLabel != null) 'eta_label': order.etaLabel,
  };

  static WingaServiceBooking serviceToDomain(
    Map<String, dynamic> json, {
    WingaServiceOffer? service,
  }) {
    final currency = Currency.fromCode(json['currency'] as String? ?? 'TZS');
    final pay = (json['payment_ref'] as String?)?.trim();
    final title = json['service_title'] as String? ?? 'Service';
    final sid = json['service_id'] as String? ?? '';
    final resolved =
        service ??
        WingaServiceOffer(
          id: sid,
          title: title,
          category: '',
          provider: '',
          city: '',
          priceFrom: Money(
            (json['total_minor'] as num?)?.toInt() ?? 0,
            currency,
          ),
          rating: 4.5,
        );
    return WingaServiceBooking(
      id: json['id'].toString(),
      service: resolved,
      slotLabel: json['slot_label'] as String? ?? '',
      total: Money((json['total_minor'] as num?)?.toInt() ?? 0, currency),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      paymentRef: (pay == null || pay.isEmpty) ? null : pay,
    );
  }

  static Map<String, dynamic> serviceCreateBody(WingaServiceBooking draft) => {
    'service_id': draft.service.id,
    'service_title': draft.service.title,
    'slot_label': draft.slotLabel,
    'total_minor': draft.total.minorUnits,
    'currency': draft.total.currency.code,
    if (draft.paymentRef != null) 'payment_ref': draft.paymentRef,
  };

  static WingaShopDraft shopToDomain(Map<String, dynamic> json) {
    final status = switch (json['status'] as String? ?? 'pending') {
      'approved' => WingaShopStatus.approved,
      'draft' => WingaShopStatus.draft,
      _ => WingaShopStatus.pending,
    };
    return WingaShopDraft(
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? 'Retail',
      address: json['address'] as String? ?? '',
      status: status,
    );
  }

  static Map<String, dynamic> shopCreateBody(WingaShopDraft draft) => {
    'name': draft.name,
    'category': draft.category,
    'address': draft.address,
  };

  static String orderStatusToApi(WingaOrderStatus status) => switch (status) {
    WingaOrderStatus.placed => 'placed',
    WingaOrderStatus.driverAssigned => 'driver_assigned',
    WingaOrderStatus.pickup => 'pickup',
    WingaOrderStatus.delivering => 'delivering',
    WingaOrderStatus.completed => 'completed',
  };

  static WingaOrderStatus orderStatusFromApi(String raw) => switch (raw) {
    'driver_assigned' => WingaOrderStatus.driverAssigned,
    'pickup' => WingaOrderStatus.pickup,
    'delivering' => WingaOrderStatus.delivering,
    'completed' => WingaOrderStatus.completed,
    _ => WingaOrderStatus.placed,
  };
}

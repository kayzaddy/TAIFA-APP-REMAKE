import '../../features/merchant/domain/merchant_models.dart';
import '../../features/wallet/domain/currency.dart';
import '../../features/wallet/domain/money.dart';

/// Maps `/api/v1/commerce/merchant-orders` JSON ↔ domain [MerchantOrder].
class MerchantOrderDto {
  const MerchantOrderDto._();

  static MerchantOrder toDomain(Map<String, dynamic> json) {
    final currency = Currency.fromCode(json['currency'] as String? ?? 'TZS');
    return MerchantOrder(
      id: json['id'].toString(),
      customerName: json['customer_name'] as String? ?? '',
      itemsLabel: json['items_label'] as String? ?? '',
      total: Money((json['total_minor'] as num?)?.toInt() ?? 0, currency),
      status: statusFromApi(json['status'] as String? ?? 'new'),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  static Map<String, dynamic> createBody(MerchantOrder order) => {
    'customer_name': order.customerName,
    'items_label': order.itemsLabel,
    'total_minor': order.total.minorUnits,
    'currency': order.total.currency.code,
    'status': statusToApi(order.status),
  };

  static Map<String, dynamic> patchBody(MerchantOrder order) => {
    'status': statusToApi(order.status),
  };

  static String statusToApi(MerchantOrderStatus status) => switch (status) {
    MerchantOrderStatus.newOrder => 'new',
    MerchantOrderStatus.preparing => 'preparing',
    MerchantOrderStatus.ready => 'ready',
    MerchantOrderStatus.completed => 'completed',
    MerchantOrderStatus.cancelled => 'cancelled',
  };

  static MerchantOrderStatus statusFromApi(String raw) => switch (raw) {
    'preparing' => MerchantOrderStatus.preparing,
    'ready' => MerchantOrderStatus.ready,
    'completed' => MerchantOrderStatus.completed,
    'cancelled' => MerchantOrderStatus.cancelled,
    _ => MerchantOrderStatus.newOrder,
  };
}

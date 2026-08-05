import '../../wallet/domain/money.dart';

enum MerchantOrderStatus { newOrder, preparing, ready, completed, cancelled }

extension MerchantOrderStatusX on MerchantOrderStatus {
  String get label => switch (this) {
    MerchantOrderStatus.newOrder => 'New',
    MerchantOrderStatus.preparing => 'Preparing',
    MerchantOrderStatus.ready => 'Ready',
    MerchantOrderStatus.completed => 'Completed',
    MerchantOrderStatus.cancelled => 'Cancelled',
  };
}

class MerchantOrder {
  const MerchantOrder({
    required this.id,
    required this.customerName,
    required this.itemsLabel,
    required this.total,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String customerName;
  final String itemsLabel;
  final Money total;
  final MerchantOrderStatus status;
  final DateTime createdAt;

  MerchantOrder copyWith({MerchantOrderStatus? status}) => MerchantOrder(
    id: id,
    customerName: customerName,
    itemsLabel: itemsLabel,
    total: total,
    status: status ?? this.status,
    createdAt: createdAt,
  );
}

class MerchantStats {
  const MerchantStats({
    required this.todaySales,
    required this.openOrders,
    required this.completedToday,
  });

  final Money todaySales;
  final int openOrders;
  final int completedToday;
}

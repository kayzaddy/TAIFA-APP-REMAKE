import '../../wallet/domain/money.dart';

class WingaStore {
  const WingaStore({
    required this.id,
    required this.name,
    required this.category,
    required this.city,
    required this.rating,
    required this.verified,
    this.tagline = '',
  });

  final String id;
  final String name;
  final String category;
  final String city;
  final double rating;
  final bool verified;
  final String tagline;
}

class WingaProduct {
  const WingaProduct({
    required this.id,
    required this.storeId,
    required this.name,
    required this.category,
    required this.price,
    required this.rating,
    required this.reviewCount,
    this.compareAt,
    this.badge,
    this.description = '',
  });

  final String id;
  final String storeId;
  final String name;
  final String category;
  final Money price;
  final Money? compareAt;
  final double rating;
  final int reviewCount;
  final String? badge;
  final String description;
}

class WingaServiceOffer {
  const WingaServiceOffer({
    required this.id,
    required this.title,
    required this.category,
    required this.provider,
    required this.city,
    required this.priceFrom,
    required this.rating,
  });

  final String id;
  final String title;
  final String category;
  final String provider;
  final String city;
  final Money priceFrom;
  final double rating;
}

class WingaCartLine {
  const WingaCartLine({required this.product, required this.quantity});

  final WingaProduct product;
  final int quantity;

  Money get lineTotal =>
      Money(product.price.minorUnits * quantity, product.price.currency);

  WingaCartLine copyWith({int? quantity}) =>
      WingaCartLine(product: product, quantity: quantity ?? this.quantity);
}

enum WingaOrderStatus { placed, driverAssigned, pickup, delivering, completed }

extension WingaOrderStatusX on WingaOrderStatus {
  String get label => switch (this) {
    WingaOrderStatus.placed => 'Order placed',
    WingaOrderStatus.driverAssigned => 'Courier assigned',
    WingaOrderStatus.pickup => 'Picked up',
    WingaOrderStatus.delivering => 'On the way',
    WingaOrderStatus.completed => 'Delivered',
  };
}

class WingaOrder {
  const WingaOrder({
    required this.id,
    required this.lines,
    required this.total,
    required this.status,
    required this.createdAt,
    this.paymentRef,
    this.courierName,
    this.etaLabel,
  });

  final String id;
  final List<WingaCartLine> lines;
  final Money total;
  final WingaOrderStatus status;
  final DateTime createdAt;
  final String? paymentRef;
  final String? courierName;
  final String? etaLabel;

  WingaOrder copyWith({
    WingaOrderStatus? status,
    String? paymentRef,
    String? courierName,
    String? etaLabel,
  }) {
    return WingaOrder(
      id: id,
      lines: lines,
      total: total,
      status: status ?? this.status,
      createdAt: createdAt,
      paymentRef: paymentRef ?? this.paymentRef,
      courierName: courierName ?? this.courierName,
      etaLabel: etaLabel ?? this.etaLabel,
    );
  }
}

enum WingaShopStatus { draft, pending, approved }

class WingaShopDraft {
  const WingaShopDraft({
    this.name = '',
    this.category = 'Retail',
    this.address = 'Dar es Salaam',
    this.logoEmoji = '🏪',
    this.status = WingaShopStatus.draft,
  });

  final String name;
  final String category;
  final String address;
  final String logoEmoji;
  final WingaShopStatus status;

  WingaShopDraft copyWith({
    String? name,
    String? category,
    String? address,
    String? logoEmoji,
    WingaShopStatus? status,
  }) {
    return WingaShopDraft(
      name: name ?? this.name,
      category: category ?? this.category,
      address: address ?? this.address,
      logoEmoji: logoEmoji ?? this.logoEmoji,
      status: status ?? this.status,
    );
  }
}

class WingaServiceBooking {
  const WingaServiceBooking({
    required this.id,
    required this.service,
    required this.slotLabel,
    required this.total,
    required this.createdAt,
    this.paymentRef,
  });

  final String id;
  final WingaServiceOffer service;
  final String slotLabel;
  final Money total;
  final DateTime createdAt;
  final String? paymentRef;
}

class WingaAiMessage {
  const WingaAiMessage({
    required this.id,
    required this.isUser,
    required this.text,
    required this.at,
  });

  final String id;
  final bool isUser;
  final String text;
  final DateTime at;
}

class NegotiaQuote {
  const NegotiaQuote({
    required this.supplier,
    required this.unitPrice,
    required this.qty,
    required this.transport,
    required this.negotiated,
    required this.scoreLabel,
  });

  final String supplier;
  final Money unitPrice;
  final int qty;
  final Money transport;
  final bool negotiated;
  final String scoreLabel;

  Money get goodsTotal => Money(unitPrice.minorUnits * qty, unitPrice.currency);
  Money get grandTotal => goodsTotal + transport;
}

class WingaMerchantStats {
  const WingaMerchantStats({
    required this.salesToday,
    required this.openOrders,
    required this.products,
    required this.customers,
  });

  final Money salesToday;
  final int openOrders;
  final int products;
  final int customers;
}

class WingaMerchantOrder {
  const WingaMerchantOrder({
    required this.id,
    required this.customer,
    required this.total,
    required this.statusLabel,
    required this.itemsSummary,
  });

  final String id;
  final String customer;
  final Money total;
  final String statusLabel;
  final String itemsSummary;
}

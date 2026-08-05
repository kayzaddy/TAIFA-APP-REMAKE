/// Taifa Commerce MOS domain models — experience layer (no money forging).
library;

class MosProduct {
  const MosProduct({
    required this.id,
    required this.sku,
    required this.name,
    required this.priceMinor,
    this.kind = 'physical',
    this.stockAvailable = 0,
    this.stockReserved = 0,
    this.favorite = false,
    this.category = 'General',
  });

  final String id;
  final String sku;
  final String name;
  final int priceMinor;
  final String kind;
  final num stockAvailable;
  final num stockReserved;
  final bool favorite;
  final String category;

  bool get isLowStock => stockAvailable > 0 && stockAvailable <= 5;
  bool get isOutOfStock => stockAvailable <= 0;

  MosProduct copyWith({
    num? stockAvailable,
    num? stockReserved,
    bool? favorite,
  }) =>
      MosProduct(
        id: id,
        sku: sku,
        name: name,
        priceMinor: priceMinor,
        kind: kind,
        stockAvailable: stockAvailable ?? this.stockAvailable,
        stockReserved: stockReserved ?? this.stockReserved,
        favorite: favorite ?? this.favorite,
        category: category,
      );
}

class MosOrder {
  const MosOrder({
    required this.id,
    required this.status,
    required this.totalMinor,
    required this.channel,
    this.paid = false,
    this.paymentRef = '',
    this.lines = const [],
    this.timeline = const [],
  });

  final String id;
  final String status;
  final int totalMinor;
  final String channel;
  final bool paid;
  final String paymentRef;
  final List<MosOrderLine> lines;
  final List<String> timeline;

  /// Journey index for UI stepper.
  int get stageIndex {
    const stages = [
      'draft',
      'open',
      'confirmed',
      'paid',
      'picking',
      'packing',
      'dispatched',
      'delivered',
      'fulfilled',
      'completed',
      'returned',
    ];
    final s = status.toLowerCase();
    if (paid && (s == 'confirmed' || s == 'open')) return stages.indexOf('paid');
    final i = stages.indexOf(s);
    return i < 0 ? 0 : i;
  }
}

class MosOrderLine {
  const MosOrderLine({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.unitPriceMinor,
  });

  final String productId;
  final String name;
  final num quantity;
  final int unitPriceMinor;
}

class MosSupplier {
  const MosSupplier({
    required this.id,
    required this.code,
    required this.name,
    this.rating = 4.2,
  });

  final String id;
  final String code;
  final String name;
  final double rating;
}

class MosPurchaseOrder {
  const MosPurchaseOrder({
    required this.id,
    required this.supplierName,
    required this.status,
    required this.totalMinor,
  });

  final String id;
  final String supplierName;
  final String status;
  final int totalMinor;
}

class MosCustomer {
  const MosCustomer({
    required this.id,
    required this.displayName,
    this.phone = '',
    this.loyaltyPoints = 0,
  });

  final String id;
  final String displayName;
  final String phone;
  final int loyaltyPoints;
}

class MosAnalytics {
  const MosAnalytics({
    this.products = 0,
    this.ordersTotal = 0,
    this.ordersPaid = 0,
    this.gmvMinor = 0,
    this.customers = 0,
    this.lowStock = 0,
    this.wingaEnabled = false,
  });

  final int products;
  final int ordersTotal;
  final int ordersPaid;
  final int gmvMinor;
  final int customers;
  final int lowStock;
  final bool wingaEnabled;
}

class MosPosSession {
  const MosPosSession({
    required this.id,
    required this.status,
    this.openingFloatMinor = 0,
  });

  final String id;
  final String status;
  final int openingFloatMinor;
  bool get isOpen => status == 'open';
}

class MosCartLine {
  const MosCartLine({
    required this.product,
    required this.quantity,
  });

  final MosProduct product;
  final int quantity;

  int get lineTotalMinor => product.priceMinor * quantity;
}

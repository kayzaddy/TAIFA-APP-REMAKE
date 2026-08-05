class ExpressProduct {
  const ExpressProduct({
    required this.id,
    required this.name,
    required this.priceMinor,
    required this.storeName,
    this.sku = '',
    this.stockQty = 0,
    this.currency = 'TZS',
  });

  final String id;
  final String name;
  final int priceMinor;
  final String storeName;
  final String sku;
  final int stockQty;
  final String currency;

  factory ExpressProduct.fromJson(Map<String, dynamic> json) {
    return ExpressProduct(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      priceMinor: (json['price_minor'] as num?)?.toInt() ?? 0,
      storeName: json['store_name']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      stockQty: (json['stock_qty'] as num?)?.toInt() ?? 0,
      currency: json['currency']?.toString() ?? 'TZS',
    );
  }
}

class ExpressRankedStore {
  const ExpressRankedStore({
    required this.storeId,
    required this.code,
    required this.name,
    required this.distanceM,
    required this.etaMinutes,
    required this.score,
    this.rating = 0,
    this.coverage = 1,
  });

  final String storeId;
  final String code;
  final String name;
  final int distanceM;
  final int etaMinutes;
  final double score;
  final double rating;
  final double coverage;

  factory ExpressRankedStore.fromJson(Map<String, dynamic> json) {
    return ExpressRankedStore(
      storeId: json['store_id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      distanceM: (json['distance_m'] as num?)?.toInt() ?? 0,
      etaMinutes: (json['eta_minutes'] as num?)?.toInt() ?? 0,
      score: (json['score'] as num?)?.toDouble() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      coverage: (json['coverage'] as num?)?.toDouble() ?? 1,
    );
  }
}

class ExpressQuote {
  const ExpressQuote({
    required this.subtotalMinor,
    required this.deliveryFeeMinor,
    required this.platformFeeMinor,
    required this.totalMinor,
    required this.etaMinutes,
    this.storeName = '',
    this.currency = 'TZS',
  });

  final int subtotalMinor;
  final int deliveryFeeMinor;
  final int platformFeeMinor;
  final int totalMinor;
  final int etaMinutes;
  final String storeName;
  final String currency;

  factory ExpressQuote.fromJson(Map<String, dynamic> json) {
    final store = json['store'];
    return ExpressQuote(
      subtotalMinor: (json['subtotal_minor'] as num?)?.toInt() ?? 0,
      deliveryFeeMinor: (json['delivery_fee_minor'] as num?)?.toInt() ?? 0,
      platformFeeMinor: (json['platform_fee_minor'] as num?)?.toInt() ?? 0,
      totalMinor: (json['total_minor'] as num?)?.toInt() ?? 0,
      etaMinutes: (json['eta_minutes'] as num?)?.toInt() ?? 0,
      storeName: store is Map ? (store['name']?.toString() ?? '') : '',
      currency: json['currency']?.toString() ?? 'TZS',
    );
  }
}

class ExpressBasketSuggestion {
  const ExpressBasketSuggestion({
    required this.prompt,
    required this.theme,
    required this.items,
    required this.disclaimer,
  });

  final String prompt;
  final String theme;
  final List<ExpressBasketItem> items;
  final String disclaimer;

  factory ExpressBasketSuggestion.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    return ExpressBasketSuggestion(
      prompt: json['prompt']?.toString() ?? '',
      theme: json['theme']?.toString() ?? '',
      items: raw is List
          ? raw
              .whereType<Map>()
              .map((e) => ExpressBasketItem.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      disclaimer: json['disclaimer']?.toString() ?? '',
    );
  }
}

class ExpressBasketItem {
  const ExpressBasketItem({
    required this.name,
    this.qty = 1,
    this.sku = '',
    this.productId = '',
    this.priceMinor = 0,
    this.unit = '',
    this.notes = '',
    this.storeName = '',
    this.status = 'matched',
  });

  final String name;
  final int qty;
  final String sku;
  final String productId;
  final int priceMinor;
  final String unit;
  final String notes;
  final String storeName;
  final String status;

  int get lineTotalMinor => priceMinor * qty;

  ExpressBasketItem copyWith({
    String? name,
    int? qty,
    String? sku,
    String? productId,
    int? priceMinor,
    String? unit,
    String? notes,
    String? storeName,
    String? status,
  }) {
    return ExpressBasketItem(
      name: name ?? this.name,
      qty: qty ?? this.qty,
      sku: sku ?? this.sku,
      productId: productId ?? this.productId,
      priceMinor: priceMinor ?? this.priceMinor,
      unit: unit ?? this.unit,
      notes: notes ?? this.notes,
      storeName: storeName ?? this.storeName,
      status: status ?? this.status,
    );
  }

  factory ExpressBasketItem.fromJson(Map<String, dynamic> json) {
    return ExpressBasketItem(
      name: json['name']?.toString() ?? '',
      qty: (json['qty'] as num?)?.toInt() ?? 1,
      sku: json['sku']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      priceMinor: (json['price_minor'] as num?)?.toInt() ?? 0,
      unit: json['unit']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      storeName: json['store_name']?.toString() ?? '',
      status: json['status']?.toString() ?? 'matched',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'qty': qty,
        if (sku.isNotEmpty) 'sku': sku,
        if (productId.isNotEmpty) 'product_id': productId,
      };
}

class ParsedShoppingList {
  const ParsedShoppingList({
    required this.matched,
    required this.unknown,
    required this.items,
    this.subtotalMinor = 0,
    this.currency = 'TZS',
    this.preferredStoreName = '',
  });

  final List<ExpressBasketItem> matched;
  final List<ExpressBasketItem> unknown;
  final List<ExpressBasketItem> items;
  final int subtotalMinor;
  final String currency;
  final String preferredStoreName;

  factory ParsedShoppingList.fromJson(Map<String, dynamic> json) {
    final matchedRaw = json['matched'];
    final unknownRaw = json['unknown'];
    final itemsRaw = json['items'];
    final store = json['preferred_store'];
    return ParsedShoppingList(
      matched: matchedRaw is List
          ? matchedRaw
              .whereType<Map>()
              .map((e) => ExpressBasketItem.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      unknown: unknownRaw is List
          ? unknownRaw
              .whereType<Map>()
              .map(
                (e) => ExpressBasketItem.fromJson({
                  ...Map<String, dynamic>.from(e),
                  'status': 'unknown',
                }),
              )
              .toList()
          : const [],
      items: itemsRaw is List
          ? itemsRaw
              .whereType<Map>()
              .map((e) => ExpressBasketItem.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      subtotalMinor: (json['subtotal_minor'] as num?)?.toInt() ?? 0,
      currency: json['currency']?.toString() ?? 'TZS',
      preferredStoreName: store is Map ? (store['name']?.toString() ?? '') : '',
    );
  }
}

class ExpressOrder {
  const ExpressOrder({
    required this.id,
    required this.publicCode,
    required this.status,
    required this.totalMinor,
    required this.lines,
    this.storeName = '',
    this.paymentRef = '',
    this.tripId = '',
    this.deliveryId = '',
    this.packageCode = '',
    this.packageQr = '',
    this.deliveryPin = '',
    this.etaMinutes = 0,
    this.deliveryFeeMinor = 0,
    this.platformFeeMinor = 0,
    this.subtotalMinor = 0,
    this.currency = 'TZS',
    this.customerAddress = '',
    this.customerLat = -6.75,
    this.customerLng = 39.28,
    this.settlementStatus = '',
    this.ranking = const [],
    this.timeline = const [],
    this.settlementPlan = const {},
  });

  final String id;
  final String publicCode;
  final String status;
  final int totalMinor;
  final int subtotalMinor;
  final int deliveryFeeMinor;
  final int platformFeeMinor;
  final String currency;
  final String storeName;
  final String paymentRef;
  final String tripId;
  final String deliveryId;
  final String packageCode;
  final String packageQr;
  final String deliveryPin;
  final String customerAddress;
  final double customerLat;
  final double customerLng;
  final String settlementStatus;
  final int etaMinutes;
  final List<Map<String, dynamic>> lines;
  final List<ExpressRankedStore> ranking;
  final List<Map<String, dynamic>> timeline;
  final Map<String, dynamic> settlementPlan;

  bool get isPaid => paymentRef.isNotEmpty;

  static const stageOrder = [
    'basket_submitted',
    'merchant_found',
    'merchant_accepted',
    'paid',
    'preparing',
    'ready',
    'rider_assigned',
    'picked_up',
    'on_the_way',
    'delivered',
    'completed',
  ];

  List<String> get timelineEvents =>
      timeline.map((e) => e['event']?.toString() ?? '').where((e) => e.isNotEmpty).toList();

  factory ExpressOrder.fromJson(Map<String, dynamic> json) {
    final rankingRaw = json['ranking'];
    final linesRaw = json['lines'];
    final timelineRaw = json['timeline'];
    final planRaw = json['settlement_plan'];
    return ExpressOrder(
      id: json['id']?.toString() ?? '',
      publicCode: json['public_code']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      totalMinor: (json['total_minor'] as num?)?.toInt() ?? 0,
      subtotalMinor: (json['subtotal_minor'] as num?)?.toInt() ?? 0,
      deliveryFeeMinor: (json['delivery_fee_minor'] as num?)?.toInt() ?? 0,
      platformFeeMinor: (json['platform_fee_minor'] as num?)?.toInt() ?? 0,
      currency: json['currency']?.toString() ?? 'TZS',
      storeName: json['store_name']?.toString() ?? '',
      paymentRef: json['payment_ref']?.toString() ?? '',
      tripId: json['trip_id']?.toString() ?? '',
      deliveryId: json['delivery_id']?.toString() ?? '',
      packageCode: json['package_code']?.toString() ?? '',
      packageQr: json['package_qr']?.toString() ?? '',
      deliveryPin: json['delivery_pin']?.toString() ?? '',
      customerAddress: json['customer_address']?.toString() ?? '',
      customerLat: (json['customer_lat'] as num?)?.toDouble() ?? -6.75,
      customerLng: (json['customer_lng'] as num?)?.toDouble() ?? 39.28,
      settlementStatus: json['settlement_status']?.toString() ?? '',
      etaMinutes: (json['eta_minutes'] as num?)?.toInt() ?? 0,
      lines: linesRaw is List
          ? linesRaw
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : const [],
      ranking: rankingRaw is List
          ? rankingRaw
              .whereType<Map>()
              .map((e) => ExpressRankedStore.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      timeline: timelineRaw is List
          ? timelineRaw
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : const [],
      settlementPlan: planRaw is Map
          ? Map<String, dynamic>.from(planRaw)
          : const {},
    );
  }
}

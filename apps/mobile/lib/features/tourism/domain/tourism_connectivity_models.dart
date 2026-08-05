class TourismEsimQuote {
  const TourismEsimQuote({
    required this.planId,
    required this.planName,
    required this.dataGb,
    required this.days,
    required this.priceMinor,
    this.currency = 'TZS',
    this.mno = '',
  });

  final String planId;
  final String planName;
  final int dataGb;
  final int days;
  final int priceMinor;
  final String currency;
  final String mno;

  factory TourismEsimQuote.fromJson(Map<String, dynamic> json) => TourismEsimQuote(
        planId: '${json['plan_id']}',
        planName: '${json['plan_name']}',
        dataGb: (json['data_gb'] as num?)?.toInt() ?? 0,
        days: (json['days'] as num?)?.toInt() ?? 0,
        priceMinor: (json['price_minor'] as num?)?.toInt() ?? 0,
        currency: '${json['currency'] ?? 'TZS'}',
        mno: '${json['mno'] ?? ''}',
      );
}

class TourismEsimActivation {
  const TourismEsimActivation({
    required this.orderId,
    required this.qrPayload,
    required this.activationCode,
  });

  final String orderId;
  final String qrPayload;
  final String activationCode;

  factory TourismEsimActivation.fromJson(Map<String, dynamic> json) =>
      TourismEsimActivation(
        orderId: '${json['order']?['id'] ?? json['id']}',
        qrPayload: '${json['qr_payload'] ?? ''}',
        activationCode: '${json['order']?['activation_code'] ?? ''}',
      );
}

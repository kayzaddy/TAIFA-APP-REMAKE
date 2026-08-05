/// MAP domain models — acceptance UX only; money refs are payment_ref strings.
class MapProfile {
  const MapProfile({
    required this.merchantId,
    required this.merchantCode,
    required this.displayName,
    required this.qrIdentity,
    this.acceptedMethods = const [],
    this.defaultCurrency = 'TZS',
  });

  final String merchantId;
  final String merchantCode;
  final String displayName;
  final String qrIdentity;
  final List<String> acceptedMethods;
  final String defaultCurrency;
}

class MapIntent {
  const MapIntent({
    required this.publicCode,
    required this.channel,
    required this.status,
    required this.amountMinor,
    this.amountPaidMinor = 0,
    this.currency = 'TZS',
    this.description = '',
    this.paymentRef = '',
    this.merchantCode = '',
  });

  final String publicCode;
  final String channel;
  final String status;
  final int amountMinor;
  final int amountPaidMinor;
  final String currency;
  final String description;
  final String paymentRef;
  final String merchantCode;

  bool get isPaid => status == 'paid';
}

class MapQr {
  const MapQr({
    required this.publicCode,
    required this.kind,
    required this.payload,
    this.intentCode = '',
  });

  final String publicCode;
  final String kind;
  final String payload;
  final String intentCode;
}

class MapPaymentLink {
  const MapPaymentLink({
    required this.publicCode,
    required this.pathToken,
    required this.payPath,
    required this.intentCode,
    this.purpose = 'general',
  });

  final String publicCode;
  final String pathToken;
  final String payPath;
  final String intentCode;
  final String purpose;
}

class MapInvoice {
  const MapInvoice({
    required this.publicCode,
    required this.invoiceNumber,
    required this.amountMinor,
    this.amountPaidMinor = 0,
    this.status = 'open',
    this.currency = 'TZS',
  });

  final String publicCode;
  final String invoiceNumber;
  final int amountMinor;
  final int amountPaidMinor;
  final String status;
  final String currency;
}

class MapReceipt {
  const MapReceipt({
    required this.publicCode,
    required this.paymentRef,
    required this.amountMinor,
    required this.merchantDisplay,
    this.currency = 'TZS',
    this.channel = '',
    this.verificationQr = '',
  });

  final String publicCode;
  final String paymentRef;
  final int amountMinor;
  final String merchantDisplay;
  final String currency;
  final String channel;
  final String verificationQr;
}

class MapAnalytics {
  const MapAnalytics({
    this.intentsTotal = 0,
    this.intentsPaid = 0,
    this.gmvMinor = 0,
    this.qrCount = 0,
    this.linksCount = 0,
    this.invoicesOpen = 0,
    this.terminals = 0,
    this.channelMix = const {},
  });

  final int intentsTotal;
  final int intentsPaid;
  final int gmvMinor;
  final int qrCount;
  final int linksCount;
  final int invoicesOpen;
  final int terminals;
  final Map<String, int> channelMix;
}

class MapPayResult {
  const MapPayResult({required this.intent, required this.receipt});

  final MapIntent intent;
  final MapReceipt receipt;
}

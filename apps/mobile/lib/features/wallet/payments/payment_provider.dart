/// The concrete payment rails TAIFA can route through. Business logic never
/// references these directly — the [PaymentRouter] resolves an operation to a
/// provider. Adding an operator (or a new aggregator/bank) is one entry here
/// plus one adapter class.
enum PaymentProvider {
  mpesa('M-Pesa'),
  mixxByYas('Mixx by Yas'),
  airtelMoney('Airtel Money'),
  halopesa('HaloPesa'),
  selcom('Selcom'),
  pesapal('Pesapal'),
  flutterwave('Flutterwave'),
  dpo('DPO Group'),
  azampay('AzamPay'),
  cardScheme('Card'),
  bankRail('Bank');

  const PaymentProvider(this.displayName);
  final String displayName;
}

/// What a provider can do. A gateway advertises its capabilities so the router
/// can pick a rail that supports the requested operation, method and currency.
enum PaymentCapability {
  charge, // pull funds in (collection)
  payout, // push funds out (disbursement)
  refund,
  statusQuery,
  mobileMoney,
  card,
  bank,
  crypto,
}

/// The operation being attempted, independent of provider.
enum PaymentOperation { charge, payout, refund }

/// Lightweight feature flags for Super App shell — local only.
class SuperAppFlags {
  const SuperAppFlags({
    this.universalSearch = true,
    this.universalQr = true,
    this.universalPay = true,
    this.homeJourneyRail = true,
    this.aiSuggestions = true,
    this.offlineBanner = true,
  });

  final bool universalSearch;
  final bool universalQr;
  final bool universalPay;
  final bool homeJourneyRail;
  final bool aiSuggestions;
  final bool offlineBanner;

  static const current = SuperAppFlags();
}

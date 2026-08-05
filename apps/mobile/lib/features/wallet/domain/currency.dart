/// Supported currencies with the metadata needed for correct storage and
/// display. `minorUnitDigits` is the ISO-4217 storage precision (how many
/// integer minor units make one major unit); `displayDigits` is how many
/// fraction digits we render (TZS is conventionally shown without decimals).
///
/// This enum is the single place currencies are defined. Adding a currency —
/// or a crypto asset — is one entry here; nothing downstream hardcodes symbols.
enum Currency {
  tzs(
    code: 'TZS',
    symbol: 'TSh',
    name: 'Tanzanian Shilling',
    minorUnitDigits: 2,
    displayDigits: 0,
  ),
  usd(
    code: 'USD',
    symbol: '\$',
    name: 'US Dollar',
    minorUnitDigits: 2,
    displayDigits: 2,
  ),
  eur(
    code: 'EUR',
    symbol: '€',
    name: 'Euro',
    minorUnitDigits: 2,
    displayDigits: 2,
  ),
  kes(
    code: 'KES',
    symbol: 'KSh',
    name: 'Kenyan Shilling',
    minorUnitDigits: 2,
    displayDigits: 0,
  ),
  ugx(
    code: 'UGX',
    symbol: 'USh',
    name: 'Ugandan Shilling',
    minorUnitDigits: 0,
    displayDigits: 0,
  ),
  btc(
    code: 'BTC',
    symbol: '₿',
    name: 'Bitcoin',
    minorUnitDigits: 8,
    displayDigits: 6,
    isCrypto: true,
  );

  const Currency({
    required this.code,
    required this.symbol,
    required this.name,
    required this.minorUnitDigits,
    required this.displayDigits,
    this.isCrypto = false,
  });

  final String code;
  final String symbol;
  final String name;
  final int minorUnitDigits;
  final int displayDigits;
  final bool isCrypto;

  /// 10^minorUnitDigits — the number of minor units per major unit.
  int get scale {
    var s = 1;
    for (var i = 0; i < minorUnitDigits; i++) {
      s *= 10;
    }
    return s;
  }

  static Currency fromCode(String code) => Currency.values.firstWhere(
    (c) => c.code == code.toUpperCase(),
    orElse: () => throw ArgumentError('Unsupported currency: $code'),
  );
}

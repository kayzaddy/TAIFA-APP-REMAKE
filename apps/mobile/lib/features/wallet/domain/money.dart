import 'currency.dart';

/// An immutable monetary amount stored as **integer minor units** in a single
/// [Currency]. Money math is exact — we never use `double` for value, which
/// eliminates rounding drift in balances, fees and ledger postings.
///
/// Example: `Money.major(2847500, Currency.tzs)` is TSh 2,847,500.00 stored as
/// 284,750,000 minor units.
class Money implements Comparable<Money> {
  const Money(this.minorUnits, this.currency);

  /// The signed amount in minor units (e.g. cents).
  final int minorUnits;
  final Currency currency;

  /// Build from a whole major-unit amount (e.g. shillings).
  factory Money.major(int major, Currency currency) =>
      Money(major * currency.scale, currency);

  /// Build from a decimal major amount (e.g. 100.20 USD). Rounds half-up to the
  /// currency's minor-unit precision.
  factory Money.fromDecimal(num amount, Currency currency) {
    final scaled = amount * currency.scale;
    return Money(scaled.round(), currency);
  }

  static Money zero(Currency currency) => Money(0, currency);

  bool get isZero => minorUnits == 0;
  bool get isNegative => minorUnits < 0;
  bool get isPositive => minorUnits > 0;

  /// Value expressed in major units as a double — **for display/estimates only**,
  /// never for further money math.
  double get asDecimal => minorUnits / currency.scale;

  Money operator +(Money other) {
    _assertSameCurrency(other);
    return Money(minorUnits + other.minorUnits, currency);
  }

  Money operator -(Money other) {
    _assertSameCurrency(other);
    return Money(minorUnits - other.minorUnits, currency);
  }

  Money operator -() => Money(-minorUnits, currency);

  Money get abs => Money(minorUnits.abs(), currency);

  bool operator >(Money other) {
    _assertSameCurrency(other);
    return minorUnits > other.minorUnits;
  }

  bool operator <(Money other) {
    _assertSameCurrency(other);
    return minorUnits < other.minorUnits;
  }

  bool operator >=(Money other) => this > other || this == other;
  bool operator <=(Money other) => this < other || this == other;

  void _assertSameCurrency(Money other) {
    if (other.currency != currency) {
      throw StateError(
        'Currency mismatch: ${currency.code} vs ${other.currency.code}. '
        'Convert via the currency engine before combining.',
      );
    }
  }

  /// Formats with grouping separators and the currency symbol, e.g.
  /// `TSh 2,847,500` or `\$1,140.00`.
  String format({bool withSymbol = true, bool withSign = false}) {
    final negative = minorUnits < 0;
    final scaled = minorUnits.abs();
    final major = scaled ~/ currency.scale;
    final fraction = scaled % currency.scale;

    final buffer = StringBuffer(_group(major));
    if (currency.displayDigits > 0) {
      // Right-most `displayDigits` of the zero-padded minor part.
      final padded = fraction.toString().padLeft(currency.minorUnitDigits, '0');
      final shown = currency.displayDigits <= padded.length
          ? padded.substring(0, currency.displayDigits)
          : padded.padRight(currency.displayDigits, '0');
      buffer.write('.$shown');
    }

    final sign = negative ? '-' : (withSign && minorUnits > 0 ? '+' : '');
    final symbol = withSymbol ? '${currency.symbol} ' : '';
    return '$sign$symbol${buffer.toString()}';
  }

  static String _group(int value) {
    final s = value.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }

  @override
  int compareTo(Money other) {
    _assertSameCurrency(other);
    return minorUnits.compareTo(other.minorUnits);
  }

  @override
  bool operator ==(Object other) =>
      other is Money &&
      other.minorUnits == minorUnits &&
      other.currency == currency;

  @override
  int get hashCode => Object.hash(minorUnits, currency);

  @override
  String toString() => '${currency.code} ${format(withSymbol: false)}';
}

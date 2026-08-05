import 'currency.dart';
import 'money.dart';

/// Converts [Money] between currencies for display and quoting. Rates are held
/// relative to a single base (TZS) so cross-rates are derived consistently.
///
/// Seed rates are static here; the production engine will source live mid-market
/// rates (with spread/markup policy) behind this same interface — callers won't
/// change. Conversions are display/estimate figures; settlement uses the rate
/// captured at authorisation time.
abstract interface class CurrencyEngine {
  /// Units of [currency] per 1 unit of the base currency.
  double rate(Currency currency);
  Currency get base;
  Money convert(Money amount, Currency to);
}

class StaticCurrencyEngine implements CurrencyEngine {
  const StaticCurrencyEngine();

  @override
  Currency get base => Currency.tzs;

  // TZS per 1 unit of the given currency.
  static const Map<Currency, double> _tzsPerUnit = {
    Currency.tzs: 1.0,
    Currency.usd: 2497.0,
    Currency.eur: 2705.0,
    Currency.kes: 19.35,
    Currency.ugx: 0.67,
    Currency.btc: 168000000.0,
  };

  @override
  double rate(Currency currency) => 1.0 / (_tzsPerUnit[currency] ?? 1.0);

  @override
  Money convert(Money amount, Currency to) {
    if (amount.currency == to) return amount;
    final inTzs = amount.asDecimal * (_tzsPerUnit[amount.currency] ?? 1.0);
    final inTarget = inTzs / (_tzsPerUnit[to] ?? 1.0);
    return Money.fromDecimal(inTarget, to);
  }
}

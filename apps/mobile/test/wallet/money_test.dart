import 'package:flutter_test/flutter_test.dart';
import 'package:taifa/features/wallet/domain/currency.dart';
import 'package:taifa/features/wallet/domain/money.dart';

void main() {
  group('Money', () {
    test('major() scales into minor units', () {
      final m = Money.major(2847500, Currency.tzs);
      expect(m.minorUnits, 284750000); // 2 minor-unit digits
      expect(m.asDecimal, 2847500.0);
    });

    test('formats TZS without decimals and grouping', () {
      expect(Money.major(2847500, Currency.tzs).format(), 'TSh 2,847,500');
    });

    test('formats USD with two decimals', () {
      expect(Money.fromDecimal(1140.5, Currency.usd).format(), '\$ 1,140.50');
    });

    test('addition and subtraction are exact', () {
      final a = Money.major(1000, Currency.tzs);
      final b = Money.major(250, Currency.tzs);
      expect((a - b), Money.major(750, Currency.tzs));
      expect((a + b), Money.major(1250, Currency.tzs));
    });

    test('rejects cross-currency arithmetic', () {
      expect(
        () => Money.major(1, Currency.tzs) + Money.major(1, Currency.usd),
        throwsStateError,
      );
    });

    test('fromDecimal rounds half-up to minor units', () {
      expect(Money.fromDecimal(10.005, Currency.usd).minorUnits, 1001);
    });

    test('signed formatting', () {
      expect(
        (-Money.major(500, Currency.tzs)).format(withSign: true),
        '-TSh 500',
      );
      expect(Money.major(500, Currency.tzs).format(withSign: true), '+TSh 500');
    });

    test('comparisons', () {
      expect(
        Money.major(2, Currency.tzs) > Money.major(1, Currency.tzs),
        isTrue,
      );
      expect(
        Money.major(1, Currency.tzs) <= Money.major(1, Currency.tzs),
        isTrue,
      );
    });
  });
}

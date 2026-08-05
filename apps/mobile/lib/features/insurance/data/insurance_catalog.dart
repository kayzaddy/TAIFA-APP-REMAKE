import '../../wallet/domain/currency.dart';
import '../../wallet/domain/money.dart';
import '../domain/insurance_models.dart';

class InsuranceCatalog {
  const InsuranceCatalog._();

  static List<InsurancePlan> plans() {
    Money m(int major) => Money.major(major, Currency.tzs);
    return [
      InsurancePlan(
        id: 'ins-health',
        name: 'Family Health Plus',
        provider: 'Jubilee Health',
        category: 'Health',
        premium: m(45000),
        coverage: m(5000000),
        highlights: const ['OPD + IPD', '3 dependents', 'Muhimbili network'],
      ),
      InsurancePlan(
        id: 'ins-motor',
        name: 'Boda / Car Third Party',
        provider: 'Alliance Insurance',
        category: 'Motor',
        premium: m(85000),
        coverage: m(10000000),
        highlights: const [
          'Third-party liability',
          '24h claims desk',
          'Dar + regions',
        ],
      ),
      InsurancePlan(
        id: 'ins-travel',
        name: 'Safari Travel Cover',
        provider: 'Strategies Insurance',
        category: 'Travel',
        premium: m(25000),
        coverage: m(2000000),
        highlights: const ['Medical abroad', 'Trip delay', '7–30 day trips'],
      ),
      InsurancePlan(
        id: 'ins-life',
        name: 'Term Life Shield',
        provider: 'Britam',
        category: 'Life',
        premium: m(30000),
        coverage: m(15000000),
        highlights: const ['Monthly premium', 'Nominee payout', 'Age 18–55'],
      ),
    ];
  }
}

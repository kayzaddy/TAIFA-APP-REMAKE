import '../../wallet/domain/currency.dart';
import '../../wallet/domain/money.dart';
import '../domain/wealth_models.dart';

class WealthCatalog {
  const WealthCatalog._();

  static List<HarambeeCircle> circles() {
    Money m(int major) => Money.major(major, Currency.tzs);
    return [
      HarambeeCircle(
        id: 'hr-school',
        name: 'Neema school fees',
        purpose: 'Term 2 · Azania Secondary',
        target: m(450000),
        raised: m(280000),
        members: 6,
      ),
      HarambeeCircle(
        id: 'hr-medical',
        name: 'Family medical fund',
        purpose: 'Muhimbili consult + meds',
        target: m(800000),
        raised: m(510000),
        members: 9,
      ),
      HarambeeCircle(
        id: 'hr-wedding',
        name: 'Asha wedding support',
        purpose: 'Community harambee',
        target: m(2500000),
        raised: m(1200000),
        members: 24,
      ),
      HarambeeCircle(
        id: 'hr-vault',
        name: 'TAIFA Vault · Saver',
        purpose: 'Personal locked savings (demo)',
        target: m(1000000),
        raised: m(350000),
        members: 1,
      ),
    ];
  }
}

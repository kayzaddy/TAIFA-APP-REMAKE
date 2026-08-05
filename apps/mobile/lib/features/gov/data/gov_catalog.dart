import '../../wallet/domain/currency.dart';
import '../../wallet/domain/money.dart';
import '../domain/gov_models.dart';

class GovCatalog {
  const GovCatalog._();

  static List<GovService> all() {
    Money m(int major) => Money.major(major, Currency.tzs);
    return [
      GovService(
        id: 'gov-nida',
        title: 'NIDA ID replacement',
        agency: 'NIDA',
        description: 'Request a replacement national ID card (demo).',
        fee: m(25000),
        etaDays: 14,
        category: 'Identity',
      ),
      GovService(
        id: 'gov-passport',
        title: 'Passport renewal',
        agency: 'Immigration',
        description: 'Renew ordinary passport appointment + fee voucher.',
        fee: m(150000),
        etaDays: 21,
        category: 'Travel',
      ),
      GovService(
        id: 'gov-tin',
        title: 'TIN certificate',
        agency: 'TRA',
        description: 'Digital TIN confirmation letter for employers.',
        fee: m(0),
        etaDays: 3,
        category: 'Tax',
      ),
      GovService(
        id: 'gov-licence',
        title: 'Business licence',
        agency: 'BRELA',
        description: 'Micro enterprise licence application (seeded demo).',
        fee: m(80000),
        etaDays: 10,
        category: 'Business',
      ),
      GovService(
        id: 'gov-land',
        title: 'Land rent statement',
        agency: 'Ministry of Lands',
        description: 'Request current land rent statement PDF.',
        fee: m(10000),
        etaDays: 5,
        category: 'Land',
      ),
    ];
  }
}

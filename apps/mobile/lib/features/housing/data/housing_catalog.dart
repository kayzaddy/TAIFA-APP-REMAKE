import '../../wallet/domain/currency.dart';
import '../../wallet/domain/money.dart';
import '../domain/housing_models.dart';

class HousingCatalog {
  const HousingCatalog._();

  static List<HousingListing> all() {
    Money m(int major) => Money.major(major, Currency.tzs);
    return [
      HousingListing(
        id: 'hs-miko',
        title: '2BR Mikocheni flat',
        area: 'Mikocheni · Dar es Salaam',
        beds: 2,
        baths: 1,
        monthlyRent: m(850000),
        deposit: m(850000),
        tagline: 'Gated · backup power',
      ),
      HousingListing(
        id: 'hs-masaki',
        title: 'Studio Masaki',
        area: 'Masaki · Peninsula',
        beds: 1,
        baths: 1,
        monthlyRent: m(1200000),
        deposit: m(1200000),
        tagline: 'Sea breeze · furnished',
      ),
      HousingListing(
        id: 'hs-arusha',
        title: 'Family house Sakina',
        area: 'Sakina · Arusha',
        beds: 3,
        baths: 2,
        monthlyRent: m(650000),
        deposit: m(650000),
        tagline: 'Garden · parking',
      ),
      HousingListing(
        id: 'hs-ubungo',
        title: 'Bedsitter Ubungo',
        area: 'Ubungo · Dar es Salaam',
        beds: 1,
        baths: 1,
        monthlyRent: m(280000),
        deposit: m(280000),
        tagline: 'Near BRT · student-friendly',
      ),
    ];
  }
}

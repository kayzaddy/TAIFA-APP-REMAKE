import '../../wallet/domain/currency.dart';
import '../../wallet/domain/money.dart';
import '../domain/huduma_models.dart';

class HudumaCatalog {
  const HudumaCatalog._();

  static List<HudumaService> services() {
    Money m(int major) => Money.major(major, Currency.tzs);
    return [
      HudumaService(
        id: 'hd-plumb',
        title: 'Plumbing fix',
        category: 'Home repair',
        provider: 'Ufundi Pros · Mikocheni',
        price: m(35000),
        etaLabel: 'Today · 2–4 pm',
        rating: 4.8,
      ),
      HudumaService(
        id: 'hd-clean',
        title: 'Deep clean (2BR)',
        category: 'Cleaning',
        provider: 'Safisha Home',
        price: m(55000),
        etaLabel: 'Tomorrow · morning',
        rating: 4.6,
      ),
      HudumaService(
        id: 'hd-ac',
        title: 'AC service',
        category: 'Appliances',
        provider: 'CoolAir TZ',
        price: m(45000),
        etaLabel: 'Sat · afternoon',
        rating: 4.7,
      ),
      HudumaService(
        id: 'hd-elec',
        title: 'Electrical check',
        category: 'Home repair',
        provider: 'Umeme Safe',
        price: m(40000),
        etaLabel: 'Today · evening',
        rating: 4.5,
      ),
      HudumaService(
        id: 'hd-laundry',
        title: 'Laundry pickup',
        category: 'Laundry',
        provider: 'Fresh Fold',
        price: m(18000),
        etaLabel: '2 hrs pickup',
        rating: 4.4,
      ),
    ];
  }

  static const slots = <String>[
    'Today · 2–4 pm',
    'Tomorrow · 9–11 am',
    'Saturday · 1–3 pm',
  ];
}

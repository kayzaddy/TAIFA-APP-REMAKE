import '../../wallet/domain/currency.dart';
import '../../wallet/domain/money.dart';
import '../domain/tourism_models.dart';

class TourismCatalog {
  const TourismCatalog._();

  static List<TourExperience> all() {
    Money m(int major) => Money.major(major, Currency.tzs);
    return [
      TourExperience(
        id: 'tour-stone',
        title: 'Stone Town Heritage Walk',
        region: 'Zanzibar · Unguja',
        durationLabel: '3 hours',
        rating: 4.9,
        price: m(65000),
        featured: true,
        tagline: 'Spices, fort & harbour',
        imageTone: 0,
        highlights: const ['Guide', 'Fort entrance', 'Spice market tasting'],
      ),
      TourExperience(
        id: 'tour-serengeti',
        title: 'Serengeti Day Flight Safari',
        region: 'Northern Circuit',
        durationLabel: 'Full day',
        rating: 4.8,
        price: m(890000),
        featured: true,
        tagline: 'Game drive + aerial corridor',
        imageTone: 1,
        highlights: const ['Park fees', 'Picnic lunch', 'Experienced ranger'],
      ),
      TourExperience(
        id: 'tour-ngorongoro',
        title: 'Ngorongoro Crater Descent',
        region: 'Arusha · Crater rim',
        durationLabel: 'Full day',
        rating: 4.9,
        price: m(420000),
        tagline: 'World Heritage crater floor',
        imageTone: 2,
        highlights: const ['4x4', 'Park fees', 'Packed lunch'],
      ),
      TourExperience(
        id: 'tour-mnemba',
        title: 'Mnemba Reef Snorkel',
        region: 'Zanzibar · Northeast',
        durationLabel: 'Half day',
        rating: 4.7,
        price: m(145000),
        tagline: 'Coral gardens & turtles',
        imageTone: 3,
        highlights: const ['Boat', 'Gear', 'Refreshments'],
      ),
      TourExperience(
        id: 'tour-spice',
        title: 'Pemba Spice & Farm Trail',
        region: 'Pemba Island',
        durationLabel: '4 hours',
        rating: 4.6,
        price: m(78000),
        tagline: 'Clove farms · village lunch',
        imageTone: 0,
        highlights: const ['Local host', 'Tastings', 'Transport'],
      ),
    ];
  }
}

import '../../wallet/domain/currency.dart';
import '../../wallet/domain/money.dart';
import '../domain/hotel_models.dart';

/// Curated Dar / Zanzibar stays for the Foundation Sprint demo.
class HotelCatalog {
  const HotelCatalog._();

  static List<Hotel> all() {
    Money m(int major) => Money.major(major, Currency.tzs);
    return [
      Hotel(
        id: 'htl-hyatt',
        name: 'Hyatt Regency Dar',
        area: 'Kivukoni · City Centre',
        rating: 4.8,
        stars: 5,
        fromNightly: m(320000),
        imageTone: 0,
        featured: true,
        tagline: 'Harbour views · rooftop pool',
        rooms: [
          RoomType(
            id: 'hy-king',
            name: 'King Harbour View',
            description: 'Floor-to-ceiling harbour windows, king bed',
            nightlyRate: m(320000),
            maxGuests: 2,
            amenities: const ['Wi‑Fi', 'Breakfast', 'Pool'],
            popular: true,
          ),
          RoomType(
            id: 'hy-suite',
            name: 'Regency Suite',
            description: 'Separate lounge, club access',
            nightlyRate: m(480000),
            maxGuests: 3,
            amenities: const ['Wi‑Fi', 'Breakfast', 'Club lounge', 'Spa'],
            popular: true,
          ),
        ],
      ),
      Hotel(
        id: 'htl-zanzibar',
        name: 'Zanzibar Serena',
        area: 'Stone Town · Zanzibar',
        rating: 4.9,
        stars: 5,
        fromNightly: m(410000),
        imageTone: 1,
        featured: true,
        tagline: 'Palace heritage · ocean breeze',
        rooms: [
          RoomType(
            id: 'zn-classic',
            name: 'Classic Sea Room',
            description: 'Swahili décor, partial sea view',
            nightlyRate: m(410000),
            maxGuests: 2,
            amenities: const ['Wi‑Fi', 'Breakfast', 'Historical tour'],
            popular: true,
          ),
          RoomType(
            id: 'zn-suite',
            name: 'Sultan Suite',
            description: 'Private balcony over the Indian Ocean',
            nightlyRate: m(620000),
            maxGuests: 3,
            amenities: const ['Wi‑Fi', 'Breakfast', 'Butler', 'Spa'],
          ),
        ],
      ),
      Hotel(
        id: 'htl-masai',
        name: 'Masai Lodge Arusha',
        area: 'Arusha · Safari gateway',
        rating: 4.6,
        stars: 4,
        fromNightly: m(185000),
        imageTone: 2,
        tagline: 'Mountain air · safari briefing desk',
        rooms: [
          RoomType(
            id: 'ms-twin',
            name: 'Safari Twin',
            description: 'Twin beds, garden view',
            nightlyRate: m(185000),
            maxGuests: 2,
            amenities: const ['Wi‑Fi', 'Breakfast', 'Airport shuttle'],
            popular: true,
          ),
          RoomType(
            id: 'ms-family',
            name: 'Family Cottage',
            description: 'Two bedrooms, private verandah',
            nightlyRate: m(260000),
            maxGuests: 4,
            amenities: const ['Wi‑Fi', 'Breakfast', 'Kitchenette'],
          ),
        ],
      ),
      Hotel(
        id: 'htl-slipway',
        name: 'Slipway Residences',
        area: 'Msasani · Dar es Salaam',
        rating: 4.5,
        stars: 4,
        fromNightly: m(145000),
        imageTone: 3,
        tagline: 'Peninsula quiet · mall access',
        rooms: [
          RoomType(
            id: 'sl-studio',
            name: 'Studio Peninsula',
            description: 'Compact studio with kitchenette',
            nightlyRate: m(145000),
            maxGuests: 2,
            amenities: const ['Wi‑Fi', 'Kitchenette', 'Gym'],
            popular: true,
          ),
          RoomType(
            id: 'sl-apt',
            name: 'One-Bedroom Apt',
            description: 'Living room + full kitchen',
            nightlyRate: m(210000),
            maxGuests: 3,
            amenities: const ['Wi‑Fi', 'Kitchen', 'Pool', 'Parking'],
          ),
        ],
      ),
    ];
  }
}

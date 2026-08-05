import '../../wallet/domain/currency.dart';
import '../../wallet/domain/money.dart';
import '../domain/food_models.dart';

/// Curated Dar es Salaam restaurant catalog for the Foundation Sprint demo.
class FoodCatalog {
  const FoodCatalog._();

  static List<Restaurant> all() {
    Money m(int major) => Money.major(major, Currency.tzs);
    return [
      Restaurant(
        id: 'rst-spice',
        name: 'Spice Bazaar',
        cuisine: 'Swahili · Grill',
        rating: 4.8,
        etaMinutes: 28,
        deliveryFee: m(1500),
        imageTone: 0,
        featured: true,
        menu: [
          MenuItem(
            id: 'm1',
            name: 'Mishkaki Platter',
            description: 'Charcoal skewers, kachumbari, ugali',
            price: m(12000),
            category: 'Mains',
            popular: true,
          ),
          MenuItem(
            id: 'm2',
            name: 'Zanzibar Pilau',
            description: 'Fragrant rice with beef',
            price: m(9500),
            category: 'Mains',
            popular: true,
          ),
          MenuItem(
            id: 'm3',
            name: 'Samaki wa Kupaka',
            description: 'Coconut fish curry',
            price: m(14000),
            category: 'Mains',
          ),
          MenuItem(
            id: 'm4',
            name: 'Fresh Sugarcane Juice',
            description: 'Pressed to order',
            price: m(3500),
            category: 'Drinks',
          ),
          MenuItem(
            id: 'm5',
            name: 'Kashata',
            description: 'Peanut brittle dessert',
            price: m(2500),
            category: 'Desserts',
          ),
        ],
      ),
      Restaurant(
        id: 'rst-coast',
        name: 'Coast Kitchen',
        cuisine: 'Seafood · Modern',
        rating: 4.7,
        etaMinutes: 35,
        deliveryFee: m(2000),
        imageTone: 1,
        featured: true,
        menu: [
          MenuItem(
            id: 'c1',
            name: 'Prawn Coconut Curry',
            description: 'Coastal prawns, chapati',
            price: m(18000),
            category: 'Mains',
            popular: true,
          ),
          MenuItem(
            id: 'c2',
            name: 'Grilled Calamari',
            description: 'Lemon butter, chili',
            price: m(15000),
            category: 'Starters',
            popular: true,
          ),
          MenuItem(
            id: 'c3',
            name: 'Fish & Chips DSM',
            description: 'Day catch, tartar',
            price: m(13500),
            category: 'Mains',
          ),
          MenuItem(
            id: 'c4',
            name: 'Passion Iced Tea',
            description: 'House blend',
            price: m(4000),
            category: 'Drinks',
          ),
        ],
      ),
      Restaurant(
        id: 'rst-ubongo',
        name: 'Ubongo Bites',
        cuisine: 'Fast · Student favourites',
        rating: 4.5,
        etaMinutes: 22,
        deliveryFee: m(1000),
        imageTone: 2,
        menu: [
          MenuItem(
            id: 'u1',
            name: 'Chipsi Mayai Deluxe',
            description: 'Potato omelette, salad',
            price: m(6500),
            category: 'Mains',
            popular: true,
          ),
          MenuItem(
            id: 'u2',
            name: 'Chicken Shawarma',
            description: 'Garlic sauce wrap',
            price: m(8000),
            category: 'Mains',
            popular: true,
          ),
          MenuItem(
            id: 'u3',
            name: 'Frozy Soda Mix',
            description: 'Ice-cold local sodas',
            price: m(2000),
            category: 'Drinks',
          ),
        ],
      ),
      Restaurant(
        id: 'rst-green',
        name: 'Green Bowl Co.',
        cuisine: 'Healthy · Bowls',
        rating: 4.6,
        etaMinutes: 30,
        deliveryFee: m(1500),
        imageTone: 3,
        menu: [
          MenuItem(
            id: 'g1',
            name: 'Avocado Power Bowl',
            description: 'Quinoa, greens, seeds',
            price: m(11000),
            category: 'Bowls',
            popular: true,
          ),
          MenuItem(
            id: 'g2',
            name: 'Grilled Chicken Salad',
            description: 'Honey mustard',
            price: m(10500),
            category: 'Bowls',
          ),
          MenuItem(
            id: 'g3',
            name: 'Cold Press Orange',
            description: '250ml',
            price: m(4500),
            category: 'Drinks',
          ),
        ],
      ),
    ];
  }
}

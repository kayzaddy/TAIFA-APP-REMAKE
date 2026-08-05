import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taifa/features/food/application/food_providers.dart';
import 'package:taifa/features/food/data/food_catalog.dart';

void main() {
  test('Food catalog has restaurants with menus', () {
    final all = FoodCatalog.all();
    expect(all, isNotEmpty);
    expect(all.first.menu, isNotEmpty);
  });

  test('FoodController can add items and compute totals', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final ctrl = container.read(foodControllerProvider.notifier);
    await ctrl.bootstrap();
    final restaurant = FoodCatalog.all().first;
    ctrl.openRestaurant(restaurant);
    ctrl.addItem(restaurant.menu.first);
    ctrl.addItem(restaurant.menu.first);
    final state = container.read(foodControllerProvider);
    expect(state.cartCount, 2);
    expect(
      state.subtotal.minorUnits,
      restaurant.menu.first.price.minorUnits * 2,
    );
  });
}

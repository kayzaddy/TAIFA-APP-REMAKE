import '../domain/food_models.dart';

abstract interface class RestaurantRepository {
  Future<List<Restaurant>> list({String? query});
  Future<Restaurant> getById(String id);
}

abstract interface class FoodOrderRepository {
  Future<FoodOrder> place(FoodOrder draft);
  Future<FoodOrder> update(FoodOrder order);
  Future<FoodOrder> pay(String orderId);
  Future<List<FoodOrder>> history({int limit = 20});
  Future<FoodOrder> getById(String id);
}

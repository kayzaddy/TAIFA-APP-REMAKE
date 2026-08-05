/// Canonical REST path fragments for commerce food orders.
class FoodApiPaths {
  const FoodApiPaths._();

  static const foodOrders = 'commerce/food-orders';

  static String foodOrder(String orderId) => 'commerce/food-orders/$orderId';

  static String foodOrderPay(String orderId) =>
      'commerce/food-orders/$orderId/pay';
}

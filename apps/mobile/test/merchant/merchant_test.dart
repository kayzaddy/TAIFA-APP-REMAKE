import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taifa/features/merchant/application/merchant_providers.dart';
import 'package:taifa/features/merchant/domain/merchant_models.dart';

void main() {
  test('MerchantController loads orders and advances status', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final ctrl = container.read(merchantControllerProvider.notifier);
    await ctrl.bootstrap();
    final orders = container.read(merchantControllerProvider).orders;
    expect(orders, isNotEmpty);
    final first = orders.firstWhere(
      (o) => o.status == MerchantOrderStatus.newOrder,
    );
    ctrl.open(first);
    await ctrl.advanceSelected();
    expect(
      container.read(merchantControllerProvider).selected?.status,
      MerchantOrderStatus.preparing,
    );
  });
}

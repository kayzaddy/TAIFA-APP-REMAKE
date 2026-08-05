import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taifa/features/winga/application/winga_providers.dart';
import 'package:taifa/features/winga/data/winga_catalog.dart';
import 'package:taifa/features/winga/gateways/winga_gateways.dart';

void main() {
  test('WingaController browses and adds to cart', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final ctrl = container.read(wingaControllerProvider.notifier);
    await ctrl.bootstrap();
    expect(container.read(wingaControllerProvider).stores, isNotEmpty);
    ctrl.openProduct(WingaCatalog.products().first);
    ctrl.addToCart(WingaCatalog.products().first);
    expect(container.read(wingaControllerProvider).phase, WingaPhase.cart);
    expect(container.read(wingaControllerProvider).cartCount, 1);
  });

  test(
    'WingaController checkout pays via wallet and dispatches delivery',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final ctrl = container.read(wingaControllerProvider.notifier);
      await ctrl.bootstrap();
      ctrl.addToCart(WingaCatalog.products().first);
      ctrl.goCheckout();
      await ctrl.payWithWallet();
      final state = container.read(wingaControllerProvider);
      expect(state.phase, WingaPhase.orderConfirm);
      expect(state.order?.paymentRef, isNotNull);
      expect(state.order?.courierName, isNotNull);
    },
  );

  test('MockWingaAiGateway recommends fridge under budget', () async {
    final ai = MockWingaAiGateway();
    final reply = await ai.shopAssist(
      'I need a refrigerator under TSh 900,000',
    );
    expect(reply.toLowerCase(), contains('fridge'));
  });

  test('NEGOTIA returns supplier quotes', () async {
    final ai = MockWingaAiGateway();
    final quotes = await ai.negotiate('I need 500 bags of cement');
    expect(quotes.length, greaterThanOrEqualTo(2));
    expect(quotes.first.qty, 500);
  });

  test('Open shop mock approval reaches merchant dashboard', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final ctrl = container.read(wingaControllerProvider.notifier);
    await ctrl.bootstrap();
    ctrl.openShopFlow();
    ctrl.updateShopDraft(name: 'Kariakoo Test Shop', category: 'Grocery');
    await ctrl.submitShop();
    expect(container.read(wingaControllerProvider).phase, WingaPhase.merchant);
  });
}

import '../../wallet/domain/currency.dart';
import '../../wallet/domain/money.dart';
import '../domain/merchant_models.dart';

class MerchantSeed {
  const MerchantSeed._();

  static List<MerchantOrder> orders() {
    Money m(int major) => Money.major(major, Currency.tzs);
    final now = DateTime.now();
    return [
      MerchantOrder(
        id: 'mo-1',
        customerName: 'Neema K.',
        itemsLabel: '2× Mishkaki · Pilau',
        total: m(33500),
        status: MerchantOrderStatus.newOrder,
        createdAt: now.subtract(const Duration(minutes: 4)),
      ),
      MerchantOrder(
        id: 'mo-2',
        customerName: 'Juma A.',
        itemsLabel: 'Chipsi Mayai · Soda',
        total: m(8500),
        status: MerchantOrderStatus.preparing,
        createdAt: now.subtract(const Duration(minutes: 18)),
      ),
      MerchantOrder(
        id: 'mo-3',
        customerName: 'Asha M.',
        itemsLabel: 'Prawn curry · Iced tea',
        total: m(22000),
        status: MerchantOrderStatus.ready,
        createdAt: now.subtract(const Duration(minutes: 32)),
      ),
      MerchantOrder(
        id: 'mo-4',
        customerName: 'Baraka T.',
        itemsLabel: 'Breakfast platter',
        total: m(18000),
        status: MerchantOrderStatus.completed,
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
    ];
  }
}

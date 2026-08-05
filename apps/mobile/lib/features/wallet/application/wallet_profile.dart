import '../domain/currency.dart';
import '../domain/money.dart';
import '../domain/payment_method.dart';
import '../domain/recipient.dart';
import '../domain/transaction.dart';

/// Static, non-money wallet scaffolding: the card presentation, the user's
/// funding sources and their saved recipients. This is profile data, not
/// balances — it is shared by every repository so the surface looks identical
/// whether money data comes from the seed or the live backend. A dedicated
/// profile service will supply this in a later phase.
class WalletProfile {
  const WalletProfile({
    required this.cardholderName,
    required this.cardTier,
    required this.maskedPan,
    required this.sources,
    required this.recipients,
  });

  final String cardholderName;
  final String cardTier;
  final String maskedPan;
  final List<PaymentMethod> sources;
  final List<Recipient> recipients;
}

const _primaryCard = TaifaWalletMethod(
  id: 'src-platinum',
  label: 'TAIFA Platinum',
  maskedNumber: '•••• 8841 · TSh 2.84M',
);

const defaultWalletProfile = WalletProfile(
  cardholderName: 'Amani Mwamba',
  cardTier: 'TAIFA · PLATINUM',
  maskedPan: '4521 ••• ••• 8841',
  sources: [
    _primaryCard,
    // Safaricom Daraja sandbox STK test MSISDN (use this for live sandbox top-ups).
    MobileMoneyMethod(
      id: 'src-mpesa-sandbox',
      label: 'M-Pesa Sandbox',
      operator: MobileMoneyOperator.mpesa,
      msisdn: '254708374149',
    ),
    MobileMoneyMethod(
      id: 'src-mpesa',
      label: 'M-Pesa',
      operator: MobileMoneyOperator.mpesa,
      msisdn: '+255754000210',
    ),
    CardMethod(
      id: 'src-visa',
      label: 'Visa',
      brand: CardBrand.visa,
      last4: '4291',
    ),
  ],
  recipients: [
    Recipient(
      id: 'rcp-fatima',
      name: 'Fatima Salim',
      handle: '+255 754 ••• 891',
      verified: true,
      method: MobileMoneyMethod(
        id: 'm-fatima',
        label: 'Fatima Salim',
        operator: MobileMoneyOperator.mpesa,
        msisdn: '+255754000891',
      ),
    ),
    Recipient(
      id: 'rcp-juma',
      name: 'Juma Ally',
      handle: '+255 655 ••• 043',
      verified: true,
      method: MobileMoneyMethod(
        id: 'm-juma',
        label: 'Juma Ally',
        operator: MobileMoneyOperator.airtelMoney,
        msisdn: '+255655000043',
      ),
    ),
    Recipient(
      id: 'rcp-neema',
      name: 'Neema Kileo',
      handle: '@neema',
      verified: false,
      method: TaifaWalletMethod(
        id: 'w-neema',
        label: 'Neema Kileo',
        maskedNumber: 'TAIFA · @neema',
      ),
    ),
  ],
);

/// The demo transaction history for the offline/seed path.
List<WalletTransaction> seedTransactions() {
  final now = DateTime.now();
  return [
    WalletTransaction(
      id: 'txn-seed-1',
      type: TransactionType.receiveMoney,
      status: TransactionStatus.succeeded,
      direction: TransactionDirection.credit,
      amount: Money.major(150000, Currency.tzs),
      fee: Money.zero(Currency.tzs),
      counterparty: 'From Mama Grace',
      method: const MobileMoneyMethod(
        id: 'm-grace',
        label: 'Mama Grace',
        operator: MobileMoneyOperator.mpesa,
        msisdn: '+255 713 ••• 002',
      ),
      createdAt: now.subtract(const Duration(hours: 2)),
      idempotencyKey: 'seed-1',
      providerRef: 'MPESA-SEED1',
    ),
    WalletTransaction(
      id: 'txn-seed-2',
      type: TransactionType.rideFare,
      status: TransactionStatus.succeeded,
      direction: TransactionDirection.debit,
      amount: Money.major(6500, Currency.tzs),
      fee: Money.zero(Currency.tzs),
      counterparty: 'Bajaji to Airport',
      method: _primaryCard,
      createdAt: now.subtract(const Duration(hours: 5)),
      idempotencyKey: 'seed-2',
    ),
    WalletTransaction(
      id: 'txn-seed-3',
      type: TransactionType.billPayment,
      status: TransactionStatus.succeeded,
      direction: TransactionDirection.debit,
      amount: Money.major(42000, Currency.tzs),
      fee: Money.zero(Currency.tzs),
      counterparty: 'TANESCO Electricity',
      method: _primaryCard,
      createdAt: now.subtract(const Duration(days: 1)),
      idempotencyKey: 'seed-3',
    ),
  ];
}

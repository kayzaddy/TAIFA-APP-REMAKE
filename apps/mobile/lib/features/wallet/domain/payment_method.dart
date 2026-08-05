/// A funding/destination instrument. Sealed so the router and UI can switch
/// exhaustively. Each method advertises the provider *kind* it needs, but never
/// a concrete provider — routing to a specific adapter is the router's job.
sealed class PaymentMethod {
  const PaymentMethod({required this.id, required this.label});
  final String id;
  final String label;

  String get subtitle;
}

/// The user's in-app TAIFA wallet balance.
class TaifaWalletMethod extends PaymentMethod {
  const TaifaWalletMethod({
    required super.id,
    required super.label,
    required this.maskedNumber,
  });
  final String maskedNumber;

  @override
  String get subtitle => maskedNumber;
}

enum MobileMoneyOperator { mpesa, mixxByYas, airtelMoney, halopesa }

extension MobileMoneyOperatorX on MobileMoneyOperator {
  String get displayName => switch (this) {
    MobileMoneyOperator.mpesa => 'M-Pesa',
    MobileMoneyOperator.mixxByYas => 'Mixx by Yas',
    MobileMoneyOperator.airtelMoney => 'Airtel Money',
    MobileMoneyOperator.halopesa => 'HaloPesa',
  };
}

class MobileMoneyMethod extends PaymentMethod {
  const MobileMoneyMethod({
    required super.id,
    required super.label,
    required this.operator,
    required this.msisdn,
  });
  final MobileMoneyOperator operator;
  final String msisdn; // +255 7XX XXX XXX

  @override
  String get subtitle => '${operator.displayName} · $msisdn';
}

enum CardBrand { visa, mastercard, taifaPlatinum }

class CardMethod extends PaymentMethod {
  const CardMethod({
    required super.id,
    required super.label,
    required this.brand,
    required this.last4,
  });
  final CardBrand brand;
  final String last4;

  @override
  String get subtitle => '•••• $last4';
}

class BankMethod extends PaymentMethod {
  const BankMethod({
    required super.id,
    required super.label,
    required this.bankName,
    required this.accountMasked,
  });
  final String bankName;
  final String accountMasked;

  @override
  String get subtitle => '$bankName · $accountMasked';
}

import '../../features/wallet/domain/currency.dart';
import '../../features/wallet/domain/money.dart';
import '../../features/wallet/domain/payment_method.dart';
import '../../features/wallet/domain/transaction.dart';
import '../api/api_exception.dart';

/// Maps the backend `Transaction` JSON (see `payments/serializers.py`) onto the
/// client's [WalletTransaction] domain object. The wire format is snake_case;
/// enums are the shared string values both cores agree on.
class TransactionDto {
  const TransactionDto._();

  static WalletTransaction toDomain(Map<String, dynamic> json) {
    try {
      final currency = Currency.fromCode(json['currency'] as String);
      return WalletTransaction(
        id: json['id'].toString(),
        type: _type(json['type'] as String?),
        status: _status(json['status'] as String?),
        direction: _direction(json['direction'] as String?),
        amount: Money((json['amount_minor'] as num).toInt(), currency),
        fee: Money((json['fee_minor'] as num?)?.toInt() ?? 0, currency),
        counterparty: (json['counterparty'] as String?) ?? '',
        method: _method(json),
        createdAt:
            DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
        // The idempotency key is a server-side secret and is not echoed back;
        // parsed records carry a stable placeholder.
        idempotencyKey: json['id'].toString(),
        note: (json['note'] as String?)?.isEmpty ?? true
            ? null
            : json['note'] as String,
        providerRef: (json['provider_ref'] as String?)?.isEmpty ?? true
            ? null
            : json['provider_ref'] as String,
        ledgerEntryId: json['ledger_entry']?.toString(),
      );
    } catch (_) {
      throw const ApiDecodeException('Malformed transaction payload.');
    }
  }

  static TransactionType _type(String? raw) => switch (raw) {
    'send_money' => TransactionType.sendMoney,
    'receive_money' => TransactionType.receiveMoney,
    'bill_payment' => TransactionType.billPayment,
    'top_up' => TransactionType.topUp,
    'withdrawal' => TransactionType.withdrawal,
    'merchant_payment' => TransactionType.merchantPayment,
    'refund' => TransactionType.refund,
    'ride_fare' => TransactionType.rideFare,
    _ => TransactionType.sendMoney,
  };

  static TransactionStatus _status(String? raw) => switch (raw) {
    'pending' => TransactionStatus.pending,
    'processing' => TransactionStatus.processing,
    'succeeded' => TransactionStatus.succeeded,
    'failed' => TransactionStatus.failed,
    'reversed' => TransactionStatus.reversed,
    _ => TransactionStatus.pending,
  };

  static TransactionDirection _direction(String? raw) => raw == 'credit'
      ? TransactionDirection.credit
      : TransactionDirection.debit;

  static PaymentMethod _method(Map<String, dynamic> json) {
    final kind = json['method_kind'] as String? ?? 'wallet';
    final ref = json['method_ref'] as String? ?? '';
    final label = (json['counterparty'] as String?) ?? '';
    final operator = json['operator'] as String? ?? '';
    switch (kind) {
      case 'mobile_money':
        return MobileMoneyMethod(
          id: 'm-$ref',
          label: label,
          operator: operatorFromApi(operator),
          msisdn: ref,
        );
      case 'card':
        return CardMethod(
          id: 'c-$ref',
          label: label,
          brand: CardBrand.visa,
          last4: ref,
        );
      case 'bank':
        return BankMethod(
          id: 'b-$ref',
          label: label,
          bankName: operator.isEmpty ? 'Bank' : operator,
          accountMasked: ref,
        );
      default:
        return TaifaWalletMethod(
          id: 'w-$ref',
          label: label,
          maskedNumber: ref.isEmpty ? 'TAIFA Wallet' : ref,
        );
    }
  }
}

MobileMoneyOperator operatorFromApi(String raw) => switch (raw) {
  'mpesa' => MobileMoneyOperator.mpesa,
  'airtel_money' => MobileMoneyOperator.airtelMoney,
  'mixx_by_yas' => MobileMoneyOperator.mixxByYas,
  'halopesa' => MobileMoneyOperator.halopesa,
  _ => MobileMoneyOperator.mpesa,
};

String operatorToApi(MobileMoneyOperator operator) => switch (operator) {
  MobileMoneyOperator.mpesa => 'mpesa',
  MobileMoneyOperator.airtelMoney => 'airtel_money',
  MobileMoneyOperator.mixxByYas => 'mixx_by_yas',
  MobileMoneyOperator.halopesa => 'halopesa',
};

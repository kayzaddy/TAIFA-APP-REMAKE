import '../../features/wallet/domain/currency.dart';
import '../../features/wallet/domain/money.dart';
import '../../features/wallet/domain/transaction.dart';
import '../api/api_exception.dart';
import 'transaction_dto.dart';

/// The money-bearing slice of the wallet returned by `GET /payments/wallet`:
/// the authoritative balance plus recent transactions. Profile scaffolding
/// (card art, saved recipients) is composed on top by the repository.
class WalletDto {
  const WalletDto({required this.balance, required this.transactions});

  final Money balance;
  final List<WalletTransaction> transactions;

  static WalletDto fromJson(Map<String, dynamic> json) {
    try {
      final currency = Currency.fromCode(json['currency'] as String? ?? 'TZS');
      final raw = (json['transactions'] as List?) ?? const [];
      return WalletDto(
        balance: Money((json['balance_minor'] as num).toInt(), currency),
        transactions: raw
            .map((e) => TransactionDto.toDomain(e as Map<String, dynamic>))
            .toList(growable: false),
      );
    } on ApiDecodeException {
      rethrow;
    } catch (_) {
      throw const ApiDecodeException('Malformed wallet payload.');
    }
  }
}

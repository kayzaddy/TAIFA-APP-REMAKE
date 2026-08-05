import '../../features/family/data/family_catalog.dart';
import '../../features/family/domain/family_models.dart';
import '../../features/wallet/domain/currency.dart';
import '../../features/wallet/domain/money.dart';

/// Maps `/api/v1/commerce/family-transfers` JSON ↔ domain [FamilyTransfer].
class FamilyTransferDto {
  const FamilyTransferDto._();

  static FamilyTransfer toDomain(
    Map<String, dynamic> json, {
    FamilyMember? member,
  }) {
    final currency = Currency.fromCode(json['currency'] as String? ?? 'TZS');
    final memberId = json['member_id'] as String? ?? '';
    final amount = Money(
      (json['amount_minor'] as num?)?.toInt() ?? 0,
      currency,
    );
    final pay = (json['payment_ref'] as String?)?.trim();
    final note = (json['note'] as String?)?.trim();

    return FamilyTransfer(
      id: json['id'].toString(),
      member:
          member ??
          _resolveMember(
            memberId,
            json['member_name'] as String? ?? 'Member',
            json['member_role'] as String? ?? '',
            json['member_phone'] as String? ?? '',
          ),
      amount: amount,
      kind: (json['kind'] as String?) == 'request'
          ? FamilyTxKind.request
          : FamilyTxKind.send,
      status: statusFromApi(json['status'] as String? ?? 'paid'),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      note: (note == null || note.isEmpty) ? null : note,
      paymentRef: (pay == null || pay.isEmpty) ? null : pay,
    );
  }

  static Map<String, dynamic> createBody(FamilyTransfer draft) => {
    'member_id': draft.member.id,
    'member_name': draft.member.name,
    'member_role': draft.member.role,
    'member_phone': draft.member.phone,
    'kind': draft.kind == FamilyTxKind.request ? 'request' : 'send',
    'amount_minor': draft.amount.minorUnits,
    'currency': draft.amount.currency.code,
    'status': statusToApi(draft.status),
    if (draft.note != null && draft.note!.isNotEmpty) 'note': draft.note,
    if (draft.paymentRef != null && draft.paymentRef!.isNotEmpty)
      'payment_ref': draft.paymentRef,
  };

  static String statusToApi(FamilyTxStatus status) => switch (status) {
    FamilyTxStatus.drafting || FamilyTxStatus.pending => 'pending',
    FamilyTxStatus.paid => 'paid',
  };

  static FamilyTxStatus statusFromApi(String raw) => switch (raw) {
    'pending' => FamilyTxStatus.pending,
    _ => FamilyTxStatus.paid,
  };

  static FamilyMember _resolveMember(
    String id,
    String name,
    String role,
    String phone,
  ) {
    try {
      return FamilyCatalog.members().firstWhere((m) => m.id == id);
    } catch (_) {
      return FamilyMember(
        id: id.isEmpty ? 'fam-unknown' : id,
        name: name,
        role: role,
        phone: phone,
        allowance: Money.major(0, Currency.tzs),
      );
    }
  }
}

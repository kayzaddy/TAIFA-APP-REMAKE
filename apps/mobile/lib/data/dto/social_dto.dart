import '../../features/wallet/domain/currency.dart';
import '../../features/wallet/domain/money.dart';
import '../api/api_exception.dart';

/// Maps the backend `payments` social-payments JSON (payment links, money
/// requests, split bills, standing orders, contacts, notifications,
/// transaction search, spending analytics/cap) onto small immutable client
/// models. Mirrors the shape of `TransactionDto`/`WalletDto`: snake_case in,
/// typed Dart out, `ApiDecodeException` on anything malformed.

enum PaymentLinkStatus { active, paused, completed, expired }

PaymentLinkStatus _linkStatus(String? raw) => switch (raw) {
  'active' => PaymentLinkStatus.active,
  'paused' => PaymentLinkStatus.paused,
  'completed' => PaymentLinkStatus.completed,
  'expired' => PaymentLinkStatus.expired,
  _ => PaymentLinkStatus.active,
};

class PaymentLink {
  const PaymentLink({
    required this.id,
    required this.slug,
    required this.owner,
    required this.displayName,
    required this.amount,
    required this.note,
    required this.emoji,
    required this.status,
    required this.singleUse,
    required this.feeBps,
    required this.totalPaid,
    required this.paymentCount,
    required this.createdAt,
  });

  final String id;
  final String slug;
  final String owner;
  final String displayName;
  final Money? amount; // null = open amount, payer chooses
  final String note;
  final String emoji;
  final PaymentLinkStatus status;
  final bool singleUse;
  final int feeBps;
  final Money totalPaid;
  final int paymentCount;
  final DateTime createdAt;

  static PaymentLink fromJson(Map<String, dynamic> json) {
    try {
      final currency = Currency.fromCode(json['currency'] as String? ?? 'TZS');
      final amountMinor = json['amount_minor'] as num?;
      return PaymentLink(
        id: json['id'].toString(),
        slug: json['slug'] as String,
        owner: json['owner'] as String? ?? '',
        displayName: (json['display_name'] as String?) ?? '',
        amount: amountMinor == null ? null : Money(amountMinor.toInt(), currency),
        note: (json['note'] as String?) ?? '',
        emoji: (json['emoji'] as String?) ?? '',
        status: _linkStatus(json['status'] as String?),
        singleUse: json['single_use'] as bool? ?? false,
        feeBps: (json['fee_bps'] as num?)?.toInt() ?? 0,
        totalPaid: Money((json['total_paid_minor'] as num?)?.toInt() ?? 0, currency),
        paymentCount: (json['payment_count'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      );
    } catch (_) {
      throw const ApiDecodeException('Malformed payment link payload.');
    }
  }
}

/// What a payer sees before paying — `GET /payments/pay/{slug}` (no auth).
class PaymentLinkPreview {
  const PaymentLinkPreview({
    required this.slug,
    required this.payee,
    required this.amount,
    required this.currency,
    required this.note,
    required this.emoji,
    required this.status,
  });

  final String slug;
  final String payee;
  final Money? amount;
  final Currency currency;
  final String note;
  final String emoji;
  final PaymentLinkStatus status;

  static PaymentLinkPreview fromJson(Map<String, dynamic> json) {
    try {
      final currency = Currency.fromCode(json['currency'] as String? ?? 'TZS');
      final amountMinor = json['amount_minor'] as num?;
      return PaymentLinkPreview(
        slug: json['slug'] as String,
        payee: json['payee'] as String? ?? '',
        amount: amountMinor == null ? null : Money(amountMinor.toInt(), currency),
        currency: currency,
        note: (json['note'] as String?) ?? '',
        emoji: (json['emoji'] as String?) ?? '',
        status: _linkStatus(json['status'] as String?),
      );
    } catch (_) {
      throw const ApiDecodeException('Malformed payment link preview.');
    }
  }
}

enum MoneyRequestStatus { pending, paid, declined, cancelled, expired }

MoneyRequestStatus _requestStatus(String? raw) => switch (raw) {
  'pending' => MoneyRequestStatus.pending,
  'paid' => MoneyRequestStatus.paid,
  'declined' => MoneyRequestStatus.declined,
  'cancelled' => MoneyRequestStatus.cancelled,
  'expired' => MoneyRequestStatus.expired,
  _ => MoneyRequestStatus.pending,
};

class MoneyRequest {
  const MoneyRequest({
    required this.id,
    required this.requester,
    required this.requesterName,
    required this.payer,
    required this.payerName,
    required this.amount,
    required this.note,
    required this.emoji,
    required this.status,
    required this.transactionId,
    required this.createdAt,
  });

  final String id;
  final String requester;
  final String requesterName;
  final String payer;
  final String payerName;
  final Money amount;
  final String note;
  final String emoji;
  final MoneyRequestStatus status;
  final String? transactionId;
  final DateTime createdAt;

  static MoneyRequest fromJson(Map<String, dynamic> json) {
    try {
      final currency = Currency.fromCode(json['currency'] as String? ?? 'TZS');
      return MoneyRequest(
        id: json['id'].toString(),
        requester: json['requester'] as String? ?? '',
        requesterName: (json['requester_name'] as String?) ?? '',
        payer: json['payer'] as String? ?? '',
        payerName: (json['payer_name'] as String?) ?? '',
        amount: Money((json['amount_minor'] as num).toInt(), currency),
        note: (json['note'] as String?) ?? '',
        emoji: (json['emoji'] as String?) ?? '',
        status: _requestStatus(json['status'] as String?),
        transactionId: json['transaction_id'] as String?,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      );
    } catch (_) {
      throw const ApiDecodeException('Malformed money request payload.');
    }
  }
}

enum BillSplitStatus { open, settled, cancelled }

class BillSplit {
  const BillSplit({
    required this.id,
    required this.organizer,
    required this.organizerName,
    required this.title,
    required this.emoji,
    required this.totalAmount,
    required this.status,
    required this.paidAmount,
    required this.shares,
    required this.createdAt,
  });

  final String id;
  final String organizer;
  final String organizerName;
  final String title;
  final String emoji;
  final Money totalAmount;
  final BillSplitStatus status;
  final Money paidAmount;
  final List<MoneyRequest> shares;
  final DateTime createdAt;

  static BillSplit fromJson(Map<String, dynamic> json) {
    try {
      final currency = Currency.fromCode(json['currency'] as String? ?? 'TZS');
      final shares = ((json['shares'] as List?) ?? const [])
          .map((e) => MoneyRequest.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
      return BillSplit(
        id: json['id'].toString(),
        organizer: json['organizer'] as String? ?? '',
        organizerName: (json['organizer_name'] as String?) ?? '',
        title: json['title'] as String? ?? '',
        emoji: (json['emoji'] as String?) ?? '',
        totalAmount: Money((json['total_amount_minor'] as num).toInt(), currency),
        status: switch (json['status'] as String?) {
          'settled' => BillSplitStatus.settled,
          'cancelled' => BillSplitStatus.cancelled,
          _ => BillSplitStatus.open,
        },
        paidAmount: Money((json['paid_amount_minor'] as num?)?.toInt() ?? 0, currency),
        shares: shares,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      );
    } catch (_) {
      throw const ApiDecodeException('Malformed bill split payload.');
    }
  }
}

enum RecurringInterval { daily, weekly, monthly }

enum RecurringStatus { active, paused, cancelled }

class RecurringPayment {
  const RecurringPayment({
    required this.id,
    required this.payee,
    required this.payeeName,
    required this.amount,
    required this.note,
    required this.emoji,
    required this.interval,
    required this.status,
    required this.nextRunAt,
    required this.consecutiveFailures,
  });

  final String id;
  final String payee;
  final String payeeName;
  final Money amount;
  final String note;
  final String emoji;
  final RecurringInterval interval;
  final RecurringStatus status;
  final DateTime nextRunAt;
  final int consecutiveFailures;

  static RecurringPayment fromJson(Map<String, dynamic> json) {
    try {
      final currency = Currency.fromCode(json['currency'] as String? ?? 'TZS');
      return RecurringPayment(
        id: json['id'].toString(),
        payee: json['payee'] as String? ?? '',
        payeeName: (json['payee_name'] as String?) ?? '',
        amount: Money((json['amount_minor'] as num).toInt(), currency),
        note: (json['note'] as String?) ?? '',
        emoji: (json['emoji'] as String?) ?? '',
        interval: switch (json['interval'] as String?) {
          'daily' => RecurringInterval.daily,
          'weekly' => RecurringInterval.weekly,
          _ => RecurringInterval.monthly,
        },
        status: switch (json['status'] as String?) {
          'paused' => RecurringStatus.paused,
          'cancelled' => RecurringStatus.cancelled,
          _ => RecurringStatus.active,
        },
        nextRunAt: DateTime.tryParse(json['next_run_at'] as String? ?? '') ?? DateTime.now(),
        consecutiveFailures: (json['consecutive_failures'] as num?)?.toInt() ?? 0,
      );
    } catch (_) {
      throw const ApiDecodeException('Malformed recurring payment payload.');
    }
  }
}

class TaifaContact {
  const TaifaContact({
    required this.id,
    required this.contactOwner,
    required this.displayName,
    required this.phoneNumber,
    required this.favorite,
  });

  final String id;
  final String contactOwner;
  final String displayName;
  final String phoneNumber;
  final bool favorite;

  static TaifaContact fromJson(Map<String, dynamic> json) {
    try {
      return TaifaContact(
        id: json['id'].toString(),
        contactOwner: json['contact_owner'] as String? ?? '',
        displayName: (json['display_name'] as String?) ?? '',
        phoneNumber: (json['phone_number'] as String?) ?? '',
        favorite: json['favorite'] as bool? ?? false,
      );
    } catch (_) {
      throw const ApiDecodeException('Malformed contact payload.');
    }
  }
}

/// `POST /payments/people/lookup` result.
class PersonLookup {
  const PersonLookup({required this.owner, required this.displayName});
  final String owner;
  final String displayName;

  static PersonLookup fromJson(Map<String, dynamic> json) {
    try {
      return PersonLookup(
        owner: json['owner'] as String,
        displayName: (json['display_name'] as String?) ?? '',
      );
    } catch (_) {
      throw const ApiDecodeException('Malformed person lookup payload.');
    }
  }
}

class TaifaNotification {
  const TaifaNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final bool read;
  final DateTime createdAt;

  static TaifaNotification fromJson(Map<String, dynamic> json) {
    try {
      return TaifaNotification(
        id: json['id'].toString(),
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        read: json['read'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      );
    } catch (_) {
      throw const ApiDecodeException('Malformed notification payload.');
    }
  }
}

class SpendingMonth {
  const SpendingMonth({
    required this.month,
    required this.totalIn,
    required this.totalOut,
    required this.byType,
  });

  final String month; // "2026-08"
  final Money totalIn;
  final Money totalOut;
  final Map<String, int> byType; // type -> minor units out

  static SpendingMonth fromJson(Map<String, dynamic> json, Currency currency) {
    final byType = <String, int>{};
    final raw = json['by_type'] as Map<String, dynamic>? ?? const {};
    for (final entry in raw.entries) {
      byType[entry.key] = (entry.value as num).toInt();
    }
    return SpendingMonth(
      month: json['month'] as String? ?? '',
      totalIn: Money((json['total_in_minor'] as num?)?.toInt() ?? 0, currency),
      totalOut: Money((json['total_out_minor'] as num?)?.toInt() ?? 0, currency),
      byType: byType,
    );
  }
}

class SpendingAnalytics {
  const SpendingAnalytics({required this.currency, required this.months});

  final Currency currency;
  final List<SpendingMonth> months;

  static SpendingAnalytics fromJson(Map<String, dynamic> json) {
    try {
      final currency = Currency.fromCode(json['currency'] as String? ?? 'TZS');
      final months = ((json['months'] as List?) ?? const [])
          .map((e) => SpendingMonth.fromJson(e as Map<String, dynamic>, currency))
          .toList(growable: false);
      return SpendingAnalytics(currency: currency, months: months);
    } catch (_) {
      throw const ApiDecodeException('Malformed spending analytics payload.');
    }
  }
}

enum SpendingCapPeriod { daily, weekly, monthly }

class SpendingCap {
  const SpendingCap({
    required this.period,
    required this.limit,
    required this.spent,
    required this.remaining,
  });

  final SpendingCapPeriod period;
  final Money limit;
  final Money spent;
  final Money remaining;

  static SpendingCap fromJson(Map<String, dynamic> json) {
    try {
      final currency = Currency.fromCode(json['currency'] as String? ?? 'TZS');
      return SpendingCap(
        period: switch (json['period'] as String?) {
          'daily' => SpendingCapPeriod.daily,
          'weekly' => SpendingCapPeriod.weekly,
          _ => SpendingCapPeriod.monthly,
        },
        limit: Money((json['limit_minor'] as num).toInt(), currency),
        spent: Money((json['spent_minor'] as num?)?.toInt() ?? 0, currency),
        remaining: Money((json['remaining_minor'] as num?)?.toInt() ?? 0, currency),
      );
    } catch (_) {
      throw const ApiDecodeException('Malformed spending cap payload.');
    }
  }
}

String spendingCapPeriodToApi(SpendingCapPeriod p) => switch (p) {
  SpendingCapPeriod.daily => 'daily',
  SpendingCapPeriod.weekly => 'weekly',
  SpendingCapPeriod.monthly => 'monthly',
};

String recurringIntervalToApi(RecurringInterval i) => switch (i) {
  RecurringInterval.daily => 'daily',
  RecurringInterval.weekly => 'weekly',
  RecurringInterval.monthly => 'monthly',
};

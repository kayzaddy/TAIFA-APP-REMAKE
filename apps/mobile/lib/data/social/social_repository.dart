import '../../features/wallet/domain/currency.dart';
import '../../features/wallet/domain/money.dart';
import '../../features/wallet/domain/transaction.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../dto/social_dto.dart';
import '../dto/transaction_dto.dart';
import 'social_api_paths.dart';

/// Domain-level failure surfaced by [SocialRepository] — mirrors
/// `WalletException`. The UI never sees raw [ApiException]s.
class SocialException implements Exception {
  const SocialException(this.message, {this.code});
  final String message;
  final String? code;

  @override
  String toString() => 'SocialException: $message';
}

class TransactionPage {
  const TransactionPage({
    required this.count,
    required this.page,
    required this.numPages,
    required this.results,
  });
  final int count;
  final int page;
  final int numPages;
  final List<WalletTransaction> results;
}

/// One repository for the whole social-payments surface — these all belong to
/// the same backend app and the same "money + people" bounded context, so one
/// cohesive interface beats nine near-identical ones. REST-only for now (no
/// offline/seed twin — these are inherently multi-party features that don't
/// have a meaningful single-user simulation); requires
/// `--dart-define=TAIFA_USE_REMOTE=true` against a live backend.
abstract interface class SocialRepository {
  // --- payment links ---
  Future<List<PaymentLink>> listLinks();
  Future<PaymentLink> createLink({
    Money? amount,
    required Currency currency,
    String note,
    String emoji,
    String displayName,
    bool singleUse,
    int? expiresInHours,
  });
  Future<PaymentLink> pauseLink(String id);
  Future<PaymentLink> resumeLink(String id);
  Future<PaymentLinkPreview> previewLink(String slug);
  Future<WalletTransaction> payLink(String slug, {Money? amount});
  Future<PaymentLink> myQr();

  // --- money requests ---
  Future<({List<MoneyRequest> sent, List<MoneyRequest> received})> listRequests();
  Future<MoneyRequest> createRequest({
    String? payer,
    String? payerPhone,
    required Money amount,
    String note,
    String emoji,
  });
  Future<MoneyRequest> payRequest(String id);
  Future<MoneyRequest> declineRequest(String id);
  Future<MoneyRequest> cancelRequest(String id);

  // --- split bills ---
  Future<({List<BillSplit> organized, List<BillSplit> owing})> listBills();
  Future<BillSplit> createBill({
    required String title,
    String emoji,
    required Currency currency,
    required Money totalAmount,
    required bool evenSplit,
    required List<({String? payer, String? phone, Money? amount})> participants,
  });
  Future<BillSplit> getBill(String id);
  Future<BillSplit> cancelBill(String id);

  // --- recurring payments ---
  Future<List<RecurringPayment>> listRecurring();
  Future<RecurringPayment> createRecurring({
    String? payee,
    String? payeePhone,
    required Money amount,
    required RecurringInterval interval,
    String note,
    String emoji,
  });
  Future<RecurringPayment> pauseRecurring(String id);
  Future<RecurringPayment> resumeRecurring(String id);
  Future<RecurringPayment> cancelRecurring(String id);

  // --- contacts + phone identity ---
  Future<PersonLookup> lookupByPhone(String phoneNumber);
  Future<List<TaifaContact>> listContacts();
  Future<TaifaContact> addContact(String phoneNumber, {String label});
  Future<void> removeContact(String id);
  Future<TaifaContact> toggleFavorite(String id, bool favorite);
  Future<void> setMyProfile({String? phoneNumber, String? displayName});
  Future<({bool isMerchant, int feeBps})> setMerchantMode(bool enable);

  // --- notifications ---
  Future<({int unreadCount, List<TaifaNotification> notifications})> listNotifications();
  Future<TaifaNotification> markNotificationRead(String id);

  // --- transaction search ---
  Future<TransactionPage> searchTransactions({
    String? type,
    String? status,
    String? direction,
    int? minAmountMinor,
    int? maxAmountMinor,
    String? query,
    int page,
    int pageSize,
  });

  // --- analytics + spending cap ---
  Future<SpendingAnalytics> spendingAnalytics({int months, Currency currency});
  Future<SpendingCap?> getSpendingCap();
  Future<SpendingCap> setSpendingCap({
    required SpendingCapPeriod period,
    required Money limit,
  });
  Future<void> clearSpendingCap();
}

class RestSocialRepository implements SocialRepository {
  RestSocialRepository(this._client);
  final TaifaApiClient _client;

  SocialException _toException(ApiException e) {
    if (e is ApiStatusException) {
      final detail = e.body?['detail'];
      return SocialException(
        detail is String ? detail : e.message,
        code: e.body?['code'] as String?,
      );
    }
    return SocialException(e.message);
  }

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on ApiException catch (e) {
      throw _toException(e);
    }
  }

  // --- payment links ---

  @override
  Future<List<PaymentLink>> listLinks() => _guard(() async {
    final json = await _client.getJson(SocialApiPaths.links);
    final raw = (json['links'] as List?) ?? const [];
    return raw.map((e) => PaymentLink.fromJson(e as Map<String, dynamic>)).toList(growable: false);
  });

  @override
  Future<PaymentLink> createLink({
    Money? amount,
    required Currency currency,
    String note = '',
    String emoji = '',
    String displayName = '',
    bool singleUse = false,
    int? expiresInHours,
  }) => _guard(() async {
    final json = await _client.postJson(
      SocialApiPaths.links,
      body: {
        if (amount != null) 'amount_minor': amount.minorUnits,
        'currency': currency.code,
        'note': note,
        'emoji': emoji,
        'display_name': displayName,
        'single_use': singleUse,
        if (expiresInHours != null) 'expires_in_hours': expiresInHours,
      },
    );
    return PaymentLink.fromJson(json);
  });

  @override
  Future<PaymentLink> pauseLink(String id) => _guard(() async {
    final json = await _client.postJson(SocialApiPaths.linkAction(id, 'pause'));
    return PaymentLink.fromJson(json);
  });

  @override
  Future<PaymentLink> resumeLink(String id) => _guard(() async {
    final json = await _client.postJson(SocialApiPaths.linkAction(id, 'resume'));
    return PaymentLink.fromJson(json);
  });

  @override
  Future<PaymentLinkPreview> previewLink(String slug) => _guard(() async {
    final json = await _client.getJson(SocialApiPaths.payLinkInfo(slug));
    return PaymentLinkPreview.fromJson(json);
  });

  @override
  Future<WalletTransaction> payLink(String slug, {Money? amount}) => _guard(() async {
    final json = await _client.postJson(
      SocialApiPaths.payLinkConfirm(slug),
      body: {if (amount != null) 'amount_minor': amount.minorUnits},
      idempotencyKey: 'link-pay-$slug-${DateTime.now().microsecondsSinceEpoch}',
    );
    return TransactionDto.toDomain(json);
  });

  @override
  Future<PaymentLink> myQr() => _guard(() async {
    final json = await _client.getJson(SocialApiPaths.walletQr);
    return PaymentLink.fromJson(json);
  });

  // --- money requests ---

  @override
  Future<({List<MoneyRequest> sent, List<MoneyRequest> received})> listRequests() => _guard(() async {
    final json = await _client.getJson(SocialApiPaths.requests);
    final sent = ((json['sent'] as List?) ?? const [])
        .map((e) => MoneyRequest.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    final received = ((json['received'] as List?) ?? const [])
        .map((e) => MoneyRequest.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return (sent: sent, received: received);
  });

  @override
  Future<MoneyRequest> createRequest({
    String? payer,
    String? payerPhone,
    required Money amount,
    String note = '',
    String emoji = '',
  }) => _guard(() async {
    final json = await _client.postJson(
      SocialApiPaths.requests,
      body: {
        if (payer != null) 'payer': payer,
        if (payerPhone != null) 'payer_phone': payerPhone,
        'amount_minor': amount.minorUnits,
        'currency': amount.currency.code,
        'note': note,
        'emoji': emoji,
      },
    );
    return MoneyRequest.fromJson(json);
  });

  @override
  Future<MoneyRequest> payRequest(String id) => _guard(() async {
    final json = await _client.postJson(
      SocialApiPaths.requestAction(id, 'pay'),
      idempotencyKey: 'req-pay-$id-${DateTime.now().microsecondsSinceEpoch}',
    );
    return MoneyRequest.fromJson(json);
  });

  @override
  Future<MoneyRequest> declineRequest(String id) => _guard(() async {
    final json = await _client.postJson(SocialApiPaths.requestAction(id, 'decline'));
    return MoneyRequest.fromJson(json);
  });

  @override
  Future<MoneyRequest> cancelRequest(String id) => _guard(() async {
    final json = await _client.postJson(SocialApiPaths.requestAction(id, 'cancel'));
    return MoneyRequest.fromJson(json);
  });

  // --- split bills ---

  @override
  Future<({List<BillSplit> organized, List<BillSplit> owing})> listBills() => _guard(() async {
    final json = await _client.getJson(SocialApiPaths.bills);
    final organized = ((json['organized'] as List?) ?? const [])
        .map((e) => BillSplit.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    final owing = ((json['owing'] as List?) ?? const [])
        .map((e) => BillSplit.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return (organized: organized, owing: owing);
  });

  @override
  Future<BillSplit> createBill({
    required String title,
    String emoji = '',
    required Currency currency,
    required Money totalAmount,
    required bool evenSplit,
    required List<({String? payer, String? phone, Money? amount})> participants,
  }) => _guard(() async {
    final json = await _client.postJson(
      SocialApiPaths.bills,
      body: {
        'title': title,
        'emoji': emoji,
        'currency': currency.code,
        'total_amount_minor': totalAmount.minorUnits,
        'split_type': evenSplit ? 'even' : 'custom',
        'participants': [
          for (final p in participants)
            {
              if (p.payer != null) 'payer': p.payer,
              if (p.phone != null) 'phone_number': p.phone,
              if (p.amount != null) 'amount_minor': p.amount!.minorUnits,
            },
        ],
      },
    );
    return BillSplit.fromJson(json);
  });

  @override
  Future<BillSplit> getBill(String id) => _guard(() async {
    final json = await _client.getJson(SocialApiPaths.bill(id));
    return BillSplit.fromJson(json);
  });

  @override
  Future<BillSplit> cancelBill(String id) => _guard(() async {
    final json = await _client.postJson(SocialApiPaths.billCancel(id));
    return BillSplit.fromJson(json);
  });

  // --- recurring payments ---

  @override
  Future<List<RecurringPayment>> listRecurring() => _guard(() async {
    final json = await _client.getJson(SocialApiPaths.recurring);
    final raw = (json['recurring_payments'] as List?) ?? const [];
    return raw.map((e) => RecurringPayment.fromJson(e as Map<String, dynamic>)).toList(growable: false);
  });

  @override
  Future<RecurringPayment> createRecurring({
    String? payee,
    String? payeePhone,
    required Money amount,
    required RecurringInterval interval,
    String note = '',
    String emoji = '',
  }) => _guard(() async {
    final json = await _client.postJson(
      SocialApiPaths.recurring,
      body: {
        if (payee != null) 'payee': payee,
        if (payeePhone != null) 'payee_phone': payeePhone,
        'amount_minor': amount.minorUnits,
        'currency': amount.currency.code,
        'interval': recurringIntervalToApi(interval),
        'note': note,
        'emoji': emoji,
      },
    );
    return RecurringPayment.fromJson(json);
  });

  @override
  Future<RecurringPayment> pauseRecurring(String id) => _guard(() async {
    final json = await _client.postJson(SocialApiPaths.recurringAction(id, 'pause'));
    return RecurringPayment.fromJson(json);
  });

  @override
  Future<RecurringPayment> resumeRecurring(String id) => _guard(() async {
    final json = await _client.postJson(SocialApiPaths.recurringAction(id, 'resume'));
    return RecurringPayment.fromJson(json);
  });

  @override
  Future<RecurringPayment> cancelRecurring(String id) => _guard(() async {
    final json = await _client.postJson(SocialApiPaths.recurringAction(id, 'cancel'));
    return RecurringPayment.fromJson(json);
  });

  // --- contacts + phone identity ---

  @override
  Future<PersonLookup> lookupByPhone(String phoneNumber) => _guard(() async {
    final json = await _client.postJson(SocialApiPaths.peopleLookup, body: {'phone_number': phoneNumber});
    return PersonLookup.fromJson(json);
  });

  @override
  Future<List<TaifaContact>> listContacts() => _guard(() async {
    final json = await _client.getJson(SocialApiPaths.contacts);
    final raw = (json['contacts'] as List?) ?? const [];
    return raw.map((e) => TaifaContact.fromJson(e as Map<String, dynamic>)).toList(growable: false);
  });

  @override
  Future<TaifaContact> addContact(String phoneNumber, {String label = ''}) => _guard(() async {
    final json = await _client.postJson(
      SocialApiPaths.contacts,
      body: {'phone_number': phoneNumber, if (label.isNotEmpty) 'label': label},
    );
    return TaifaContact.fromJson(json);
  });

  @override
  Future<void> removeContact(String id) => _guard(() => _client.deleteJson(SocialApiPaths.contact(id)));

  @override
  Future<TaifaContact> toggleFavorite(String id, bool favorite) => _guard(() async {
    final json = await _client.postJson(
      SocialApiPaths.contactAction(id, favorite ? 'favorite' : 'unfavorite'),
    );
    return TaifaContact.fromJson(json);
  });

  @override
  Future<void> setMyProfile({String? phoneNumber, String? displayName}) => _guard(() async {
    await _client.postJson(
      SocialApiPaths.deviceProfile,
      body: {
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (displayName != null) 'display_name': displayName,
      },
    );
  });

  @override
  Future<({bool isMerchant, int feeBps})> setMerchantMode(bool enable) => _guard(() async {
    final json = await _client.postJson(SocialApiPaths.deviceMerchant, body: {'enable': enable});
    return (isMerchant: json['is_merchant'] as bool, feeBps: (json['fee_bps'] as num).toInt());
  });

  // --- notifications ---

  @override
  Future<({int unreadCount, List<TaifaNotification> notifications})> listNotifications() => _guard(() async {
    final json = await _client.getJson(SocialApiPaths.notifications);
    final raw = (json['notifications'] as List?) ?? const [];
    return (
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      notifications: raw.map((e) => TaifaNotification.fromJson(e as Map<String, dynamic>)).toList(growable: false),
    );
  });

  @override
  Future<TaifaNotification> markNotificationRead(String id) => _guard(() async {
    final json = await _client.postJson(SocialApiPaths.notificationRead(id));
    return TaifaNotification.fromJson(json);
  });

  // --- transaction search ---

  @override
  Future<TransactionPage> searchTransactions({
    String? type,
    String? status,
    String? direction,
    int? minAmountMinor,
    int? maxAmountMinor,
    String? query,
    int page = 1,
    int pageSize = 20,
  }) => _guard(() async {
    final q = <String, String>{
      'page': '$page',
      'page_size': '$pageSize',
      if (type != null) 'type': type,
      if (status != null) 'status': status,
      if (direction != null) 'direction': direction,
      if (minAmountMinor != null) 'min_amount_minor': '$minAmountMinor',
      if (maxAmountMinor != null) 'max_amount_minor': '$maxAmountMinor',
      if (query != null && query.isNotEmpty) 'q': query,
    };
    final json = await _client.getJson(SocialApiPaths.transactionsSearch(q));
    final results = ((json['results'] as List?) ?? const [])
        .map((e) => TransactionDto.toDomain(e as Map<String, dynamic>))
        .toList(growable: false);
    return TransactionPage(
      count: (json['count'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      numPages: (json['num_pages'] as num?)?.toInt() ?? 1,
      results: results,
    );
  });

  // --- analytics + spending cap ---

  @override
  Future<SpendingAnalytics> spendingAnalytics({int months = 6, Currency currency = Currency.tzs}) => _guard(() async {
    final json = await _client.getJson(
      'payments/analytics/spending?months=$months&currency=${currency.code}',
    );
    return SpendingAnalytics.fromJson(json);
  });

  @override
  Future<SpendingCap?> getSpendingCap() async {
    try {
      final json = await _client.getJson(SocialApiPaths.spendingCap);
      return SpendingCap.fromJson(json);
    } on ApiStatusException catch (e) {
      if (e.statusCode == 204) return null;
      throw _toException(e);
    } on ApiDecodeException {
      // A 204 with an empty body decodes to nothing — treated as "no cap".
      return null;
    } on ApiException catch (e) {
      throw _toException(e);
    }
  }

  @override
  Future<SpendingCap> setSpendingCap({
    required SpendingCapPeriod period,
    required Money limit,
  }) => _guard(() async {
    final json = await _client.postJson(
      SocialApiPaths.spendingCap,
      body: {
        'period': spendingCapPeriodToApi(period),
        'limit_minor': limit.minorUnits,
        'currency': limit.currency.code,
      },
    );
    return SpendingCap.fromJson(json);
  });

  @override
  Future<void> clearSpendingCap() => _guard(() => _client.deleteJson(SocialApiPaths.spendingCap));
}

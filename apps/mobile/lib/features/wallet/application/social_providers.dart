import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/dto/social_dto.dart';
import '../../../data/social/social_repository.dart';
import 'wallet_providers.dart';

/// The social-payments repository. REST-only (see `SocialRepository` doc) —
/// meaningful only when `TAIFA_USE_REMOTE=true`; screens should check
/// `apiConfigProvider.useRemoteBackend` and show a "connect a live backend"
/// state rather than watch the providers below when it's false.
final socialRepositoryProvider = Provider<SocialRepository>((ref) {
  return RestSocialRepository(ref.watch(apiClientProvider));
});

/// After any mutation (create/pause/pay/decline/...), call
/// `ref.invalidate(...)` on the relevant provider(s) below to refetch.

final paymentLinksProvider = FutureProvider.autoDispose<List<PaymentLink>>(
  (ref) => ref.watch(socialRepositoryProvider).listLinks(),
);

final myQrLinkProvider = FutureProvider.autoDispose<PaymentLink>(
  (ref) => ref.watch(socialRepositoryProvider).myQr(),
);

final moneyRequestsProvider =
    FutureProvider.autoDispose<({List<MoneyRequest> sent, List<MoneyRequest> received})>(
      (ref) => ref.watch(socialRepositoryProvider).listRequests(),
    );

final billsProvider =
    FutureProvider.autoDispose<({List<BillSplit> organized, List<BillSplit> owing})>(
      (ref) => ref.watch(socialRepositoryProvider).listBills(),
    );

final billDetailProvider = FutureProvider.autoDispose.family<BillSplit, String>(
  (ref, id) => ref.watch(socialRepositoryProvider).getBill(id),
);

final recurringPaymentsProvider = FutureProvider.autoDispose<List<RecurringPayment>>(
  (ref) => ref.watch(socialRepositoryProvider).listRecurring(),
);

final contactsProvider = FutureProvider.autoDispose<List<TaifaContact>>(
  (ref) => ref.watch(socialRepositoryProvider).listContacts(),
);

final notificationsProvider =
    FutureProvider.autoDispose<({int unreadCount, List<TaifaNotification> notifications})>(
      (ref) => ref.watch(socialRepositoryProvider).listNotifications(),
    );

final spendingCapProvider = FutureProvider.autoDispose<SpendingCap?>(
  (ref) => ref.watch(socialRepositoryProvider).getSpendingCap(),
);

final spendingAnalyticsProvider = FutureProvider.autoDispose.family<SpendingAnalytics, int>(
  (ref, months) => ref.watch(socialRepositoryProvider).spendingAnalytics(months: months),
);

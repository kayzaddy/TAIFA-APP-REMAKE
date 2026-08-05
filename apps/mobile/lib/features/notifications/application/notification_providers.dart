import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/notification_models.dart';

abstract interface class NotificationRepository {
  Future<List<AppNotification>> list();
  Future<List<AppNotification>> markRead(String id);
  Future<List<AppNotification>> markAllRead();
}

class SeedNotificationRepository implements NotificationRepository {
  List<AppNotification> _items = [
    AppNotification(
      id: 'n1',
      title: 'Ride completed',
      body: 'Your trip to Mikocheni is done. Receipt is ready.',
      kind: NotifKind.ride,
      at: DateTime.now().subtract(const Duration(minutes: 18)),
    ),
    AppNotification(
      id: 'n2',
      title: 'Food on the way',
      body: 'Asha M. is delivering from Spice Bazaar.',
      kind: NotifKind.food,
      at: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    AppNotification(
      id: 'n3',
      title: 'Wallet transfer settled',
      body: 'TSh 25,000 sent successfully.',
      kind: NotifKind.payment,
      at: DateTime.now().subtract(const Duration(hours: 5)),
      read: true,
    ),
    AppNotification(
      id: 'n4',
      title: 'Zanzibar Weekend',
      body: 'Flights from TSh 145,000 · tap to explore.',
      kind: NotifKind.promo,
      at: DateTime.now().subtract(const Duration(days: 1)),
    ),
    AppNotification(
      id: 'n5',
      title: 'Security tip',
      body: 'Enable biometric unlock in Settings when available.',
      kind: NotifKind.system,
      at: DateTime.now().subtract(const Duration(days: 2)),
      read: true,
    ),
  ];

  @override
  Future<List<AppNotification>> list() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return List.unmodifiable(_items);
  }

  @override
  Future<List<AppNotification>> markRead(String id) async {
    _items = [
      for (final n in _items)
        if (n.id == id) n.copyWith(read: true) else n,
    ];
    return list();
  }

  @override
  Future<List<AppNotification>> markAllRead() async {
    _items = [for (final n in _items) n.copyWith(read: true)];
    return list();
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => SeedNotificationRepository(),
);

class NotificationsUiState {
  const NotificationsUiState({
    this.items = const [],
    this.isBusy = false,
    this.error,
  });

  final List<AppNotification> items;
  final bool isBusy;
  final String? error;

  int get unreadCount => items.where((n) => !n.read).length;

  NotificationsUiState copyWith({
    List<AppNotification>? items,
    bool? isBusy,
    String? error,
    bool clearError = false,
  }) {
    return NotificationsUiState(
      items: items ?? this.items,
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class NotificationsController extends Notifier<NotificationsUiState> {
  NotificationRepository get _repo => ref.read(notificationRepositoryProvider);

  @override
  NotificationsUiState build() => const NotificationsUiState(isBusy: true);

  Future<void> bootstrap() async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final items = await _repo.list();
      state = state.copyWith(items: items, isBusy: false);
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> open(String id) async {
    final items = await _repo.markRead(id);
    state = state.copyWith(items: items);
  }

  Future<void> markAll() async {
    final items = await _repo.markAllRead();
    state = state.copyWith(items: items);
  }
}

final notificationsControllerProvider =
    NotifierProvider<NotificationsController, NotificationsUiState>(
      NotificationsController.new,
    );

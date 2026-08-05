import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taifa/features/notifications/application/notification_providers.dart';

void main() {
  test('Notifications mark all read', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final ctrl = container.read(notificationsControllerProvider.notifier);
    await ctrl.bootstrap();
    expect(
      container.read(notificationsControllerProvider).unreadCount,
      greaterThan(0),
    );
    await ctrl.markAll();
    expect(container.read(notificationsControllerProvider).unreadCount, 0);
  });
}

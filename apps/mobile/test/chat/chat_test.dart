import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taifa/features/chat/application/chat_providers.dart';
import 'package:taifa/features/chat/domain/chat_models.dart';

void main() {
  test('ChatController opens thread and sends message', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final ctrl = container.read(chatControllerProvider.notifier);
    await ctrl.bootstrap();
    final thread = container.read(chatControllerProvider).threads.first;
    await ctrl.open(thread);
    final before = container.read(chatControllerProvider).messages.length;
    await ctrl.send('Asante');
    final after = container.read(chatControllerProvider).messages;
    expect(after.length, before + 1);
    expect(after.last.sender, ChatSender.me);
  });
}

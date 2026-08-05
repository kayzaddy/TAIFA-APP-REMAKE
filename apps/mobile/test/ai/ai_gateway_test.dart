import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taifa/features/ai/application/ai_providers.dart';
import 'package:taifa/features/ai/domain/ai_models.dart';
import 'package:taifa/features/ai/gateways/ai_gateway.dart';

void main() {
  test('MockAiGateway answers ride intent', () async {
    final gateway = MockAiGateway();
    final reply = await gateway.complete(
      history: const [],
      userText: 'How do I book a ride?',
    );
    expect(reply.role, ChatRole.assistant);
    expect(reply.text.toLowerCase(), contains('ride'));
  });

  test('AiController appends user and assistant messages', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final ctrl = container.read(aiControllerProvider.notifier);
    await ctrl.send('Habari TAIFA');
    final state = container.read(aiControllerProvider);
    expect(state.messages.length, greaterThanOrEqualTo(3));
    expect(state.messages.last.role, ChatRole.assistant);
  });
}

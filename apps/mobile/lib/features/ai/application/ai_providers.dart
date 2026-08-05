import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/ai_models.dart';
import '../gateways/ai_gateway.dart';

final aiGatewayProvider = Provider<AiGateway>((ref) => MockAiGateway());

class AiUiState {
  const AiUiState({
    this.messages = const [],
    this.isTyping = false,
    this.error,
  });

  final List<ChatMessage> messages;
  final bool isTyping;
  final String? error;

  AiUiState copyWith({
    List<ChatMessage>? messages,
    bool? isTyping,
    String? error,
    bool clearError = false,
  }) {
    return AiUiState(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AiController extends Notifier<AiUiState> {
  int _seq = 0;
  AiGateway get _gateway => ref.read(aiGatewayProvider);

  static const suggestions = <AiSuggestion>[
    AiSuggestion(label: 'Habari', prompt: 'Habari TAIFA'),
    AiSuggestion(label: 'Ride help', prompt: 'How do I book a ride?'),
    AiSuggestion(label: 'Zanzibar flight', prompt: 'Find a flight to Zanzibar'),
    AiSuggestion(label: 'Wallet', prompt: 'How does my wallet work?'),
  ];

  @override
  AiUiState build() {
    return AiUiState(
      messages: [
        ChatMessage(
          id: 'welcome',
          role: ChatRole.assistant,
          text:
              'Karibu. I\'m TAIFA AI — Swahili-first, Tanzania-aware. Ask me about rides, food, stays, flights, tours or your wallet.',
          at: DateTime.now(),
        ),
      ],
    );
  }

  Future<void> send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || state.isTyping) return;
    final user = ChatMessage(
      id: 'u-${DateTime.now().millisecondsSinceEpoch}-${_seq++}',
      role: ChatRole.user,
      text: text,
      at: DateTime.now(),
    );
    state = state.copyWith(
      messages: [...state.messages, user],
      isTyping: true,
      clearError: true,
    );
    try {
      final reply = await _gateway.complete(
        history: state.messages,
        userText: text,
      );
      state = state.copyWith(
        messages: [...state.messages, reply],
        isTyping: false,
      );
    } catch (e) {
      state = state.copyWith(isTyping: false, error: e.toString());
    }
  }

  void clearChat() {
    state = build();
  }
}

final aiControllerProvider = NotifierProvider<AiController, AiUiState>(
  AiController.new,
);

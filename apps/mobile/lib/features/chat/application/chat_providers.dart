import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/chat/rest_chat_repository.dart';
import '../../wallet/application/wallet_providers.dart'
    show apiClientProvider, apiConfigProvider;
import '../domain/chat_models.dart';
import 'chat_repository.dart';

/// Seed offline, or live inbox when `TAIFA_USE_REMOTE=true`.
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final config = ref.watch(apiConfigProvider);
  if (config.useRemoteBackend) {
    return RestChatRepository(ref.watch(apiClientProvider));
  }
  return SeedChatRepository();
});

enum ChatPhase { inbox, thread }

class ChatUiState {
  const ChatUiState({
    this.phase = ChatPhase.inbox,
    this.threads = const [],
    this.activeThread,
    this.messages = const [],
    this.isBusy = false,
    this.error,
  });

  final ChatPhase phase;
  final List<ChatThread> threads;
  final ChatThread? activeThread;
  final List<ChatMessage> messages;
  final bool isBusy;
  final String? error;

  ChatUiState copyWith({
    ChatPhase? phase,
    List<ChatThread>? threads,
    ChatThread? activeThread,
    List<ChatMessage>? messages,
    bool? isBusy,
    String? error,
    bool clearActive = false,
    bool clearError = false,
  }) {
    return ChatUiState(
      phase: phase ?? this.phase,
      threads: threads ?? this.threads,
      activeThread: clearActive ? null : (activeThread ?? this.activeThread),
      messages: messages ?? this.messages,
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ChatController extends Notifier<ChatUiState> {
  ChatRepository get _repo => ref.read(chatRepositoryProvider);

  @override
  ChatUiState build() => const ChatUiState(isBusy: true);

  Future<void> bootstrap() async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final threads = await _repo.threads();
      state = state.copyWith(
        threads: threads,
        isBusy: false,
        phase: ChatPhase.inbox,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> open(ChatThread thread) async {
    state = state.copyWith(
      isBusy: true,
      activeThread: thread,
      phase: ChatPhase.thread,
      clearError: true,
    );
    try {
      final msgs = await _repo.messages(thread.id);
      state = state.copyWith(messages: msgs, isBusy: false);
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  void backInbox() => state = state.copyWith(
    phase: ChatPhase.inbox,
    clearActive: true,
    messages: const [],
  );

  Future<void> send(String text) async {
    final thread = state.activeThread;
    final t = text.trim();
    if (thread == null || t.isEmpty) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      await _repo.send(thread.id, t);
      final msgs = await _repo.messages(thread.id);
      final threads = await _repo.threads();
      state = state.copyWith(messages: msgs, threads: threads, isBusy: false);
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }
}

final chatControllerProvider = NotifierProvider<ChatController, ChatUiState>(
  ChatController.new,
);

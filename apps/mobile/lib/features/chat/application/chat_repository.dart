import '../data/chat_seed.dart';
import '../domain/chat_models.dart';

abstract interface class ChatRepository {
  Future<List<ChatThread>> threads();
  Future<List<ChatMessage>> messages(String threadId);
  Future<ChatMessage> send(String threadId, String text);
}

class SeedChatRepository implements ChatRepository {
  final Map<String, List<ChatMessage>> _msgs = {
    for (final t in ChatSeed.threads()) t.id: ChatSeed.messagesFor(t.id),
  };
  List<ChatThread> _threads = ChatSeed.threads();
  int _seq = 0;

  @override
  Future<List<ChatThread>> threads() async {
    await Future<void>.delayed(const Duration(milliseconds: 160));
    return List.unmodifiable(_threads);
  }

  @override
  Future<List<ChatMessage>> messages(String threadId) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return List.unmodifiable(_msgs[threadId] ?? const []);
  }

  @override
  Future<ChatMessage> send(String threadId, String text) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final msg = ChatMessage(
      id: 'out-${DateTime.now().millisecondsSinceEpoch}-${_seq++}',
      threadId: threadId,
      sender: ChatSender.me,
      text: text,
      at: DateTime.now(),
    );
    _msgs[threadId] = [...(_msgs[threadId] ?? const []), msg];
    _threads = [
      for (final t in _threads)
        if (t.id == threadId)
          ChatThread(
            id: t.id,
            title: t.title,
            subtitle: text,
            unread: 0,
            updatedAt: DateTime.now(),
          )
        else
          t,
    ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return msg;
  }
}

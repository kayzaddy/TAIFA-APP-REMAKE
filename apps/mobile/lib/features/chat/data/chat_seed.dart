import '../domain/chat_models.dart';

class ChatSeed {
  const ChatSeed._();

  static List<ChatThread> threads() {
    final now = DateTime.now();
    return [
      ChatThread(
        id: 'th-driver',
        title: 'Driver · PW 401 trip',
        subtitle: 'Niko karibu — dakika 3',
        unread: 1,
        updatedAt: now.subtract(const Duration(minutes: 3)),
      ),
      ChatThread(
        id: 'th-support',
        title: 'TAIFA Support',
        subtitle: 'Karibu! How can we help?',
        unread: 0,
        updatedAt: now.subtract(const Duration(hours: 2)),
      ),
      ChatThread(
        id: 'th-family',
        title: 'Family Wallet',
        subtitle: 'Asante for the school fees',
        unread: 2,
        updatedAt: now.subtract(const Duration(hours: 5)),
      ),
    ];
  }

  static List<ChatMessage> messagesFor(String threadId) {
    final now = DateTime.now();
    return switch (threadId) {
      'th-driver' => [
        ChatMessage(
          id: 'm1',
          threadId: threadId,
          sender: ChatSender.them,
          text: 'Habari — nimefika pickup point.',
          at: now.subtract(const Duration(minutes: 8)),
        ),
        ChatMessage(
          id: 'm2',
          threadId: threadId,
          sender: ChatSender.me,
          text: 'Okay, ninatoka sasa.',
          at: now.subtract(const Duration(minutes: 6)),
        ),
        ChatMessage(
          id: 'm3',
          threadId: threadId,
          sender: ChatSender.them,
          text: 'Niko karibu — dakika 3',
          at: now.subtract(const Duration(minutes: 3)),
        ),
      ],
      'th-support' => [
        ChatMessage(
          id: 's1',
          threadId: threadId,
          sender: ChatSender.them,
          text: 'Karibu! How can we help with your TAIFA account?',
          at: now.subtract(const Duration(hours: 2)),
        ),
      ],
      'th-family' => [
        ChatMessage(
          id: 'f1',
          threadId: threadId,
          sender: ChatSender.them,
          text: 'Asante for the school fees 💚',
          at: now.subtract(const Duration(hours: 5)),
        ),
        ChatMessage(
          id: 'f2',
          threadId: threadId,
          sender: ChatSender.me,
          text: 'Karibu — paid via TAIFA Education.',
          at: now.subtract(const Duration(hours: 4, minutes: 50)),
        ),
      ],
      _ => const <ChatMessage>[],
    };
  }
}

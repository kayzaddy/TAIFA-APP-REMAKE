class ChatThread {
  const ChatThread({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.unread,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String subtitle;
  final int unread;
  final DateTime updatedAt;
}

enum ChatSender { me, them }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.threadId,
    required this.sender,
    required this.text,
    required this.at,
  });

  final String id;
  final String threadId;
  final ChatSender sender;
  final String text;
  final DateTime at;
}

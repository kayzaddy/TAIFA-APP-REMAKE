import '../../features/chat/domain/chat_models.dart';

/// Maps `/api/v1/commerce/chat-*` JSON ↔ domain chat models.
class ChatDto {
  const ChatDto._();

  static ChatThread threadToDomain(Map<String, dynamic> json) {
    return ChatThread(
      id: json['id'].toString(),
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      unread: (json['unread'] as num?)?.toInt() ?? 0,
      updatedAt:
          DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  static Map<String, dynamic> threadCreateBody(ChatThread thread) => {
    'title': thread.title,
    'subtitle': thread.subtitle,
    'unread': thread.unread,
  };

  static ChatMessage messageToDomain(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'].toString(),
      threadId: json['thread'].toString(),
      sender: (json['sender'] as String?) == 'them'
          ? ChatSender.them
          : ChatSender.me,
      text: json['text'] as String? ?? '',
      at:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  static Map<String, dynamic> messageCreateBody(ChatMessage msg) => {
    'sender': msg.sender == ChatSender.them ? 'them' : 'me',
    'text': msg.text,
  };
}

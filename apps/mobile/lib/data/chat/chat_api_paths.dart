/// Path fragments for `/api/v1/commerce/chat-threads*` (relative to API base).
abstract final class ChatApiPaths {
  static const chatThreads = 'commerce/chat-threads';

  static String chatThread(String id) => 'commerce/chat-threads/$id';

  static String chatMessages(String threadId) =>
      'commerce/chat-threads/$threadId/messages';
}

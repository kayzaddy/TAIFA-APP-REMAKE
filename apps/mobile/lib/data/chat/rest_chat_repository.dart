import '../../features/chat/application/chat_repository.dart';
import '../../features/chat/data/chat_seed.dart';
import '../../features/chat/domain/chat_models.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import 'chat_api_paths.dart';
import 'chat_dto.dart';

/// Live [ChatRepository]: hydrates demo inbox once, then persists sends.
class RestChatRepository implements ChatRepository {
  RestChatRepository(this._client);

  final TaifaApiClient _client;
  bool _seeded = false;

  @override
  Future<List<ChatThread>> threads() async {
    try {
      var list = await _fetchThreads();
      if (list.isEmpty && !_seeded) {
        await _hydrateSeed();
        _seeded = true;
        list = await _fetchThreads();
      }
      return list;
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<List<ChatMessage>> messages(String threadId) async {
    try {
      final list = await _client.getJsonList(
        ChatApiPaths.chatMessages(threadId),
      );
      return list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .map(ChatDto.messageToDomain)
          .toList();
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<ChatMessage> send(String threadId, String text) async {
    try {
      final json = await _client.postJson(
        ChatApiPaths.chatMessages(threadId),
        body: {'sender': 'me', 'text': text},
      );
      return ChatDto.messageToDomain(json);
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  Future<List<ChatThread>> _fetchThreads() async {
    final list = await _client.getJsonList(ChatApiPaths.chatThreads);
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .map(ChatDto.threadToDomain)
        .toList();
  }

  Future<void> _hydrateSeed() async {
    for (final thread in ChatSeed.threads()) {
      final created = await _client.postJson(
        ChatApiPaths.chatThreads,
        body: ChatDto.threadCreateBody(thread),
      );
      final id = created['id'].toString();
      for (final msg in ChatSeed.messagesFor(thread.id)) {
        await _client.postJson(
          ChatApiPaths.chatMessages(id),
          body: ChatDto.messageCreateBody(msg),
        );
      }
    }
  }

  String _message(ApiException e) => switch (e) {
    NetworkException() => e.message,
    ApiStatusException(:final message) => message,
    ApiDecodeException() => e.message,
  };
}

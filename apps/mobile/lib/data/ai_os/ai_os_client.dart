import '../api/api_client.dart';

/// Client for `/api/v1/ai-os/*`.
class AiOsClient {
  AiOsClient(this._client);

  final TaifaApiClient _client;

  Future<Map<String, dynamic>> commandCenter() {
    return _client.getJson('ai-os/command-center');
  }

  Future<List<Map<String, dynamic>>> agents() async {
    final json = await _client.getJson('ai-os/agents');
    final agents = json['agents'];
    if (agents is! List) return const [];
    return agents
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<Map<String, dynamic>> runAgent({
    required String agentCode,
    required String message,
    String? capabilityCode,
  }) {
    return _client.postJson(
      'ai-os/agents/$agentCode/run',
      body: {
        'message': message,
        'capability_code': ?capabilityCode,
      },
    );
  }

  Future<Map<String, dynamic>> infer({
    required String capability,
    Map<String, dynamic> payload = const {},
    String domainCode = '',
  }) {
    return _client.postJson(
      'ai-os/infer/$capability',
      body: {'payload': payload, 'domain_code': domainCode},
    );
  }

  Future<Map<String, dynamic>> knowledgeSearch(String query, {String domain = ''}) {
    return _client.postJson(
      'ai-os/knowledge/search',
      body: {'query': query, 'domain_code': domain},
    );
  }
}

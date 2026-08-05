import '../api/api_client.dart';

/// Client for `/api/v1/ecosystem/*` — Super App modules and open platform.
class EcosystemClient {
  EcosystemClient(this._client);

  final TaifaApiClient _client;

  Future<Map<String, dynamic>> blueprint() {
    return _client.getJson('ecosystem/blueprint');
  }

  Future<List<Map<String, dynamic>>> myModules() async {
    final json = await _client.getJson('ecosystem/modules');
    final modules = json['modules'];
    if (modules is! List) return const [];
    return modules
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<Map<String, dynamic>> setModuleEnabled({
    required String moduleCode,
    required bool enabled,
  }) {
    return _client.postJson(
      'ecosystem/modules/$moduleCode/enable',
      body: {'enabled': enabled},
    );
  }

  Future<List<Map<String, dynamic>>> farms() async {
    final json = await _client.getJson('ecosystem/agriculture/farms');
    final farms = json['farms'];
    if (farms is! List) return const [];
    return farms
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<List<Map<String, dynamic>>> listings({String region = ''}) async {
    final path = region.isEmpty
        ? 'ecosystem/agriculture/listings'
        : 'ecosystem/agriculture/listings?region=${Uri.encodeQueryComponent(region)}';
    final json = await _client.getJson(path);
    final rows = json['listings'];
    if (rows is! List) return const [];
    return rows
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<Map<String, dynamic>> invokeAi({
    required String capability,
    Map<String, dynamic> payload = const {},
    String domainCode = '',
  }) {
    return _client.postJson(
      'ecosystem/ai/$capability/invoke',
      body: {'payload': payload, 'domain_code': domainCode},
    );
  }
}

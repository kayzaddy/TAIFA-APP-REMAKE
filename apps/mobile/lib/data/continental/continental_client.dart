import '../api/api_client.dart';

class ContinentalClient {
  ContinentalClient(this._client);

  final TaifaApiClient _client;

  Future<Map<String, dynamic>> blueprint() {
    return _client.getJson('continental/blueprint');
  }

  Future<Map<String, dynamic>> opsCenter() {
    return _client.getJson('continental/ops-center');
  }

  Future<List<Map<String, dynamic>>> countries() async {
    final json = await _client.getJson('continental/countries');
    final rows = json['countries'];
    if (rows is! List) return const [];
    return rows
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<Map<String, dynamic>> country(String code) {
    return _client.getJson('continental/countries/$code');
  }

  Future<Map<String, dynamic>> fxQuote({
    required String base,
    required String quote,
    int amountMinor = 0,
  }) {
    final q = 'base=$base&quote=$quote'
        '${amountMinor > 0 ? '&amount_minor=$amountMinor' : ''}';
    return _client.getJson('continental/fx/quote?$q');
  }
}

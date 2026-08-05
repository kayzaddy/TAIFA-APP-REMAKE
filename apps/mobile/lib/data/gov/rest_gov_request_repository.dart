import '../../features/gov/application/gov_repository.dart';
import '../../features/gov/domain/gov_models.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import 'gov_api_paths.dart';
import 'gov_request_dto.dart';

/// Live [GovRequestRepository]: persists Huduma requests on `/commerce/gov-requests`.
/// Service catalog stays client-side; the API stores durable request summaries.
class RestGovRequestRepository implements GovRequestRepository {
  RestGovRequestRepository(this._client);

  final TaifaApiClient _client;
  final Map<String, GovService> _services = {};
  int _refSeq = 0;

  @override
  Future<GovRequest> submit(GovRequest draft) async {
    try {
      _refSeq++;
      final reference = draft.reference ?? 'GVR-${200000 + _refSeq * 17}';
      final json = await _client.postJson(
        GovApiPaths.govRequests,
        body: GovRequestDto.createBody(draft, reference: reference),
      );
      final req = GovRequestDto.toDomain(
        json,
        service: draft.service,
      ).copyWith(status: GovRequestStatus.inReview, reference: reference);
      _services[req.id] = draft.service;
      if ((json['reference'] as String?)?.trim().isEmpty ?? true) {
        return _patch(req);
      }
      return req;
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<GovRequest> pay(String id) async {
    try {
      final json = await _client.postJson(
        GovApiPaths.govRequestPay(id),
        body: const {},
        idempotencyKey: 'gov-pay-$id',
      );
      return GovRequestDto.toDomain(json, service: _services[id]);
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<List<GovRequest>> history() async {
    try {
      final list = await _client.getJsonList(GovApiPaths.govRequests);
      return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).map(
        (json) {
          final id = json['id'].toString();
          return GovRequestDto.toDomain(json, service: _services[id]);
        },
      ).toList();
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  Future<GovRequest> _patch(GovRequest request) async {
    try {
      final json = await _client.patchJson(
        GovApiPaths.govRequest(request.id),
        body: GovRequestDto.patchBody(request),
      );
      _services[request.id] = request.service;
      return GovRequestDto.toDomain(json, service: request.service);
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  String _message(ApiException e) => switch (e) {
    NetworkException() => e.message,
    ApiStatusException(:final message) => message,
    ApiDecodeException() => e.message,
  };
}

import '../../features/tourism/application/tourism_assist_repository.dart';
import '../../features/tourism/domain/tourism_assist_models.dart';
import '../../features/tourism/domain/tourism_connectivity_models.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import 'tourism_assist_api_paths.dart';

class RestTourismAssistRepository implements TourismAssistRepository {
  RestTourismAssistRepository(this._client);

  final TaifaApiClient _client;

  @override
  Future<List<TourismNearbyPlace>> nearby({
    double? latitude,
    double? longitude,
  }) async {
    try {
      final path = TourismAssistApiPaths.nearby;
      final uri = StringBuffer(path);
      if (latitude != null || longitude != null) {
        uri.write('?');
        if (latitude != null) uri.write('lat=$latitude');
        if (longitude != null) {
          if (latitude != null) uri.write('&');
          uri.write('lng=$longitude');
        }
      }
      final json = await _client.getJson(uri.toString());
      final rows = json['places'] as List? ?? const [];
      return rows
          .whereType<Map>()
          .map((e) => TourismNearbyPlace.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<TourismAssistanceCase> sendSos({
    String? tripId,
    double? latitude,
    double? longitude,
    String notes = '',
  }) async {
    try {
      final body = {
        'notes': notes,
        if (tripId != null) 'trip_id': tripId,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };
      final json = await _client.postJson(TourismAssistApiPaths.sos, body: body);
      return TourismAssistanceCase.fromJson(json);
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<TourismEsimActivation> esimQr(String orderId) async {
    try {
      final json = await _client.getJson(TourismAssistApiPaths.esimQr(orderId));
      return TourismEsimActivation.fromJson(json);
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

import 'dart:convert';

import '../../features/mobility_transit/application/transit_repository.dart';
import '../../features/mobility_transit/domain/transit_models.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import 'transit_api_paths.dart';

class RestTransitRepository implements TransitRepository {
  RestTransitRepository(this._client);

  final TaifaApiClient _client;

  @override
  Future<TransitHome> loadHome({
    double? lat,
    double? lng,
    String region = 'Dar es Salaam',
    String mode = '',
  }) async {
    try {
      final params = <String>[];
      if (lat != null) params.add('lat=$lat');
      if (lng != null) params.add('lng=$lng');
      if (region.isNotEmpty) {
        params.add('region=${Uri.encodeQueryComponent(region)}');
      }
      if (mode.isNotEmpty) {
        params.add('mode=${Uri.encodeQueryComponent(mode)}');
      }
      final suffix = params.isEmpty ? '' : '?${params.join('&')}';
      final json = await _client.getJson('${TransitApiPaths.home}$suffix');
      return TransitHome.fromJson(json);
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<List<TransitMode>> loadModes({String region = 'Dar es Salaam'}) async {
    try {
      final json = await _client.getJson(
        '${TransitApiPaths.modes}?region=${Uri.encodeQueryComponent(region)}',
      );
      final modes = json['modes'] as List? ?? const [];
      return modes
          .whereType<Map>()
          .map((e) => TransitMode.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<List<TransitRoute>> listRoutes({
    String region = '',
    String mode = '',
  }) async {
    try {
      final params = <String>[];
      if (region.isNotEmpty) {
        params.add('region=${Uri.encodeQueryComponent(region)}');
      }
      if (mode.isNotEmpty) params.add('mode=${Uri.encodeQueryComponent(mode)}');
      final suffix = params.isEmpty ? '' : '?${params.join('&')}';
      final json = await _client.getJson('${TransitApiPaths.routes}$suffix');
      final routes = json['routes'] as List? ?? const [];
      return routes
          .whereType<Map>()
          .map((e) => TransitRoute.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<TransitRoute> getRoute(String id) async {
    try {
      final json = await _client.getJson(TransitApiPaths.route(id));
      return TransitRoute.fromJson(json);
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<List<TransitRoute>> search(String query, {String region = ''}) async {
    try {
      final params = <String>[
        'q=${Uri.encodeQueryComponent(query)}',
      ];
      if (region.isNotEmpty) {
        params.add('region=${Uri.encodeQueryComponent(region)}');
      }
      final json = await _client.getJson(
        '${TransitApiPaths.search}?${params.join('&')}',
      );
      final routes = json['routes'] as List? ?? const [];
      return routes
          .whereType<Map>()
          .map((e) => TransitRoute.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<TransitTicket> purchaseTicket({
    required String routeId,
    required String productCode,
    String originStop = '',
    String destinationStop = '',
    required String idempotencyKey,
  }) async {
    try {
      final json = await _client.postJson(
        TransitApiPaths.ticketsPurchase,
        body: {
          'route_id': routeId,
          'product_code': productCode,
          if (originStop.isNotEmpty) 'origin_stop': originStop,
          if (destinationStop.isNotEmpty) 'destination_stop': destinationStop,
        },
        idempotencyKey: idempotencyKey,
      );
      return TransitTicket.fromJson(json);
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<List<TransitTicket>> myTickets() async {
    try {
      final json = await _client.getJson(TransitApiPaths.ticketsMine);
      final tickets = json['tickets'] as List? ?? const [];
      return tickets
          .whereType<Map>()
          .map((e) => TransitTicket.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<List<TransitProduct>> listProducts({String mode = ''}) async {
    try {
      final suffix = mode.isEmpty ? '' : '?mode=${Uri.encodeQueryComponent(mode)}';
      final json = await _client.getJson('${TransitApiPaths.products}$suffix');
      final products = json['products'] as List? ?? const [];
      return products
          .whereType<Map>()
          .map((e) => TransitProduct.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<TransitStationDetail> getStation(String stopCode) async {
    try {
      final json = await _client.getJson(TransitApiPaths.station(stopCode));
      return TransitStationDetail.fromJson(json);
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<List<TransitPlanOption>> planJourney({
    required String originStop,
    required String destinationStop,
    String region = '',
  }) async {
    try {
      final params = [
        'origin_stop=${Uri.encodeQueryComponent(originStop)}',
        'destination_stop=${Uri.encodeQueryComponent(destinationStop)}',
      ];
      if (region.isNotEmpty) {
        params.add('region=${Uri.encodeQueryComponent(region)}');
      }
      final json = await _client.getJson('${TransitApiPaths.plan}?${params.join('&')}');
      final plans = json['plans'] as List? ?? const [];
      return plans
          .whereType<Map>()
          .map((e) => TransitPlanOption.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<List<TransitScheduledRun>> driverRuns() async {
    try {
      final json = await _client.getJson(TransitApiPaths.driverRuns);
      final runs = json['runs'] as List? ?? const [];
      return runs
          .whereType<Map>()
          .map((e) => TransitScheduledRun.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<TransitScheduledRun> advanceDriverRun(String runId, String status) async {
    try {
      final json = await _client.patchJson(
        TransitApiPaths.driverRun(runId),
        body: {'status': status},
      );
      return TransitScheduledRun.fromJson(json);
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<TransitLiveMap> loadLiveMap({
    String region = 'Dar es Salaam',
    String routeId = '',
  }) async {
    try {
      final params = <String>[];
      if (region.isNotEmpty) {
        params.add('region=${Uri.encodeQueryComponent(region)}');
      }
      if (routeId.isNotEmpty) params.add('route_id=$routeId');
      final suffix = params.isEmpty ? '' : '?${params.join('&')}';
      final json = await _client.getJson('${TransitApiPaths.liveMap}$suffix');
      return TransitLiveMap.fromJson(json);
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<TransitMapVehicle> pingAvl({
    required String vehicleLabel,
    required String routeId,
    required double latitude,
    required double longitude,
    int speedKmh = 0,
    String nextStopCode = '',
    int etaNextStopSeconds = 0,
  }) async {
    try {
      final json = await _client.postJson(
        TransitApiPaths.avlPing,
        body: {
          'vehicle_label': vehicleLabel,
          'route_id': routeId,
          'latitude': latitude,
          'longitude': longitude,
          'speed_kmh': speedKmh,
          if (nextStopCode.isNotEmpty) 'next_stop_code': nextStopCode,
          if (etaNextStopSeconds > 0) 'eta_next_stop_seconds': etaNextStopSeconds,
        },
      );
      return TransitMapVehicle.fromJson(json);
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<TransitProfileBundle> loadProfile() async {
    try {
      final json = await _client.getJson(TransitApiPaths.profile);
      return TransitProfileBundle.fromJson(json);
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<TransitProfileBundle> updateProfile({
    String? homeStop,
    String? workStop,
    String? preferredLanguage,
    Map<String, dynamic>? accessibility,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (homeStop != null) body['home_stop'] = homeStop;
      if (workStop != null) body['work_stop'] = workStop;
      if (preferredLanguage != null) body['preferred_language'] = preferredLanguage;
      if (accessibility != null) body['accessibility'] = accessibility;
      final json = await _client.patchJson(TransitApiPaths.profile, body: body);
      return TransitProfileBundle.fromJson(json);
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<List<TransitFavorite>> listFavorites() async {
    try {
      final json = await _client.getJson(TransitApiPaths.favorites);
      final favorites = json['favorites'] as List? ?? const [];
      return favorites
          .whereType<Map>()
          .map((e) => TransitFavorite.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<TransitFavorite> addFavorite({
    required String subjectType,
    required String subjectCode,
    String label = '',
  }) async {
    try {
      final json = await _client.postJson(
        TransitApiPaths.favorites,
        body: {
          'subject_type': subjectType,
          'subject_code': subjectCode,
          if (label.isNotEmpty) 'label': label,
        },
      );
      return TransitFavorite.fromJson(json);
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<void> removeFavorite(String favoriteId) async {
    try {
      await _client.deleteJson(TransitApiPaths.favorite(favoriteId));
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<List<TransitNotification>> listNotifications() async {
    try {
      final json = await _client.getJson(TransitApiPaths.notifications);
      final rows = json['notifications'] as List? ?? const [];
      return rows
          .whereType<Map>()
          .map((e) => TransitNotification.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<int> markNotificationsRead({List<String>? ids}) async {
    try {
      final json = await _client.postJson(
        TransitApiPaths.notifications,
        body: ids == null || ids.isEmpty ? {} : {'ids': ids},
      );
      return (json['marked_read'] as num?)?.toInt() ?? 0;
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<TransitFeedback> submitFeedback({
    required int rating,
    String comment = '',
    List<String> tags = const [],
    String? routeId,
    String? ticketId,
  }) async {
    try {
      final json = await _client.postJson(
        TransitApiPaths.feedback,
        body: {
          'rating': rating,
          if (comment.isNotEmpty) 'comment': comment,
          if (tags.isNotEmpty) 'tags': tags,
          'route_id': ?routeId,
          'ticket_id': ?ticketId,
        },
      );
      return TransitFeedback(
        id: '${json['id'] ?? ''}',
        rating: (json['rating'] as num?)?.toInt() ?? rating,
        comment: comment,
        sentiment: '${json['sentiment'] ?? ''}',
        tags: tags,
        routeCode: '',
        createdAt: DateTime.now().toUtc().toIso8601String(),
      );
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<TransitSosResult> reportSos({
    double? latitude,
    double? longitude,
    String stopCode = '',
    String? routeId,
    String vehicleLabel = '',
    String notes = '',
  }) async {
    try {
      final json = await _client.postJson(
        TransitApiPaths.safetySos,
        body: {
          'latitude': ?latitude,
          'longitude': ?longitude,
          if (stopCode.isNotEmpty) 'stop_code': stopCode,
          'route_id': ?routeId,
          if (vehicleLabel.isNotEmpty) 'vehicle_label': vehicleLabel,
          if (notes.isNotEmpty) 'notes': notes,
        },
      );
      return TransitSosResult.fromJson(json);
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<TransitAnalytics> loadAnalytics({
    String region = 'Dar es Salaam',
    int days = 7,
  }) async {
    try {
      final json = await _client.getJson(
        '${TransitApiPaths.analytics}?region=${Uri.encodeQueryComponent(region)}&days=$days',
      );
      return TransitAnalytics.fromJson(json);
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<TransitRoute> adminUpdateRoute(String routeId, Map<String, dynamic> body) async {
    try {
      final json = await _client.patchJson(TransitApiPaths.adminRoute(routeId), body: body);
      return TransitRoute.fromJson(json);
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<TransitProduct> adminUpdateProduct(String productId, Map<String, dynamic> body) async {
    try {
      final json = await _client.patchJson(TransitApiPaths.adminProduct(productId), body: body);
      return TransitProduct.fromJson(json);
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<TransitProduct> adminCreateProduct(Map<String, dynamic> body) async {
    try {
      final json = await _client.postJson(TransitApiPaths.adminProducts, body: body);
      return TransitProduct.fromJson(json);
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<TransitAssistantReply> askAssistant({
    required String query,
    String locale = '',
    String region = 'Dar es Salaam',
  }) async {
    try {
      final json = await _client.postJson(
        TransitApiPaths.assistant,
        body: {
          'query': query,
          if (locale.isNotEmpty) 'locale': locale,
          'region': region,
        },
      );
      return TransitAssistantReply.fromJson(json);
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<TransitFamilyBundle> loadFamilyBundle() async {
    try {
      final json = await _client.getJson(TransitApiPaths.family);
      return TransitFamilyBundle.fromJson(json);
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<List<TransitFamilyMember>> listFamilyMembers() async {
    try {
      final json = await _client.getJson(TransitApiPaths.familyMembers);
      final members = json['members'] as List? ?? const [];
      return members
          .whereType<Map>()
          .map((e) => TransitFamilyMember.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<TransitFamilyMember> addFamilyMember({
    required String memberOwner,
    required String displayName,
    String relationship = 'child',
    int monthlyLimitMinor = 0,
  }) async {
    try {
      final json = await _client.postJson(
        TransitApiPaths.familyMembers,
        body: {
          'member_owner': memberOwner,
          'display_name': displayName,
          'relationship': relationship,
          'monthly_limit_minor': monthlyLimitMinor,
        },
      );
      return TransitFamilyMember.fromJson(json);
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<void> removeFamilyMember(String memberId) async {
    try {
      await _client.deleteJson(TransitApiPaths.familyMember(memberId));
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<TransitTicket> purchaseTicketForMember({
    required String routeId,
    required String productCode,
    required String beneficiaryOwner,
    required String idempotencyKey,
    String originStop = '',
    String destinationStop = '',
  }) async {
    try {
      final json = await _client.postJson(
        TransitApiPaths.ticketsPurchase,
        body: {
          'route_id': routeId,
          'product_code': productCode,
          'beneficiary_owner': beneficiaryOwner,
          if (originStop.isNotEmpty) 'origin_stop': originStop,
          if (destinationStop.isNotEmpty) 'destination_stop': destinationStop,
        },
        idempotencyKey: idempotencyKey,
      );
      return TransitTicket.fromJson(json);
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<TransitLostFoundBundle> loadLostFoundBundle({
    String kind = '',
    String stopCode = '',
  }) async {
    try {
      final params = <String>[];
      if (kind.isNotEmpty) params.add('kind=${Uri.encodeQueryComponent(kind)}');
      if (stopCode.isNotEmpty) {
        params.add('stop_code=${Uri.encodeQueryComponent(stopCode)}');
      }
      final suffix = params.isEmpty ? '' : '?${params.join('&')}';
      final json = await _client.getJson('${TransitApiPaths.lostFound}$suffix');
      return TransitLostFoundBundle.fromJson(json);
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<TransitLostFoundItem> reportLostFound({
    required String kind,
    required String title,
    String description = '',
    String category = 'other',
    String stopCode = '',
    String? routeId,
    String contactHint = '',
    String photoUrl = '',
  }) async {
    try {
      final json = await _client.postJson(
        TransitApiPaths.lostFound,
        body: {
          'kind': kind,
          'title': title,
          if (description.isNotEmpty) 'description': description,
          'category': category,
          if (stopCode.isNotEmpty) 'stop_code': stopCode,
          'route_id': ?routeId,
          if (contactHint.isNotEmpty) 'contact_hint': contactHint,
          if (photoUrl.isNotEmpty) 'photo_url': photoUrl,
        },
      );
      return TransitLostFoundItem.fromJson(json);
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<TransitLostFoundItem> claimLostFound({
    required String itemId,
    String message = '',
  }) async {
    try {
      final json = await _client.postJson(
        TransitApiPaths.lostFoundClaim(itemId),
        body: {if (message.isNotEmpty) 'message': message},
      );
      return TransitLostFoundItem.fromJson(json);
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<TransitLostFoundItem> resolveLostFound({
    required String itemId,
    String status = 'closed',
  }) async {
    try {
      final json = await _client.postJson(
        TransitApiPaths.lostFoundResolve(itemId),
        body: {'status': status},
      );
      return TransitLostFoundItem.fromJson(json);
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<String> uploadLostFoundPhoto({
    required List<int> bytes,
    String contentType = 'image/jpeg',
  }) async {
    try {
      final json = await _client.postJson(
        TransitApiPaths.lostFoundPhoto,
        body: {
          'content_base64': base64Encode(bytes),
          'content_type': contentType,
        },
      );
      return '${json['photo_url'] ?? ''}';
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<List<TransitLostFoundItem>> loadAdminLostFound({String status = ''}) async {
    try {
      final suffix = status.isEmpty ? '' : '?status=${Uri.encodeQueryComponent(status)}';
      final json = await _client.getJson('${TransitApiPaths.adminLostFound}$suffix');
      final items = json['items'] as List? ?? const [];
      return items
          .whereType<Map>()
          .map((e) => TransitLostFoundItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<TransitLostFoundItem> opsResolveLostFound({
    required String itemId,
    String status = 'closed',
  }) async {
    try {
      final json = await _client.postJson(
        TransitApiPaths.adminLostFoundResolve(itemId),
        body: {'status': status},
      );
      return TransitLostFoundItem.fromJson(json);
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  String _message(ApiException e) => switch (e) {
        ApiStatusException(:final message) => message,
        _ => e.message,
      };
}

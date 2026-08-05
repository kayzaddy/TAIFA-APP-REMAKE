import '../../wallet/domain/currency.dart';
import '../../wallet/domain/money.dart';

class TransitStation {
  const TransitStation({
    required this.stopCode,
    required this.name,
    required this.region,
    required this.latitude,
    required this.longitude,
    this.distanceMeters = 0,
    this.imageUrl = '',
    this.facilities = const [],
    this.platform = '',
  });

  final String stopCode;
  final String name;
  final String region;
  final double latitude;
  final double longitude;
  final int distanceMeters;
  final String imageUrl;
  final List<String> facilities;
  final String platform;

  factory TransitStation.fromJson(Map<String, dynamic> json) => TransitStation(
        stopCode: '${json['stop_code'] ?? ''}',
        name: '${json['name'] ?? ''}',
        region: '${json['region'] ?? ''}',
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
        distanceMeters: (json['distance_meters'] as num?)?.toInt() ?? 0,
        imageUrl: '${json['image_url'] ?? ''}',
        facilities: (json['facilities'] as List?)?.map((e) => '$e').toList() ?? const [],
        platform: '${json['platform'] ?? ''}',
      );
}

class TransitRoute {
  const TransitRoute({
    required this.id,
    required this.code,
    required this.name,
    required this.region,
    required this.stops,
    required this.metadata,
    this.fareMinor = 0,
    this.currency = 'TZS',
    this.departures = const [],
  });

  final String id;
  final String code;
  final String name;
  final String region;
  final List<Map<String, dynamic>> stops;
  final Map<String, dynamic> metadata;
  final int fareMinor;
  final String currency;
  final List<Map<String, dynamic>> departures;

  String get brand => '${metadata['brand'] ?? metadata['operator'] ?? 'Transit'}';
  String get mode => '${metadata['mode'] ?? 'bus'}';
  Money get fare => Money(fareMinor, Currency.fromCode(currency));

  factory TransitRoute.fromJson(Map<String, dynamic> json) => TransitRoute(
        id: '${json['id'] ?? ''}',
        code: '${json['code'] ?? ''}',
        name: '${json['name'] ?? ''}',
        region: '${json['region'] ?? ''}',
        stops: (json['stops'] as List?)
                ?.whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList() ??
            const [],
        metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
        fareMinor: (json['fare_minor'] as num?)?.toInt() ?? 0,
        currency: '${json['currency'] ?? 'TZS'}',
        departures: (json['departures'] as List?)
                ?.whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList() ??
            const [],
      );
}

class TransitAlert {
  const TransitAlert({
    required this.id,
    required this.title,
    required this.body,
    required this.severity,
  });

  final String id;
  final String title;
  final String body;
  final String severity;

  factory TransitAlert.fromJson(Map<String, dynamic> json) => TransitAlert(
        id: '${json['id'] ?? ''}',
        title: '${json['title'] ?? ''}',
        body: '${json['body'] ?? ''}',
        severity: '${json['severity'] ?? 'info'}',
      );
}

class TransitTicket {
  const TransitTicket({
    required this.id,
    required this.mediaCode,
    required this.status,
    required this.fareMinor,
    required this.currency,
    required this.validFrom,
    required this.validTo,
    required this.qr,
    this.routeName = '',
    this.routeCode = '',
    this.originStop = '',
    this.destinationStop = '',
    this.productCode = '',
    this.guardianOwner = '',
    this.beneficiaryDisplayName = '',
  });

  final String id;
  final String mediaCode;
  final String status;
  final int fareMinor;
  final String currency;
  final String validFrom;
  final String validTo;
  final Map<String, dynamic> qr;
  final String routeName;
  final String routeCode;
  final String originStop;
  final String destinationStop;
  final String productCode;
  final String guardianOwner;
  final String beneficiaryDisplayName;

  Money get fare => Money(fareMinor, Currency.fromCode(currency));

  factory TransitTicket.fromJson(Map<String, dynamic> json) {
    final route = json['route'] as Map?;
    return TransitTicket(
      id: '${json['id'] ?? ''}',
      mediaCode: '${json['media_code'] ?? ''}',
      status: '${json['status'] ?? ''}',
      fareMinor: (json['fare_minor'] as num?)?.toInt() ?? 0,
      currency: '${json['currency'] ?? 'TZS'}',
      validFrom: '${json['valid_from'] ?? ''}',
      validTo: '${json['valid_to'] ?? ''}',
      qr: Map<String, dynamic>.from(json['qr'] as Map? ?? {}),
      routeName: '${route?['name'] ?? ''}',
      routeCode: '${route?['code'] ?? ''}',
      originStop: '${json['origin_stop'] ?? ''}',
      destinationStop: '${json['destination_stop'] ?? ''}',
      productCode: '${json['product_code'] ?? ''}',
      guardianOwner: '${json['guardian_owner'] ?? ''}',
      beneficiaryDisplayName: '${json['beneficiary_display_name'] ?? ''}',
    );
  }
}

class TransitHome {
  const TransitHome({
    required this.nearbyStations,
    required this.featuredRoutes,
    required this.alerts,
    required this.recentTickets,
    required this.products,
    required this.region,
    this.mode = '',
    this.unreadNotifications = 0,
  });

  final List<TransitStation> nearbyStations;
  final List<TransitRoute> featuredRoutes;
  final List<TransitAlert> alerts;
  final List<TransitTicket> recentTickets;
  final List<TransitProduct> products;
  final String region;
  final String mode;
  final int unreadNotifications;

  factory TransitHome.fromJson(Map<String, dynamic> json) => TransitHome(
        nearbyStations: (json['nearby_stations'] as List?)
                ?.whereType<Map>()
                .map((e) => TransitStation.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            const [],
        featuredRoutes: (json['featured_routes'] as List?)
                ?.whereType<Map>()
                .map((e) => TransitRoute.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            const [],
        alerts: (json['alerts'] as List?)
                ?.whereType<Map>()
                .map((e) => TransitAlert.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            const [],
        recentTickets: (json['recent_tickets'] as List?)
                ?.whereType<Map>()
                .map((e) => TransitTicket.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            const [],
        products: (json['products'] as List?)
                ?.whereType<Map>()
                .map((e) => TransitProduct.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            const [],
        region: '${json['region'] ?? 'Dar es Salaam'}',
        mode: '${json['mode'] ?? ''}',
        unreadNotifications: (json['unread_notifications'] as num?)?.toInt() ?? 0,
      );
}

class TransitMode {
  const TransitMode({
    required this.id,
    required this.label,
    required this.operator,
    required this.color,
    required this.routeCount,
  });

  final String id;
  final String label;
  final String operator;
  final String color;
  final int routeCount;

  factory TransitMode.fromJson(Map<String, dynamic> json) => TransitMode(
        id: '${json['id'] ?? ''}',
        label: '${json['label'] ?? ''}',
        operator: '${json['operator'] ?? ''}',
        color: '${json['color'] ?? '#00A651'}',
        routeCount: (json['routes'] as num?)?.toInt() ?? 0,
      );
}

class TransitProduct {
  const TransitProduct({
    required this.code,
    required this.name,
    required this.description,
    required this.ticketType,
    required this.fareMinor,
    required this.currency,
    required this.validityHours,
    required this.maxValidations,
  });

  final String code;
  final String name;
  final String description;
  final String ticketType;
  final int fareMinor;
  final String currency;
  final int validityHours;
  final int maxValidations;

  Money get fare => Money(fareMinor, Currency.fromCode(currency));

  factory TransitProduct.fromJson(Map<String, dynamic> json) => TransitProduct(
        code: '${json['code'] ?? ''}',
        name: '${json['name'] ?? ''}',
        description: '${json['description'] ?? ''}',
        ticketType: '${json['ticket_type'] ?? 'single'}',
        fareMinor: (json['fare_minor'] as num?)?.toInt() ?? 0,
        currency: '${json['currency'] ?? 'TZS'}',
        validityHours: (json['validity_hours'] as num?)?.toInt() ?? 2,
        maxValidations: (json['max_validations'] as num?)?.toInt() ?? 1,
      );
}

class TransitStationDetail {
  const TransitStationDetail({
    required this.stopCode,
    required this.name,
    required this.region,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    required this.facilities,
    required this.accessibility,
    required this.platform,
    required this.upcoming,
  });

  final String stopCode;
  final String name;
  final String region;
  final double latitude;
  final double longitude;
  final String imageUrl;
  final List<String> facilities;
  final Map<String, dynamic> accessibility;
  final String platform;
  final List<Map<String, dynamic>> upcoming;

  factory TransitStationDetail.fromJson(Map<String, dynamic> json) =>
      TransitStationDetail(
        stopCode: '${json['stop_code'] ?? ''}',
        name: '${json['name'] ?? ''}',
        region: '${json['region'] ?? ''}',
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
        imageUrl: '${json['image_url'] ?? ''}',
        facilities: (json['facilities'] as List?)?.map((e) => '$e').toList() ?? const [],
        accessibility: Map<String, dynamic>.from(json['accessibility'] as Map? ?? {}),
        platform: '${json['platform'] ?? ''}',
        upcoming: (json['upcoming'] as List?)
                ?.whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList() ??
            const [],
      );
}

class TransitPlanOption {
  const TransitPlanOption({
    required this.kind,
    required this.routeId,
    required this.routeCode,
    required this.routeName,
    required this.mode,
    required this.brand,
    required this.originStop,
    required this.destinationStop,
    required this.fareMinor,
    required this.currency,
    required this.durationMinutes,
    this.transferStop = '',
    this.legs = const [],
  });

  final String kind;
  final String routeId;
  final String routeCode;
  final String routeName;
  final String mode;
  final String brand;
  final String originStop;
  final String destinationStop;
  final int fareMinor;
  final String currency;
  final int durationMinutes;
  final String transferStop;
  final List<Map<String, dynamic>> legs;

  bool get isTransfer => kind == 'transfer';

  Money get fare => Money(fareMinor, Currency.fromCode(currency));

  factory TransitPlanOption.fromJson(Map<String, dynamic> json) => TransitPlanOption(
        kind: '${json['kind'] ?? 'direct'}',
        routeId: '${json['route_id'] ?? ''}',
        routeCode: '${json['route_code'] ?? ''}',
        routeName: '${json['route_name'] ?? ''}',
        mode: '${json['mode'] ?? ''}',
        brand: '${json['brand'] ?? ''}',
        originStop: '${json['origin_stop'] ?? ''}',
        destinationStop: '${json['destination_stop'] ?? ''}',
        fareMinor: (json['fare_minor'] as num?)?.toInt() ?? 0,
        currency: '${json['currency'] ?? 'TZS'}',
        durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 0,
        transferStop: '${json['transfer_stop'] ?? ''}',
        legs: (json['legs'] as List?)
                ?.whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList() ??
            const [],
      );
}

class TransitScheduledRun {
  const TransitScheduledRun({
    required this.id,
    required this.routeId,
    required this.routeCode,
    required this.routeName,
    required this.vehicleLabel,
    required this.scheduledAt,
    required this.originStop,
    required this.destinationStop,
    required this.status,
    required this.brand,
  });

  final String id;
  final String routeId;
  final String routeCode;
  final String routeName;
  final String vehicleLabel;
  final String scheduledAt;
  final String originStop;
  final String destinationStop;
  final String status;
  final String brand;

  factory TransitScheduledRun.fromJson(Map<String, dynamic> json) => TransitScheduledRun(
        id: '${json['id'] ?? ''}',
        routeId: '${json['route_id'] ?? ''}',
        routeCode: '${json['route_code'] ?? ''}',
        routeName: '${json['route_name'] ?? ''}',
        vehicleLabel: '${json['vehicle_label'] ?? ''}',
        scheduledAt: '${json['scheduled_at'] ?? ''}',
        originStop: '${json['origin_stop'] ?? ''}',
        destinationStop: '${json['destination_stop'] ?? ''}',
        status: '${json['status'] ?? ''}',
        brand: '${json['brand'] ?? ''}',
      );
}

class TransitMapVehicle {
  const TransitMapVehicle({
    required this.id,
    required this.vehicleLabel,
    required this.routeCode,
    required this.routeName,
    required this.latitude,
    required this.longitude,
    required this.heading,
    required this.speedKmh,
    required this.progressE4,
    required this.nextStopCode,
    required this.etaNextStopSeconds,
    required this.status,
    required this.brand,
  });

  final String id;
  final String vehicleLabel;
  final String routeCode;
  final String routeName;
  final double latitude;
  final double longitude;
  final int heading;
  final int speedKmh;
  final int progressE4;
  final String nextStopCode;
  final int etaNextStopSeconds;
  final String status;
  final String brand;

  factory TransitMapVehicle.fromJson(Map<String, dynamic> json) => TransitMapVehicle(
        id: '${json['id'] ?? ''}',
        vehicleLabel: '${json['vehicle_label'] ?? ''}',
        routeCode: '${json['route_code'] ?? ''}',
        routeName: '${json['route_name'] ?? ''}',
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
        heading: (json['heading'] as num?)?.toInt() ?? 0,
        speedKmh: (json['speed_kmh'] as num?)?.toInt() ?? 0,
        progressE4: (json['progress_e4'] as num?)?.toInt() ?? 0,
        nextStopCode: '${json['next_stop_code'] ?? ''}',
        etaNextStopSeconds: (json['eta_next_stop_seconds'] as num?)?.toInt() ?? 0,
        status: '${json['status'] ?? ''}',
        brand: '${json['brand'] ?? ''}',
      );
}

class TransitMapStation {
  const TransitMapStation({
    required this.stopCode,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.platform,
  });

  final String stopCode;
  final String name;
  final double latitude;
  final double longitude;
  final String platform;

  factory TransitMapStation.fromJson(Map<String, dynamic> json) => TransitMapStation(
        stopCode: '${json['stop_code'] ?? ''}',
        name: '${json['name'] ?? ''}',
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
        platform: '${json['platform'] ?? ''}',
      );
}

class TransitMapRoute {
  const TransitMapRoute({
    required this.id,
    required this.code,
    required this.name,
    required this.polyline,
    required this.color,
  });

  final String id;
  final String code;
  final String name;
  final List<Map<String, dynamic>> polyline;
  final String color;

  factory TransitMapRoute.fromJson(Map<String, dynamic> json) {
    final metadata = json['metadata'] as Map? ?? {};
    return TransitMapRoute(
      id: '${json['id'] ?? ''}',
      code: '${json['code'] ?? ''}',
      name: '${json['name'] ?? ''}',
      polyline: (json['polyline'] as List?)
              ?.whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          const [],
      color: '${metadata['color'] ?? '#00A651'}',
    );
  }
}

class TransitLiveMap {
  const TransitLiveMap({
    required this.region,
    required this.routes,
    required this.stations,
    required this.vehicles,
  });

  final String region;
  final List<TransitMapRoute> routes;
  final List<TransitMapStation> stations;
  final List<TransitMapVehicle> vehicles;

  factory TransitLiveMap.fromJson(Map<String, dynamic> json) => TransitLiveMap(
        region: '${json['region'] ?? 'Dar es Salaam'}',
        routes: (json['routes'] as List?)
                ?.whereType<Map>()
                .map((e) => TransitMapRoute.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            const [],
        stations: (json['stations'] as List?)
                ?.whereType<Map>()
                .map((e) => TransitMapStation.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            const [],
        vehicles: (json['vehicles'] as List?)
                ?.whereType<Map>()
                .map((e) => TransitMapVehicle.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            const [],
      );
}

class TransitPassengerProfile {
  const TransitPassengerProfile({
    required this.homeStop,
    required this.workStop,
    required this.preferredLanguage,
    required this.accessibility,
  });

  final String homeStop;
  final String workStop;
  final String preferredLanguage;
  final Map<String, dynamic> accessibility;

  factory TransitPassengerProfile.fromJson(Map<String, dynamic> json) =>
      TransitPassengerProfile(
        homeStop: '${json['home_stop'] ?? ''}',
        workStop: '${json['work_stop'] ?? ''}',
        preferredLanguage: '${json['preferred_language'] ?? 'sw'}',
        accessibility: Map<String, dynamic>.from(json['accessibility'] as Map? ?? {}),
      );
}

class TransitTravelStats {
  const TransitTravelStats({
    required this.totalTickets,
    required this.activeTickets,
    required this.completedTrips,
    required this.favoriteCount,
  });

  final int totalTickets;
  final int activeTickets;
  final int completedTrips;
  final int favoriteCount;

  factory TransitTravelStats.fromJson(Map<String, dynamic> json) => TransitTravelStats(
        totalTickets: (json['total_tickets'] as num?)?.toInt() ?? 0,
        activeTickets: (json['active_tickets'] as num?)?.toInt() ?? 0,
        completedTrips: (json['completed_trips'] as num?)?.toInt() ?? 0,
        favoriteCount: (json['favorite_count'] as num?)?.toInt() ?? 0,
      );
}

class TransitFavorite {
  const TransitFavorite({
    required this.id,
    required this.subjectType,
    required this.subjectCode,
    required this.label,
  });

  final String id;
  final String subjectType;
  final String subjectCode;
  final String label;

  factory TransitFavorite.fromJson(Map<String, dynamic> json) => TransitFavorite(
        id: '${json['id'] ?? ''}',
        subjectType: '${json['subject_type'] ?? ''}',
        subjectCode: '${json['subject_code'] ?? ''}',
        label: '${json['label'] ?? ''}',
      );
}

class TransitProfileBundle {
  const TransitProfileBundle({
    required this.profile,
    required this.stats,
    required this.favorites,
  });

  final TransitPassengerProfile profile;
  final TransitTravelStats stats;
  final List<TransitFavorite> favorites;

  factory TransitProfileBundle.fromJson(Map<String, dynamic> json) =>
      TransitProfileBundle(
        profile: TransitPassengerProfile.fromJson(
          Map<String, dynamic>.from(json['profile'] as Map? ?? {}),
        ),
        stats: TransitTravelStats.fromJson(
          Map<String, dynamic>.from(json['stats'] as Map? ?? {}),
        ),
        favorites: (json['favorites'] as List?)
                ?.whereType<Map>()
                .map((e) => TransitFavorite.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            const [],
      );
}

class TransitNotification {
  const TransitNotification({
    required this.id,
    required this.eventType,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
    this.payload = const {},
  });

  final String id;
  final String eventType;
  final String title;
  final String body;
  final bool read;
  final String createdAt;
  final Map<String, dynamic> payload;

  factory TransitNotification.fromJson(Map<String, dynamic> json) =>
      TransitNotification(
        id: '${json['id'] ?? ''}',
        eventType: '${json['event_type'] ?? ''}',
        title: '${json['title'] ?? ''}',
        body: '${json['body'] ?? ''}',
        read: json['read'] == true,
        createdAt: '${json['created_at'] ?? ''}',
        payload: Map<String, dynamic>.from(json['payload'] as Map? ?? {}),
      );
}

class TransitFeedback {
  const TransitFeedback({
    required this.id,
    required this.rating,
    required this.comment,
    required this.sentiment,
    required this.tags,
    required this.routeCode,
    required this.createdAt,
  });

  final String id;
  final int rating;
  final String comment;
  final String sentiment;
  final List<String> tags;
  final String routeCode;
  final String createdAt;

  factory TransitFeedback.fromJson(Map<String, dynamic> json) => TransitFeedback(
        id: '${json['id'] ?? ''}',
        rating: (json['rating'] as num?)?.toInt() ?? 0,
        comment: '${json['comment'] ?? ''}',
        sentiment: '${json['sentiment'] ?? ''}',
        tags: (json['tags'] as List?)?.map((e) => '$e').toList() ?? const [],
        routeCode: '${json['route_code'] ?? ''}',
        createdAt: '${json['created_at'] ?? ''}',
      );
}

class TransitSosResult {
  const TransitSosResult({
    required this.incidentId,
    required this.status,
    required this.kind,
    required this.createdAt,
  });

  final String incidentId;
  final String status;
  final String kind;
  final String createdAt;

  factory TransitSosResult.fromJson(Map<String, dynamic> json) => TransitSosResult(
        incidentId: '${json['incident_id'] ?? ''}',
        status: '${json['status'] ?? ''}',
        kind: '${json['kind'] ?? ''}',
        createdAt: '${json['created_at'] ?? ''}',
      );
}

class TransitAnalytics {
  const TransitAnalytics({
    required this.region,
    required this.days,
    required this.daily,
    required this.byRoute,
    required this.ops,
  });

  final String region;
  final int days;
  final List<Map<String, dynamic>> daily;
  final List<Map<String, dynamic>> byRoute;
  final Map<String, dynamic> ops;

  factory TransitAnalytics.fromJson(Map<String, dynamic> json) => TransitAnalytics(
        region: '${json['region'] ?? ''}',
        days: (json['days'] as num?)?.toInt() ?? 7,
        daily: (json['daily'] as List?)
                ?.whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList() ??
            const [],
        byRoute: (json['by_route'] as List?)
                ?.whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList() ??
            const [],
        ops: Map<String, dynamic>.from(json['ops'] as Map? ?? {}),
      );
}

class TransitAssistantAction {
  const TransitAssistantAction({
    required this.action,
    required this.label,
    this.routeId = '',
    this.productCode = '',
    this.originStop = '',
    this.destinationStop = '',
    this.stopCode = '',
  });

  final String action;
  final String label;
  final String routeId;
  final String productCode;
  final String originStop;
  final String destinationStop;
  final String stopCode;

  factory TransitAssistantAction.fromJson(Map<String, dynamic> json) =>
      TransitAssistantAction(
        action: '${json['action'] ?? ''}',
        label: '${json['label'] ?? ''}',
        routeId: '${json['route_id'] ?? ''}',
        productCode: '${json['product_code'] ?? ''}',
        originStop: '${json['origin_stop'] ?? ''}',
        destinationStop: '${json['destination_stop'] ?? ''}',
        stopCode: '${json['stop_code'] ?? ''}',
      );
}

class TransitAssistantReply {
  const TransitAssistantReply({
    required this.query,
    required this.locale,
    required this.intent,
    required this.reply,
    required this.originStop,
    required this.destinationStop,
    required this.plans,
    required this.suggestedActions,
  });

  final String query;
  final String locale;
  final String intent;
  final String reply;
  final String originStop;
  final String destinationStop;
  final List<TransitPlanOption> plans;
  final List<TransitAssistantAction> suggestedActions;

  factory TransitAssistantReply.fromJson(Map<String, dynamic> json) =>
      TransitAssistantReply(
        query: '${json['query'] ?? ''}',
        locale: '${json['locale'] ?? 'en'}',
        intent: '${json['intent'] ?? 'general'}',
        reply: '${json['reply'] ?? ''}',
        originStop: '${json['origin_stop'] ?? ''}',
        destinationStop: '${json['destination_stop'] ?? ''}',
        plans: (json['plans'] as List?)
                ?.whereType<Map>()
                .map((e) => TransitPlanOption.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            const [],
        suggestedActions: (json['suggested_actions'] as List?)
                ?.whereType<Map>()
                .map((e) => TransitAssistantAction.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            const [],
      );
}

class TransitFamilyMember {
  const TransitFamilyMember({
    required this.id,
    required this.memberOwner,
    required this.displayName,
    required this.relationship,
    required this.status,
    required this.canPurchase,
    required this.monthlyLimitMinor,
    required this.spentThisMonthMinor,
    required this.activeTickets,
  });

  final String id;
  final String memberOwner;
  final String displayName;
  final String relationship;
  final String status;
  final bool canPurchase;
  final int monthlyLimitMinor;
  final int spentThisMonthMinor;
  final int activeTickets;

  Money get monthlyLimit => Money(monthlyLimitMinor, Currency.tzs);
  Money get spentThisMonth => Money(spentThisMonthMinor, Currency.tzs);

  bool get hasLimit => monthlyLimitMinor > 0;

  factory TransitFamilyMember.fromJson(Map<String, dynamic> json) => TransitFamilyMember(
        id: '${json['id'] ?? ''}',
        memberOwner: '${json['member_owner'] ?? ''}',
        displayName: '${json['display_name'] ?? ''}',
        relationship: '${json['relationship'] ?? 'child'}',
        status: '${json['status'] ?? 'active'}',
        canPurchase: json['can_purchase'] != false,
        monthlyLimitMinor: (json['monthly_limit_minor'] as num?)?.toInt() ?? 0,
        spentThisMonthMinor: (json['spent_this_month_minor'] as num?)?.toInt() ?? 0,
        activeTickets: (json['active_tickets'] as num?)?.toInt() ?? 0,
      );
}

class TransitFamilyBundle {
  const TransitFamilyBundle({
    required this.guardianOwner,
    required this.members,
    required this.tickets,
  });

  final String guardianOwner;
  final List<TransitFamilyMember> members;
  final List<TransitTicket> tickets;

  factory TransitFamilyBundle.fromJson(Map<String, dynamic> json) => TransitFamilyBundle(
        guardianOwner: '${json['guardian_owner'] ?? ''}',
        members: (json['members'] as List?)
                ?.whereType<Map>()
                .map((e) => TransitFamilyMember.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            const [],
        tickets: (json['tickets'] as List?)
                ?.whereType<Map>()
                .map((e) => TransitTicket.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            const [],
      );
}

class TransitLostFoundItem {
  const TransitLostFoundItem({
    required this.id,
    required this.reporterOwner,
    required this.kind,
    required this.category,
    required this.title,
    required this.description,
    required this.stopCode,
    required this.routeCode,
    required this.status,
    required this.contactHint,
    required this.claimantOwner,
    required this.claimMessage,
    required this.claimedAt,
    required this.resolvedAt,
    required this.createdAt,
    this.photoUrl = '',
  });

  final String id;
  final String reporterOwner;
  final String kind;
  final String category;
  final String title;
  final String description;
  final String stopCode;
  final String routeCode;
  final String status;
  final String contactHint;
  final String claimantOwner;
  final String claimMessage;
  final String claimedAt;
  final String resolvedAt;
  final String createdAt;
  final String photoUrl;

  bool get isOpen => status == 'open';
  bool get isFound => kind == 'found';
  bool get isLost => kind == 'lost';

  factory TransitLostFoundItem.fromJson(Map<String, dynamic> json) => TransitLostFoundItem(
        id: '${json['id'] ?? ''}',
        reporterOwner: '${json['reporter_owner'] ?? ''}',
        kind: '${json['kind'] ?? ''}',
        category: '${json['category'] ?? 'other'}',
        title: '${json['title'] ?? ''}',
        description: '${json['description'] ?? ''}',
        stopCode: '${json['stop_code'] ?? ''}',
        routeCode: '${json['route_code'] ?? ''}',
        status: '${json['status'] ?? 'open'}',
        contactHint: '${json['contact_hint'] ?? ''}',
        claimantOwner: '${json['claimant_owner'] ?? ''}',
        claimMessage: '${json['claim_message'] ?? ''}',
        claimedAt: '${json['claimed_at'] ?? ''}',
        resolvedAt: '${json['resolved_at'] ?? ''}',
        createdAt: '${json['created_at'] ?? ''}',
        photoUrl: '${json['photo_url'] ?? ''}',
      );
}

class TransitLostFoundBundle {
  const TransitLostFoundBundle({
    required this.openItems,
    required this.myReports,
    required this.myClaims,
  });

  final List<TransitLostFoundItem> openItems;
  final List<TransitLostFoundItem> myReports;
  final List<TransitLostFoundItem> myClaims;

  factory TransitLostFoundBundle.fromJson(Map<String, dynamic> json) =>
      TransitLostFoundBundle(
        openItems: (json['open_items'] as List?)
                ?.whereType<Map>()
                .map((e) => TransitLostFoundItem.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            const [],
        myReports: (json['my_reports'] as List?)
                ?.whereType<Map>()
                .map((e) => TransitLostFoundItem.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            const [],
        myClaims: (json['my_claims'] as List?)
                ?.whereType<Map>()
                .map((e) => TransitLostFoundItem.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            const [],
      );
}

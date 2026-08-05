import 'package:uuid/uuid.dart';

import '../domain/transit_models.dart';
import 'transit_repository.dart';

/// Offline demo data for Mwendokasi / DART when remote backend is disabled.
class SeedTransitRepository implements TransitRepository {
  static const _dartRouteId = 'seed-dart-kimara-kivukoni';
  static const _dalaMwengeId = 'seed-dala-mwenge-posta';
  static const _dalaSinzaId = 'seed-dala-sinza-kariakoo';

  static const _brtProducts = [
    TransitProduct(
      code: 'brt_single',
      name: 'BRT Single Ride',
      description: 'One boarding validation',
      ticketType: 'single',
      fareMinor: 650_00,
      currency: 'TZS',
      validityHours: 2,
      maxValidations: 1,
    ),
    TransitProduct(
      code: 'brt_daily',
      name: 'BRT Daily Pass',
      description: 'Unlimited corridor rides for 24 hours',
      ticketType: 'daily',
      fareMinor: 3_500_00,
      currency: 'TZS',
      validityHours: 24,
      maxValidations: 10,
    ),
  ];

  static const _dalaProducts = [
    TransitProduct(
      code: 'dala_single',
      name: 'Daladala Single Ride',
      description: 'One boarding validation',
      ticketType: 'single',
      fareMinor: 800_00,
      currency: 'TZS',
      validityHours: 2,
      maxValidations: 1,
    ),
    TransitProduct(
      code: 'dala_daily',
      name: 'Daladala Daily Pass',
      description: 'Unlimited daladala rides for 24 hours',
      ticketType: 'daily',
      fareMinor: 2_500_00,
      currency: 'TZS',
      validityHours: 24,
      maxValidations: 8,
    ),
  ];

  static final _dartRoute = TransitRoute(
    id: _dartRouteId,
    code: 'dart-kimara-kivukoni',
    name: 'Kimara — Kivukoni (Mwendokasi)',
    region: 'Dar es Salaam',
    fareMinor: 650_00,
    currency: 'TZS',
    metadata: const {
      'operator': 'DART',
      'mode': 'brt',
      'brand': 'Mwendokasi',
      'corridor': 'phase_1',
      'color': '#00A651',
    },
    stops: const [
      {'code': 'kimara', 'name': 'Kimara Terminal', 'sequence': 1},
      {'code': 'ubungo', 'name': 'Ubungo BRT', 'sequence': 2},
      {'code': 'morocco', 'name': 'Morocco', 'sequence': 3},
      {'code': 'kariakoo', 'name': 'Kariakoo', 'sequence': 4},
      {'code': 'posta', 'name': 'Posta', 'sequence': 5},
      {'code': 'kivukoni', 'name': 'Kivukoni', 'sequence': 6},
    ],
    departures: const [
      {'departure_time': '06:30:00', 'fare_minor': 650_00, 'currency': 'TZS'},
      {'departure_time': '07:30:00', 'fare_minor': 650_00, 'currency': 'TZS'},
      {'departure_time': '08:30:00', 'fare_minor': 650_00, 'currency': 'TZS'},
    ],
  );

  static final _dalaMwengeRoute = TransitRoute(
    id: _dalaMwengeId,
    code: 'dsm-dala-mwenge',
    name: 'Mwenge — Posta Daladala',
    region: 'Dar es Salaam',
    fareMinor: 800_00,
    currency: 'TZS',
    metadata: const {
      'operator': 'LATRA',
      'mode': 'daladala',
      'brand': 'Daladala',
      'color': '#F7941D',
    },
    stops: const [
      {'code': 'mwenge', 'name': 'Mwenge', 'sequence': 1},
      {'code': 'mustafa', 'name': 'Mustafa Centre', 'sequence': 2},
      {'code': 'posta', 'name': 'Posta', 'sequence': 3},
    ],
    departures: const [
      {'departure_time': '06:15:00', 'fare_minor': 800_00, 'currency': 'TZS'},
      {'departure_time': '07:15:00', 'fare_minor': 800_00, 'currency': 'TZS'},
    ],
  );

  static final _dalaSinzaRoute = TransitRoute(
    id: _dalaSinzaId,
    code: 'dsm-dala-sinza',
    name: 'Sinza — Kariakoo Daladala',
    region: 'Dar es Salaam',
    fareMinor: 700_00,
    currency: 'TZS',
    metadata: const {
      'operator': 'UDA',
      'mode': 'daladala',
      'brand': 'Daladala',
      'color': '#F7941D',
    },
    stops: const [
      {'code': 'sinza', 'name': 'Sinza', 'sequence': 1},
      {'code': 'magomeni', 'name': 'Magomeni', 'sequence': 2},
      {'code': 'kariakoo', 'name': 'Kariakoo', 'sequence': 3},
    ],
    departures: const [
      {'departure_time': '06:20:00', 'fare_minor': 700_00, 'currency': 'TZS'},
      {'departure_time': '07:20:00', 'fare_minor': 700_00, 'currency': 'TZS'},
    ],
  );

  static final _allRoutes = [_dartRoute, _dalaMwengeRoute, _dalaSinzaRoute];

  static final _stations = [
    const TransitStation(
      stopCode: 'kimara',
      name: 'Kimara Terminal',
      region: 'Dar es Salaam',
      latitude: -6.7201,
      longitude: 39.2088,
      distanceMeters: 420,
      platform: 'A',
      facilities: ['shelter', 'ticket_booth'],
    ),
    const TransitStation(
      stopCode: 'ubungo',
      name: 'Ubungo BRT',
      region: 'Dar es Salaam',
      latitude: -6.7912,
      longitude: 39.2089,
      distanceMeters: 2100,
      platform: 'B',
      facilities: ['shelter', 'restroom'],
    ),
    const TransitStation(
      stopCode: 'kariakoo',
      name: 'Kariakoo',
      region: 'Dar es Salaam',
      latitude: -6.8234,
      longitude: 39.2695,
      distanceMeters: 4800,
      platform: 'C',
      facilities: ['shelter'],
    ),
  ];

  final List<TransitTicket> _tickets = [];

  @override
  Future<TransitHome> loadHome({
    double? lat,
    double? lng,
    String region = 'Dar es Salaam',
    String mode = '',
  }) async {
    final routes = _routesForMode(mode);
    final products = _productsForMode(mode);
    return TransitHome(
      region: region,
      mode: mode,
      nearbyStations: _stations,
      featuredRoutes: routes,
      alerts: const [
        TransitAlert(
          id: 'seed-alert-1',
          title: 'Mwendokasi running on schedule',
          body: 'Peak service every 5 minutes on Kimara — Kivukoni corridor.',
          severity: 'info',
        ),
      ],
      products: products,
      recentTickets: List<TransitTicket>.from(_tickets.take(5)),
      unreadNotifications: _notifications.where((n) => !n.read).length,
    );
  }

  @override
  Future<List<TransitMode>> loadModes({String region = 'Dar es Salaam'}) async {
    return [
      TransitMode(
        id: 'brt',
        label: 'Mwendokasi BRT',
        operator: 'DART',
        color: '#00A651',
        routeCount: _allRoutes.where((r) => r.mode == 'brt').length,
      ),
      TransitMode(
        id: 'daladala',
        label: 'Daladala',
        operator: 'LATRA',
        color: '#F7941D',
        routeCount: _allRoutes.where((r) => r.mode == 'daladala').length,
      ),
    ];
  }

  List<TransitRoute> _routesForMode(String mode) {
    if (mode == 'brt') return [_dartRoute];
    if (mode == 'daladala') return [_dalaMwengeRoute, _dalaSinzaRoute];
    return List<TransitRoute>.from(_allRoutes);
  }

  List<TransitProduct> _productsForMode(String mode) {
    if (mode == 'brt') return List<TransitProduct>.from(_brtProducts);
    if (mode == 'daladala') return List<TransitProduct>.from(_dalaProducts);
    return [..._brtProducts, ..._dalaProducts];
  }

  @override
  Future<List<TransitRoute>> listRoutes({
    String region = '',
    String mode = '',
  }) async {
    if (region.isNotEmpty && !region.toLowerCase().contains('dar')) {
      return [];
    }
    return _routesForMode(mode);
  }

  @override
  Future<TransitRoute> getRoute(String id) async {
    for (final route in _allRoutes) {
      if (route.id == id) return route;
    }
    throw StateError('Route not found');
  }

  @override
  Future<List<TransitRoute>> search(String query, {String region = ''}) async {
    final q = query.toLowerCase();
    if (q.isEmpty) return List<TransitRoute>.from(_allRoutes);
    return _allRoutes
        .where(
          (r) =>
              r.name.toLowerCase().contains(q) ||
              r.code.toLowerCase().contains(q) ||
              r.brand.toLowerCase().contains(q) ||
              r.stops.any((s) => '${s['code']}'.toLowerCase().contains(q)),
        )
        .toList();
  }

  @override
  Future<TransitTicket> purchaseTicket({
    required String routeId,
    required String productCode,
    String originStop = '',
    String destinationStop = '',
    required String idempotencyKey,
  }) async {
    final route = await getRoute(routeId);
    final now = DateTime.now().toUtc();
    final id = const Uuid().v4();
    final prefix = route.mode == 'daladala' ? 'DALA' : 'BRT';
    final mediaCode = '$prefix-${id.substring(0, 8).toUpperCase()}';
    final ticket = TransitTicket(
      id: id,
      mediaCode: mediaCode,
      status: 'active',
      fareMinor: route.fareMinor,
      currency: route.currency,
      validFrom: now.toIso8601String(),
      validTo: now.add(const Duration(hours: 2)).toIso8601String(),
      routeName: route.name,
      routeCode: route.code,
      originStop: originStop,
      destinationStop: destinationStop,
      productCode: productCode,
      qr: {
        'ticket_id': id,
        'media_code': mediaCode,
        'route_code': route.code,
        'expires_at': now.add(const Duration(hours: 2)).millisecondsSinceEpoch ~/ 1000,
        'signature': 'seed-demo-signature',
        'kid': 'brt.v1',
      },
    );
    _tickets.insert(0, ticket);
    _notifications.insert(
      0,
      TransitNotification(
        id: const Uuid().v4(),
        eventType: 'transit.ticket.purchased',
        title: 'Ticket ready',
        body: 'Your ${route.brand} pass is active.',
        read: false,
        createdAt: now.toIso8601String(),
        payload: {'ticket_id': id, 'media_code': mediaCode},
      ),
    );
    return ticket;
  }

  @override
  Future<List<TransitTicket>> myTickets() async =>
      List<TransitTicket>.from(_tickets);

  @override
  Future<List<TransitProduct>> listProducts({String mode = ''}) async {
    return _productsForMode(mode);
  }

  @override
  Future<TransitStationDetail> getStation(String stopCode) async {
    final station = _stations.firstWhere(
      (s) => s.stopCode == stopCode,
      orElse: () => _stations.first,
    );
    return TransitStationDetail(
      stopCode: station.stopCode,
      name: station.name,
      region: station.region,
      latitude: station.latitude,
      longitude: station.longitude,
      imageUrl: station.imageUrl,
      facilities: station.facilities,
      accessibility: const {'wheelchair': true},
      platform: station.platform,
      upcoming: [
        {
          'route_code': 'dart-kimara-kivukoni',
          'route_name': 'Kimara — Kivukoni (Mwendokasi)',
          'departure_time': '07:30:00',
          'fare_minor': 650_00,
        },
      ],
    );
  }

  @override
  Future<List<TransitPlanOption>> planJourney({
    required String originStop,
    required String destinationStop,
    String region = '',
  }) async {
    final origin = originStop.toLowerCase();
    final destination = destinationStop.toLowerCase();
    final plans = <TransitPlanOption>[];

    for (final route in _allRoutes) {
      final stops = route.stops;
      final oIdx = stops.indexWhere((s) => '${s['code']}'.toLowerCase() == origin);
      final dIdx = stops.indexWhere((s) => '${s['code']}'.toLowerCase() == destination);
      if (oIdx >= 0 && dIdx > oIdx) {
        plans.add(
          TransitPlanOption(
            kind: 'direct',
            routeId: route.id,
            routeCode: route.code,
            routeName: route.name,
            mode: route.mode,
            brand: route.brand,
            originStop: origin,
            destinationStop: destination,
            fareMinor: route.fareMinor,
            currency: route.currency,
            durationMinutes: (dIdx - oIdx) * 8 + 5,
          ),
        );
      }
    }

    // Multimodal: sinza → kivukoni via kariakoo (daladala + BRT)
    if (origin == 'sinza' && destination == 'kivukoni') {
      plans.add(
        TransitPlanOption(
          kind: 'transfer',
          routeId: _dalaSinzaId,
          routeCode: 'dsm-dala-sinza',
          routeName: '${_dalaSinzaRoute.name} → ${_dartRoute.name}',
          mode: 'daladala+brt',
          brand: 'Multi-modal',
          originStop: origin,
          destinationStop: destination,
          transferStop: 'kariakoo',
          fareMinor: _dalaSinzaRoute.fareMinor + _dartRoute.fareMinor,
          currency: 'TZS',
          durationMinutes: 55,
          legs: [
            {
              'route_id': _dalaSinzaId,
              'route_code': _dalaSinzaRoute.code,
              'route_name': _dalaSinzaRoute.name,
              'origin_stop': origin,
              'destination_stop': 'kariakoo',
              'mode': 'daladala',
            },
            {
              'route_id': _dartRouteId,
              'route_code': _dartRoute.code,
              'route_name': _dartRoute.name,
              'origin_stop': 'kariakoo',
              'destination_stop': destination,
              'mode': 'brt',
            },
          ],
        ),
      );
    }

    return plans;
  }

  final List<TransitScheduledRun> _runs = [
    const TransitScheduledRun(
      id: 'seed-run-1',
      routeId: _dartRouteId,
      routeCode: 'dart-kimara-kivukoni',
      routeName: 'Kimara — Kivukoni (Mwendokasi)',
      vehicleLabel: 'DART-201',
      scheduledAt: '2026-07-23T08:00:00Z',
      originStop: 'kimara',
      destinationStop: 'kivukoni',
      status: 'scheduled',
      brand: 'Mwendokasi',
    ),
  ];

  @override
  Future<List<TransitScheduledRun>> driverRuns() async =>
      List<TransitScheduledRun>.from(_runs);

  @override
  Future<TransitScheduledRun> advanceDriverRun(String runId, String status) async {
    final idx = _runs.indexWhere((r) => r.id == runId);
    if (idx < 0) throw StateError('Run not found');
    final current = _runs[idx];
    final updated = TransitScheduledRun(
      id: current.id,
      routeId: current.routeId,
      routeCode: current.routeCode,
      routeName: current.routeName,
      vehicleLabel: current.vehicleLabel,
      scheduledAt: current.scheduledAt,
      originStop: current.originStop,
      destinationStop: current.destinationStop,
      status: status,
      brand: current.brand,
    );
    _runs[idx] = updated;
    return updated;
  }

  @override
  Future<TransitLiveMap> loadLiveMap({
    String region = 'Dar es Salaam',
    String routeId = '',
  }) async {
    return TransitLiveMap(
      region: region,
      routes: [
        TransitMapRoute(
          id: _dartRouteId,
          code: _dartRoute.code,
          name: _dartRoute.name,
          color: '#00A651',
          polyline: _stations
              .map(
                (s) => {
                  'code': s.stopCode,
                  'name': s.name,
                  'lat': s.latitude,
                  'lng': s.longitude,
                },
              )
              .toList(),
        ),
      ],
      stations: _stations
          .map(
            (s) => TransitMapStation(
              stopCode: s.stopCode,
              name: s.name,
              latitude: s.latitude,
              longitude: s.longitude,
              platform: s.platform,
            ),
          )
          .toList(),
      vehicles: const [
        TransitMapVehicle(
          id: 'seed-avl-1',
          vehicleLabel: 'DART-201',
          routeCode: 'dart-kimara-kivukoni',
          routeName: 'Kimara — Kivukoni (Mwendokasi)',
          latitude: -6.7350,
          longitude: 39.2095,
          heading: 95,
          speedKmh: 28,
          progressE4: 1500,
          nextStopCode: 'ubungo',
          etaNextStopSeconds: 240,
          status: 'in_service',
          brand: 'Mwendokasi',
        ),
      ],
    );
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
    return TransitMapVehicle(
      id: 'seed-ping',
      vehicleLabel: vehicleLabel,
      routeCode: _dartRoute.code,
      routeName: _dartRoute.name,
      latitude: latitude,
      longitude: longitude,
      heading: 90,
      speedKmh: speedKmh,
      progressE4: 3000,
      nextStopCode: nextStopCode,
      etaNextStopSeconds: etaNextStopSeconds,
      status: 'in_service',
      brand: 'Mwendokasi',
    );
  }

  TransitPassengerProfile _profile = const TransitPassengerProfile(
    homeStop: 'kimara',
    workStop: 'kivukoni',
    preferredLanguage: 'sw',
    accessibility: {'wheelchair': false, 'large_text': false},
  );

  final List<TransitFavorite> _favorites = [];
  final List<TransitNotification> _notifications = [];
  final List<TransitFeedback> _feedback = [];

  @override
  Future<TransitProfileBundle> loadProfile() async {
    return TransitProfileBundle(
      profile: _profile,
      stats: TransitTravelStats(
        totalTickets: _tickets.length,
        activeTickets: _tickets.where((t) => t.status == 'active').length,
        completedTrips: _tickets.where((t) => t.status == 'used').length,
        favoriteCount: _favorites.length,
      ),
      favorites: List<TransitFavorite>.from(_favorites),
    );
  }

  @override
  Future<TransitProfileBundle> updateProfile({
    String? homeStop,
    String? workStop,
    String? preferredLanguage,
    Map<String, dynamic>? accessibility,
  }) async {
    _profile = TransitPassengerProfile(
      homeStop: homeStop ?? _profile.homeStop,
      workStop: workStop ?? _profile.workStop,
      preferredLanguage: preferredLanguage ?? _profile.preferredLanguage,
      accessibility: accessibility ?? _profile.accessibility,
    );
    return loadProfile();
  }

  @override
  Future<List<TransitFavorite>> listFavorites() async =>
      List<TransitFavorite>.from(_favorites);

  @override
  Future<TransitFavorite> addFavorite({
    required String subjectType,
    required String subjectCode,
    String label = '',
  }) async {
    final fav = TransitFavorite(
      id: const Uuid().v4(),
      subjectType: subjectType,
      subjectCode: subjectCode,
      label: label.isNotEmpty ? label : subjectCode,
    );
    _favorites.removeWhere(
      (f) => f.subjectType == subjectType && f.subjectCode == subjectCode,
    );
    _favorites.insert(0, fav);
    return fav;
  }

  @override
  Future<void> removeFavorite(String favoriteId) async {
    _favorites.removeWhere((f) => f.id == favoriteId);
  }

  @override
  Future<List<TransitNotification>> listNotifications() async =>
      List<TransitNotification>.from(_notifications);

  @override
  Future<int> markNotificationsRead({List<String>? ids}) async {
    var count = 0;
    for (var i = 0; i < _notifications.length; i++) {
      final n = _notifications[i];
      if (n.read) continue;
      if (ids != null && ids.isNotEmpty && !ids.contains(n.id)) continue;
      _notifications[i] = TransitNotification(
        id: n.id,
        eventType: n.eventType,
        title: n.title,
        body: n.body,
        read: true,
        createdAt: n.createdAt,
        payload: n.payload,
      );
      count++;
    }
    return count;
  }

  @override
  Future<TransitFeedback> submitFeedback({
    required int rating,
    String comment = '',
    List<String> tags = const [],
    String? routeId,
    String? ticketId,
  }) async {
    final feedback = TransitFeedback(
      id: const Uuid().v4(),
      rating: rating,
      comment: comment,
      sentiment: rating >= 4 ? 'positive' : (rating == 3 ? 'neutral' : 'negative'),
      tags: tags,
      routeCode: _dartRoute.code,
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );
    _feedback.insert(0, feedback);
    return feedback;
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
    final id = const Uuid().v4();
    _notifications.insert(
      0,
      TransitNotification(
        id: const Uuid().v4(),
        eventType: 'transit.safety.sos',
        title: 'SOS sent to DART security',
        body: 'Your location was shared with transit safety operators.',
        read: false,
        createdAt: DateTime.now().toUtc().toIso8601String(),
        payload: {'incident_id': id, 'stop_code': stopCode},
      ),
    );
    return TransitSosResult(
      incidentId: id,
      status: 'open',
      kind: 'sos',
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );
  }

  @override
  Future<TransitAnalytics> loadAnalytics({
    String region = 'Dar es Salaam',
    int days = 7,
  }) async {
    final issued = _tickets.length;
    final validated = _tickets.fold<int>(0, (sum, t) => sum + (t.status == 'used' ? 1 : 0));
    return TransitAnalytics(
      region: region,
      days: days,
      daily: [
        {
          'date': DateTime.now().toUtc().toIso8601String().substring(0, 10),
          'tickets_issued': issued,
          'tickets_validated': validated,
          'fare_minor': _tickets.fold<int>(0, (sum, t) => sum + t.fareMinor),
        },
      ],
      byRoute: [
        {
          'route_code': _dartRoute.code,
          'tickets_issued': issued,
          'tickets_validated': validated,
          'fare_minor': _tickets.fold<int>(0, (sum, t) => sum + t.fareMinor),
        },
      ],
      ops: {
        'tickets_issued_today': issued,
        'validations_today': validated,
        'avl_vehicles_in_service': 1,
        'active_alerts': 1,
        'active_routes': 1,
      },
    );
  }

  @override
  Future<TransitRoute> adminUpdateRoute(String routeId, Map<String, dynamic> body) async {
    if (routeId != _dartRouteId) throw StateError('Route not found');
    return TransitRoute(
      id: _dartRoute.id,
      code: _dartRoute.code,
      name: '${body['name'] ?? _dartRoute.name}',
      region: _dartRoute.region,
      stops: _dartRoute.stops,
      metadata: _dartRoute.metadata,
      fareMinor: _dartRoute.fareMinor,
      currency: _dartRoute.currency,
      departures: _dartRoute.departures,
    );
  }

  @override
  Future<TransitProduct> adminUpdateProduct(String productId, Map<String, dynamic> body) async {
    return TransitProduct(
      code: '${body['code'] ?? 'seed-product'}',
      name: '${body['name'] ?? 'Product'}',
      description: '${body['description'] ?? ''}',
      ticketType: '${body['ticket_type'] ?? 'single'}',
      fareMinor: (body['fare_minor'] as num?)?.toInt() ?? 650_00,
      currency: '${body['currency'] ?? 'TZS'}',
      validityHours: (body['validity_hours'] as num?)?.toInt() ?? 2,
      maxValidations: (body['max_validations'] as num?)?.toInt() ?? 1,
    );
  }

  @override
  Future<TransitProduct> adminCreateProduct(Map<String, dynamic> body) async =>
      adminUpdateProduct('new', body);

  @override
  Future<TransitAssistantReply> askAssistant({
    required String query,
    String locale = '',
    String region = 'Dar es Salaam',
  }) async {
    final lower = query.toLowerCase();
    final isSw = locale == 'sw' || lower.contains('kutoka') || lower.contains('hadi');
    if (lower.contains('kutoka kimara') && lower.contains('kivukoni')) {
      return TransitAssistantReply(
        query: query,
        locale: isSw ? 'sw' : 'en',
        intent: 'plan_journey',
        reply: isSw
            ? 'Njia ya Mwendokasi kutoka Kimara hadi Kivukoni inapatikana.'
            : 'Mwendokasi corridor route from Kimara to Kivukoni is available.',
        originStop: 'kimara',
        destinationStop: 'kivukoni',
        plans: await planJourney(
          originStop: 'kimara',
          destinationStop: 'kivukoni',
          region: region,
        ),
        suggestedActions: [
          TransitAssistantAction(
            action: 'open_planner',
            label: isSw ? 'Angalia mpango' : 'View plan',
            originStop: 'kimara',
            destinationStop: 'kivukoni',
          ),
        ],
      );
    }
    if (lower.contains('ubungo') || lower.contains('search') || lower.contains('tafuta')) {
      return TransitAssistantReply(
        query: query,
        locale: isSw ? 'sw' : 'en',
        intent: 'search',
        reply: isSw ? 'Nimepata stesheni za Ubungo.' : 'Found Ubungo station matches.',
        originStop: '',
        destinationStop: '',
        plans: const [],
        suggestedActions: const [
          TransitAssistantAction(
            action: 'open_station',
            label: 'Ubungo BRT',
            stopCode: 'ubungo',
          ),
        ],
      );
    }
    return TransitAssistantReply(
      query: query,
      locale: isSw ? 'sw' : 'en',
      intent: 'general',
      reply: isSw
          ? 'Uliza kuhusu safari, stesheni, au andika kutoka Kimara hadi Kivukoni.'
          : 'Ask about trips, stations, or try from Kimara to Kivukoni.',
      originStop: '',
      destinationStop: '',
      plans: const [],
      suggestedActions: const [],
    );
  }

  final List<TransitFamilyMember> _familyMembers = [
    const TransitFamilyMember(
      id: 'seed-family-1',
      memberOwner: 'device:child-demo',
      displayName: 'Amina (demo)',
      relationship: 'child',
      status: 'active',
      canPurchase: true,
      monthlyLimitMinor: 50_000_00,
      spentThisMonthMinor: 650_00,
      activeTickets: 0,
    ),
  ];

  @override
  Future<TransitFamilyBundle> loadFamilyBundle() async {
    return TransitFamilyBundle(
      guardianOwner: 'device:guardian-demo',
      members: List.unmodifiable(_familyMembers),
      tickets: _tickets
          .where((t) => t.beneficiaryDisplayName.isNotEmpty)
          .toList(growable: false),
    );
  }

  @override
  Future<List<TransitFamilyMember>> listFamilyMembers() async =>
      List.unmodifiable(_familyMembers);

  @override
  Future<TransitFamilyMember> addFamilyMember({
    required String memberOwner,
    required String displayName,
    String relationship = 'child',
    int monthlyLimitMinor = 0,
  }) async {
    final member = TransitFamilyMember(
      id: const Uuid().v4(),
      memberOwner: memberOwner,
      displayName: displayName.isNotEmpty ? displayName : memberOwner,
      relationship: relationship,
      status: 'active',
      canPurchase: true,
      monthlyLimitMinor: monthlyLimitMinor,
      spentThisMonthMinor: 0,
      activeTickets: 0,
    );
    _familyMembers.add(member);
    return member;
  }

  @override
  Future<void> removeFamilyMember(String memberId) async {
    _familyMembers.removeWhere((m) => m.id == memberId);
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
    final member = _familyMembers.firstWhere(
      (m) => m.memberOwner == beneficiaryOwner,
      orElse: () => throw StateError('Family member not linked'),
    );
    if (member.monthlyLimitMinor > 0 &&
        member.spentThisMonthMinor + _dartRoute.fareMinor > member.monthlyLimitMinor) {
      throw StateError('Monthly family spend limit exceeded');
    }
    final route = await getRoute(routeId);
    final now = DateTime.now().toUtc();
    final id = const Uuid().v4();
    final prefix = route.mode == 'daladala' ? 'DALA' : 'BRT';
    final mediaCode = '$prefix-${id.substring(0, 8).toUpperCase()}';
    final ticket = TransitTicket(
      id: id,
      mediaCode: mediaCode,
      status: 'active',
      fareMinor: route.fareMinor,
      currency: route.currency,
      validFrom: now.toIso8601String(),
      validTo: now.add(const Duration(hours: 2)).toIso8601String(),
      routeName: route.name,
      routeCode: route.code,
      originStop: originStop,
      destinationStop: destinationStop,
      productCode: productCode,
      guardianOwner: 'device:guardian-demo',
      beneficiaryDisplayName: member.displayName,
      qr: {
        'ticket_id': id,
        'media_code': mediaCode,
        'route_code': route.code,
      },
    );
    _tickets.insert(0, ticket);
    final idx = _familyMembers.indexWhere((m) => m.id == member.id);
    if (idx >= 0) {
      _familyMembers[idx] = TransitFamilyMember(
        id: member.id,
        memberOwner: member.memberOwner,
        displayName: member.displayName,
        relationship: member.relationship,
        status: member.status,
        canPurchase: member.canPurchase,
        monthlyLimitMinor: member.monthlyLimitMinor,
        spentThisMonthMinor: member.spentThisMonthMinor + route.fareMinor,
        activeTickets: member.activeTickets + 1,
      );
    }
    return ticket;
  }

  final List<TransitLostFoundItem> _lostFoundItems = [
    TransitLostFoundItem(
      id: 'seed-lf-1',
      reporterOwner: 'device:station-demo',
      kind: 'found',
      category: 'phone',
      title: 'Android phone (demo)',
      description: 'Found near ticket gates, black case',
      stopCode: 'ubungo',
      routeCode: 'dart-kimara-kivukoni',
      status: 'open',
      contactHint: '',
      claimantOwner: '',
      claimMessage: '',
      claimedAt: '',
      resolvedAt: '',
      createdAt: DateTime.now().toUtc().toIso8601String(),
      photoUrl: '',
    ),
  ];

  @override
  Future<TransitLostFoundBundle> loadLostFoundBundle({
    String kind = '',
    String stopCode = '',
  }) async {
    var open = _lostFoundItems.where((i) => i.status == 'open' || i.status == 'claimed');
    if (kind.isNotEmpty) open = open.where((i) => i.kind == kind);
    if (stopCode.isNotEmpty) open = open.where((i) => i.stopCode == stopCode);
    return TransitLostFoundBundle(
      openItems: open.toList(growable: false),
      myReports: _lostFoundItems
          .where((i) => i.reporterOwner == 'device:guardian-demo')
          .toList(growable: false),
      myClaims: const [],
    );
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
    final item = TransitLostFoundItem(
      id: const Uuid().v4(),
      reporterOwner: 'device:guardian-demo',
      kind: kind,
      category: category,
      title: title,
      description: description,
      stopCode: stopCode,
      routeCode: routeId != null ? _dartRoute.code : '',
      status: 'open',
      contactHint: contactHint,
      claimantOwner: '',
      claimMessage: '',
      claimedAt: '',
      resolvedAt: '',
      createdAt: DateTime.now().toUtc().toIso8601String(),
      photoUrl: photoUrl,
    );
    _lostFoundItems.insert(0, item);
    return item;
  }

  @override
  Future<TransitLostFoundItem> claimLostFound({
    required String itemId,
    String message = '',
  }) async {
    final idx = _lostFoundItems.indexWhere((i) => i.id == itemId);
    if (idx < 0) throw StateError('item not found');
    final item = _lostFoundItems[idx];
    if (!item.isFound || !item.isOpen) throw StateError('item is not open for claims');
    final updated = TransitLostFoundItem(
      id: item.id,
      reporterOwner: item.reporterOwner,
      kind: item.kind,
      category: item.category,
      title: item.title,
      description: item.description,
      stopCode: item.stopCode,
      routeCode: item.routeCode,
      status: 'claimed',
      contactHint: item.contactHint,
      claimantOwner: 'device:guardian-demo',
      claimMessage: message,
      claimedAt: DateTime.now().toUtc().toIso8601String(),
      resolvedAt: '',
      createdAt: item.createdAt,
      photoUrl: item.photoUrl,
    );
    _lostFoundItems[idx] = updated;
    return updated;
  }

  @override
  Future<TransitLostFoundItem> resolveLostFound({
    required String itemId,
    String status = 'closed',
  }) async {
    final idx = _lostFoundItems.indexWhere((i) => i.id == itemId);
    if (idx < 0) throw StateError('item not found');
    final item = _lostFoundItems[idx];
    final updated = TransitLostFoundItem(
      id: item.id,
      reporterOwner: item.reporterOwner,
      kind: item.kind,
      category: item.category,
      title: item.title,
      description: item.description,
      stopCode: item.stopCode,
      routeCode: item.routeCode,
      status: status,
      contactHint: item.contactHint,
      claimantOwner: item.claimantOwner,
      claimMessage: item.claimMessage,
      claimedAt: item.claimedAt,
      resolvedAt: DateTime.now().toUtc().toIso8601String(),
      createdAt: item.createdAt,
      photoUrl: item.photoUrl,
    );
    _lostFoundItems[idx] = updated;
    return updated;
  }

  @override
  Future<String> uploadLostFoundPhoto({
    required List<int> bytes,
    String contentType = 'image/jpeg',
  }) async =>
      'https://storage.local/transit/lost-found/demo.${contentType.contains('png') ? 'png' : 'jpg'}';

  @override
  Future<List<TransitLostFoundItem>> loadAdminLostFound({String status = ''}) async {
    var items = _lostFoundItems;
    if (status.isNotEmpty) items = items.where((i) => i.status == status).toList();
    return List.unmodifiable(items);
  }

  @override
  Future<TransitLostFoundItem> opsResolveLostFound({
    required String itemId,
    String status = 'closed',
  }) async =>
      resolveLostFound(itemId: itemId, status: status);
}

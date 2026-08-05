import 'package:flutter_test/flutter_test.dart';
import 'package:taifa/data/api/api_client.dart';
import 'package:taifa/data/api/api_exception.dart';
import 'package:taifa/data/trips/rest_transit_repository.dart';
import 'package:taifa/data/trips/transit_api_paths.dart';
import 'package:taifa/features/mobility_transit/application/seed_transit_repository.dart';

class _FakeTransitClient implements TaifaApiClient {
  _FakeTransitClient({this.getResponse, this.postResponse, this.getListResponse});

  Map<String, dynamic>? getResponse;
  Map<String, dynamic>? postResponse;
  List<dynamic>? getListResponse;

  String? lastGetPath;
  String? lastPostPath;
  String? lastIdempotencyKey;
  Map<String, dynamic>? lastBody;

  @override
  Future<Map<String, dynamic>> getJson(String path) async {
    lastGetPath = path;
    return getResponse ?? {};
  }

  @override
  Future<List<dynamic>> getJsonList(String path) async {
    lastGetPath = path;
    return getListResponse ?? const [];
  }

  @override
  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic> body = const {},
    String? idempotencyKey,
  }) async {
    lastPostPath = path;
    lastBody = body;
    lastIdempotencyKey = idempotencyKey;
    return postResponse!;
  }

  @override
  Future<Map<String, dynamic>> patchJson(
    String path, {
    Map<String, dynamic> body = const {},
  }) async =>
      postResponse ?? {};

  @override
  Future<void> deleteJson(String path) async {}
}

void main() {
  group('RestTransitRepository', () {
    test('loadHome parses bundled payload', () async {
      final client = _FakeTransitClient(
        getResponse: {
          'region': 'Dar es Salaam',
          'nearby_stations': [
            {
              'stop_code': 'kimara',
              'name': 'Kimara Terminal',
              'region': 'Dar es Salaam',
              'latitude': -6.72,
              'longitude': 39.20,
              'distance_meters': 400,
            },
          ],
          'featured_routes': [
            {
              'id': 'route-1',
              'code': 'dart-kimara-kivukoni',
              'name': 'Kimara — Kivukoni',
              'region': 'Dar es Salaam',
              'stops': [],
              'metadata': {'brand': 'Mwendokasi', 'mode': 'brt'},
              'fare_minor': 650_00,
              'currency': 'TZS',
            },
          ],
          'alerts': [],
          'recent_tickets': [],
        },
      );
      final repo = RestTransitRepository(client);
      final home = await repo.loadHome(lat: -6.79, lng: 39.21);
      expect(home.region, 'Dar es Salaam');
      expect(home.nearbyStations, hasLength(1));
      expect(home.featuredRoutes.first.code, 'dart-kimara-kivukoni');
      expect(client.lastGetPath, contains(TransitApiPaths.home));
    });

    test('purchaseTicket sends idempotency key and route id', () async {
      final client = _FakeTransitClient(
        postResponse: {
          'id': 'ticket-1',
          'media_code': 'BRT-ABCDEF12',
          'status': 'active',
          'fare_minor': 650_00,
          'currency': 'TZS',
          'valid_from': '2026-07-21T10:00:00Z',
          'valid_to': '2026-07-21T12:00:00Z',
          'qr': {'media_code': 'BRT-ABCDEF12'},
        },
      );
      final repo = RestTransitRepository(client);
      final ticket = await repo.purchaseTicket(
        routeId: 'route-1',
        productCode: 'brt_single',
        idempotencyKey: 'idem-123',
      );
      expect(ticket.mediaCode, 'BRT-ABCDEF12');
      expect(client.lastPostPath, TransitApiPaths.ticketsPurchase);
      expect(client.lastIdempotencyKey, 'idem-123');
      expect(client.lastBody?['route_id'], 'route-1');
    });

    test('loadFamilyBundle parses members and tickets', () async {
      final client = _FakeTransitClient(
        getResponse: {
          'guardian_owner': 'device:guardian',
          'members': [
            {
              'id': 'fam-1',
              'member_owner': 'device:child',
              'display_name': 'Amina',
              'relationship': 'child',
              'status': 'active',
              'can_purchase': true,
              'monthly_limit_minor': 50_000_00,
              'spent_this_month_minor': 650_00,
              'active_tickets': 1,
            },
          ],
          'tickets': [],
        },
      );
      final repo = RestTransitRepository(client);
      final bundle = await repo.loadFamilyBundle();
      expect(client.lastGetPath, TransitApiPaths.family);
      expect(bundle.members, hasLength(1));
      expect(bundle.members.first.displayName, 'Amina');
    });

    test('purchaseTicketForMember sends beneficiary_owner', () async {
      final client = _FakeTransitClient(
        postResponse: {
          'id': 'ticket-2',
          'media_code': 'BRT-CHILD01',
          'status': 'active',
          'fare_minor': 650_00,
          'currency': 'TZS',
          'valid_from': '2026-07-21T10:00:00Z',
          'valid_to': '2026-07-21T12:00:00Z',
          'qr': {'media_code': 'BRT-CHILD01'},
          'beneficiary_display_name': 'Amina',
        },
      );
      final repo = RestTransitRepository(client);
      final ticket = await repo.purchaseTicketForMember(
        routeId: 'route-1',
        productCode: 'brt_single',
        beneficiaryOwner: 'device:child',
        idempotencyKey: 'idem-family',
      );
      expect(ticket.mediaCode, 'BRT-CHILD01');
      expect(client.lastBody?['beneficiary_owner'], 'device:child');
    });

    test('loadHome passes mode filter', () async {
      final client = _FakeTransitClient(
        getResponse: {
          'region': 'Dar es Salaam',
          'mode': 'daladala',
          'nearby_stations': [],
          'featured_routes': [],
          'alerts': [],
          'recent_tickets': [],
          'products': [],
        },
      );
      final repo = RestTransitRepository(client);
      final home = await repo.loadHome(mode: 'daladala');
      expect(home.mode, 'daladala');
      expect(client.lastGetPath, contains('mode=daladala'));
    });

    test('loadModes parses catalog', () async {
      final client = _FakeTransitClient(
        getResponse: {
          'modes': [
            {
              'id': 'brt',
              'label': 'Mwendokasi BRT',
              'operator': 'DART',
              'color': '#00A651',
              'routes': 1,
            },
            {
              'id': 'daladala',
              'label': 'Daladala',
              'operator': 'LATRA',
              'color': '#F7941D',
              'routes': 2,
            },
          ],
        },
      );
      final repo = RestTransitRepository(client);
      final modes = await repo.loadModes();
      expect(client.lastGetPath, contains(TransitApiPaths.modes));
      expect(modes, hasLength(2));
      expect(modes.last.id, 'daladala');
      expect(modes.last.routeCount, 2);
    });

    test('loadLostFoundBundle parses open items', () async {
      final client = _FakeTransitClient(
        getResponse: {
          'open_items': [
            {
              'id': 'lf-1',
              'kind': 'found',
              'category': 'phone',
              'title': 'Android phone',
              'stop_code': 'ubungo',
              'status': 'open',
            },
          ],
          'my_reports': [],
          'my_claims': [],
        },
      );
      final repo = RestTransitRepository(client);
      final bundle = await repo.loadLostFoundBundle(kind: 'found');
      expect(client.lastGetPath, '${TransitApiPaths.lostFound}?kind=found');
      expect(bundle.openItems, hasLength(1));
      expect(bundle.openItems.first.title, 'Android phone');
    });
  });

  group('SeedTransitRepository', () {
    test('offline purchase issues ticket with qr payload', () async {
      final repo = SeedTransitRepository();
      final routes = await repo.listRoutes();
      final ticket = await repo.purchaseTicket(
        routeId: routes.first.id,
        productCode: 'brt_single',
        idempotencyKey: 'seed-key',
      );
      expect(ticket.status, 'active');
      expect(ticket.qr['media_code'], ticket.mediaCode);
      final mine = await repo.myTickets();
      expect(mine, isNotEmpty);
    });
    test('offline daladala purchase uses DALA prefix', () async {
      final repo = SeedTransitRepository();
      final routes = await repo.listRoutes(mode: 'daladala');
      expect(routes, hasLength(2));
      final ticket = await repo.purchaseTicket(
        routeId: routes.first.id,
        productCode: 'dala_single',
        idempotencyKey: 'seed-dala',
      );
      expect(ticket.mediaCode, startsWith('DALA-'));
    });

    test('planJourney includes transfer for sinza to kivukoni', () async {
      final repo = SeedTransitRepository();
      final plans = await repo.planJourney(
        originStop: 'sinza',
        destinationStop: 'kivukoni',
      );
      expect(plans.any((p) => p.isTransfer), isTrue);
      final transfer = plans.firstWhere((p) => p.isTransfer);
      expect(transfer.transferStop, 'kariakoo');
      expect(transfer.legs, hasLength(2));
    });
  });
}

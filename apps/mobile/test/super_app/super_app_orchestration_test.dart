import 'package:flutter_test/flutter_test.dart';

import 'package:taifa/features/super_app/domain/ecosystem_catalog.dart';
import 'package:taifa/features/super_app/domain/qr_resolver.dart';
import 'package:taifa/features/ai/gateways/ai_gateway.dart';

void main() {
  group('EcosystemCatalog', () {
    test('finds mobility for ride query', () {
      final hits = EcosystemCatalog.search('ride');
      expect(hits, isNotEmpty);
      expect(hits.first.route, '/mobility');
    });

    test('finds pay for lipa query', () {
      final hits = EcosystemCatalog.search('lipa');
      expect(hits.any((e) => e.category == 'Pay'), isTrue);
    });
  });

  group('QrResolver', () {
    const resolver = QrResolver();

    test('routes MAP payment QR to map pay', () {
      final r = resolver.resolve(
        'taifa://pay/map-seed?q=pi_abc&a=1000&c=TZS&i=pi_abc&e=&s=x',
      );
      expect(r.kind, QrKind.payment);
      expect(r.route, '/map/pay');
    });

    test('routes ride QR to mobility', () {
      final r = resolver.resolve('taifa://ride/demo');
      expect(r.route, '/mobility');
      expect(r.kind, QrKind.mobility);
    });
  });

  group('AI payment guard', () {
    test('refuses to authorize payments', () async {
      final gw = MockAiGateway();
      final msg = await gw.complete(history: const [], userText: 'authorize payment now');
      expect(msg.text.toLowerCase(), contains('never authorize'));
    });
  });
}

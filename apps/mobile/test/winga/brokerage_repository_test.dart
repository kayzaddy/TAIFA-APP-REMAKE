import 'package:flutter_test/flutter_test.dart';

import 'package:taifa/features/winga/application/seed_brokerage_repository.dart';
import 'package:taifa/features/winga/domain/brokerage_models.dart';

void main() {
  late SeedBrokerageRepository repo;

  setUp(() {
    repo = SeedBrokerageRepository();
  });

  test('domains and offerings load offline', () async {
    final domains = await repo.domains();
    expect(domains, isNotEmpty);
    final offerings = await repo.offerings(domainCode: 'hotels');
    expect(offerings.every((o) => o.domainId == domains.firstWhere((d) => d.code == 'hotels').id), isTrue);
  });

  test('AI assist blocks payment authorization capabilities', () async {
    expect(
      () => repo.assist(capability: 'authorize_payment'),
      throwsA(isA<StateError>()),
    );
  });

  test('deal pay then commission settle', () async {
    final domains = await repo.domains();
    final wingas = await repo.wingas();
    final providers = await repo.providers();
    final offerings = await repo.offerings();
    final deal = await repo.openDeal(
      wingaId: wingas.first.id,
      providerId: providers.first.id,
      domainId: domains.first.id,
      customerPrincipal: 'c1',
      amountMinor: 100000,
      offeringId: offerings.first.id,
    );
    expect(deal.stage, DealStageUi.accepted);
    final paid = await repo.payDeal(deal.id, idempotencyKey: 'k1');
    expect(paid.isPaid, isTrue);
    final settled = await repo.settleCommission(deal.id);
    expect(settled, isNotEmpty);
    expect(settled.first.isSettled, isTrue);
  });

  test('dealStageFromApi maps commission_payout', () {
    expect(dealStageFromApi('commission_payout'), DealStageUi.commissionPayout);
    expect(dealStageToApi(DealStageUi.commissionPayout), 'commission_payout');
  });
}

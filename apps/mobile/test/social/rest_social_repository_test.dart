import 'package:flutter_test/flutter_test.dart';
import 'package:taifa/data/api/api_exception.dart';
import 'package:taifa/data/dto/social_dto.dart';
import 'package:taifa/data/social/social_repository.dart';
import 'package:taifa/features/wallet/domain/currency.dart';
import 'package:taifa/features/wallet/domain/money.dart';

import '../helpers/fake_api_client.dart';

void main() {
  group('RestSocialRepository.listLinks', () {
    test('maps GET /payments/links onto PaymentLink models', () async {
      final client = FakeApiClient(
        getResponse: {
          'links': [
            {
              'id': 'l1', 'slug': 'abc123', 'owner': 'dev_a', 'display_name': 'Mama Ntilie',
              'amount_minor': 5500000, 'currency': 'TZS', 'note': 'Lunch', 'emoji': '🍟',
              'status': 'active', 'single_use': false, 'fee_bps': 0,
              'total_paid_minor': 0, 'payment_count': 0, 'created_at': '2026-08-08T10:00:00Z',
            },
          ],
        },
      );
      final repo = RestSocialRepository(client);
      final links = await repo.listLinks();
      expect(client.lastGetPath, 'payments/links');
      expect(links, hasLength(1));
      expect(links.first.slug, 'abc123');
      expect(links.first.amount, Money(5500000, Currency.tzs));
      expect(links.first.status, PaymentLinkStatus.active);
    });

    test('open-amount link decodes amount as null', () async {
      final client = FakeApiClient(
        getResponse: {
          'links': [
            {
              'id': 'l2', 'slug': 'xyz', 'owner': 'dev_a', 'display_name': '',
              'amount_minor': null, 'currency': 'TZS', 'note': '', 'emoji': '',
              'status': 'active', 'single_use': false, 'fee_bps': 0,
              'total_paid_minor': 0, 'payment_count': 0, 'created_at': '2026-08-08T10:00:00Z',
            },
          ],
        },
      );
      final links = await RestSocialRepository(client).listLinks();
      expect(links.first.amount, isNull);
    });
  });

  group('RestSocialRepository.payLink', () {
    test('posts to pay/{slug}/confirm with an idempotency key', () async {
      final client = FakeApiClient(
        postResponse: {
          'id': 't1', 'type': 'send_money', 'status': 'succeeded', 'direction': 'debit',
          'amount_minor': 20000, 'currency': 'TZS', 'counterparty': 'Shop', 'method_kind': 'wallet',
          'created_at': '2026-08-08T10:00:00Z',
        },
      );
      final txn = await RestSocialRepository(client).payLink('abc123');
      expect(client.lastPostPath, 'payments/pay/abc123/confirm');
      expect(client.lastIdempotencyKey, isNotNull);
      expect(txn.status.name, 'succeeded');
    });

    test('surfaces the server detail message as a SocialException', () async {
      final client = FakeApiClient(
        throwOnPost: const ApiStatusException(403, 'denied', body: {'detail': 'Spending cap exceeded.', 'code': 'SPENDING_CAP_EXCEEDED'}),
      );
      await expectLater(
        RestSocialRepository(client).payLink('abc123'),
        throwsA(isA<SocialException>().having((e) => e.message, 'message', 'Spending cap exceeded.').having((e) => e.code, 'code', 'SPENDING_CAP_EXCEEDED')),
      );
    });
  });

  group('RestSocialRepository.createRequest', () {
    test('sends payer_phone and amount in the request body', () async {
      final client = FakeApiClient(
        postResponse: {
          'id': 'r1', 'requester': 'dev_a', 'requester_name': 'Alice', 'payer': 'dev_b', 'payer_name': 'Bob',
          'amount_minor': 500000, 'currency': 'TZS', 'note': '', 'emoji': '', 'status': 'pending',
          'transaction_id': null, 'created_at': '2026-08-08T10:00:00Z',
        },
      );
      final req = await RestSocialRepository(client).createRequest(
        payerPhone: '+255700000000',
        amount: Money.major(5000, Currency.tzs),
      );
      expect(client.lastBody!['payer_phone'], '+255700000000');
      expect(client.lastBody!['amount_minor'], 500000);
      expect(req.status.name, 'pending');
    });
  });

  group('RestSocialRepository.getSpendingCap', () {
    test('returns null on a 204-shaped decode failure', () async {
      final client = FakeApiClient(getResponse: null); // empty body -> ApiDecodeException
      final cap = await RestSocialRepository(client).getSpendingCap();
      expect(cap, isNull);
    });

    test('parses a set cap', () async {
      final client = FakeApiClient(
        getResponse: {
          'period': 'monthly', 'limit_minor': 5000000, 'currency': 'TZS',
          'spent_minor': 1000000, 'remaining_minor': 4000000, 'period_start': '2026-08-01T00:00:00Z',
        },
      );
      final cap = await RestSocialRepository(client).getSpendingCap();
      expect(cap, isNotNull);
      expect(cap!.period, SpendingCapPeriod.monthly);
      expect(cap.remaining, Money(4000000, Currency.tzs));
    });
  });

  group('RestSocialRepository.searchTransactions', () {
    test('builds the query string and parses the page envelope', () async {
      final client = FakeApiClient(
        getResponse: {
          'count': 1, 'page': 1, 'num_pages': 1,
          'results': [
            {
              'id': 't1', 'type': 'top_up', 'status': 'succeeded', 'direction': 'credit',
              'amount_minor': 100000, 'currency': 'TZS', 'counterparty': '', 'method_kind': 'wallet',
              'created_at': '2026-08-08T10:00:00Z',
            },
          ],
        },
      );
      final page = await RestSocialRepository(client).searchTransactions(type: 'top_up', query: 'lunch');
      expect(client.lastGetPath, contains('type=top_up'));
      expect(client.lastGetPath, contains('q=lunch'));
      expect(page.count, 1);
      expect(page.results, hasLength(1));
    });
  });
}

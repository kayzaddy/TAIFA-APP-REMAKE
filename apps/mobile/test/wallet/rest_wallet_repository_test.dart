import 'package:flutter_test/flutter_test.dart';
import 'package:taifa/data/api/api_client.dart';
import 'package:taifa/data/api/api_exception.dart';
import 'package:taifa/data/wallet/rest_wallet_repository.dart';
import 'package:taifa/features/wallet/application/wallet_profile.dart';
import 'package:taifa/features/wallet/application/wallet_repository.dart';
import 'package:taifa/features/wallet/domain/currency.dart';
import 'package:taifa/features/wallet/domain/money.dart';
import 'package:taifa/features/wallet/domain/payment_method.dart';
import 'package:taifa/features/wallet/domain/transaction.dart';

/// A programmable [TaifaApiClient] that records requests and returns canned
/// responses — no `http`, no network. Lets us verify the repository speaks the
/// backend's contract exactly.
class FakeApiClient implements TaifaApiClient {
  FakeApiClient({
    this.getResponse,
    this.getListResponse,
    this.postResponse,
    this.patchResponse,
    this.throwOnPost,
  });

  Map<String, dynamic>? getResponse;
  List<dynamic>? getListResponse;
  Map<String, dynamic>? postResponse;
  Map<String, dynamic>? patchResponse;
  ApiException? throwOnPost;

  String? lastGetPath;
  String? lastPostPath;
  String? lastPatchPath;
  Map<String, dynamic>? lastBody;
  String? lastIdempotencyKey;

  @override
  Future<Map<String, dynamic>> getJson(String path) async {
    lastGetPath = path;
    return getResponse ?? (throw const ApiDecodeException());
  }

  @override
  Future<List<dynamic>> getJsonList(String path) async {
    lastGetPath = path;
    return getListResponse ?? (throw const ApiDecodeException());
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
    if (throwOnPost != null) throw throwOnPost!;
    return postResponse!;
  }

  @override
  Future<Map<String, dynamic>> patchJson(
    String path, {
    Map<String, dynamic> body = const {},
  }) async {
    lastPatchPath = path;
    lastBody = body;
    return patchResponse ?? postResponse ?? (throw const ApiDecodeException());
  }

  @override
  Future<void> deleteJson(String path) async {}
}

void main() {
  final fatima = defaultWalletProfile.recipients.first; // M-Pesa recipient

  group('RestWalletRepository.load', () {
    test('maps GET /payments/wallet onto a snapshot', () async {
      final client = FakeApiClient(
        getResponse: {
          'owner': 'dev_x',
          'currency': 'TZS',
          'balance_minor': 284750000,
          'balance_display': 'TSh 2,847,500',
          'transactions': [
            {
              'id': 'abc-1',
              'type': 'send_money',
              'status': 'succeeded',
              'direction': 'debit',
              'amount_minor': 25000000,
              'fee_minor': 0,
              'currency': 'TZS',
              'counterparty': 'Juma Ally',
              'method_kind': 'mobile_money',
              'method_ref': '+255655000043',
              'operator': 'airtel_money',
              'provider': 'AIRTEL_MONEY',
              'provider_ref': 'REF1',
              'note': '',
              'ledger_entry': 'led-1',
              'created_at': '2026-07-10T21:00:00Z',
            },
          ],
        },
      );

      final snapshot = await RestWalletRepository(client).load();

      expect(snapshot.balance, Money.major(2847500, Currency.tzs));
      expect(snapshot.transactions, hasLength(1));
      expect(snapshot.transactions.first.counterparty, 'Juma Ally');
      expect(
        snapshot.transactions.first.amount,
        Money.major(250000, Currency.tzs),
      );
      // Profile scaffolding is composed on top of live money data.
      expect(snapshot.recipients, isNotEmpty);
      expect(snapshot.cardholderName, defaultWalletProfile.cardholderName);
    });

    test('translates a network error into a WalletException', () async {
      final client = FakeApiClient()..getResponse = null;
      // getJson throws ApiDecodeException by default here; assert it surfaces.
      expect(
        () => RestWalletRepository(client).load(),
        throwsA(isA<WalletException>()),
      );
    });
  });

  group('RestWalletRepository.transfer', () {
    test('POSTs the backend contract with an idempotency key', () async {
      final client = FakeApiClient(
        postResponse: {
          'id': 'txn-9',
          'type': 'send_money',
          'status': 'processing',
          'direction': 'debit',
          'amount_minor': 25000000,
          'fee_minor': 0,
          'currency': 'TZS',
          'counterparty': 'Fatima Salim',
          'method_kind': 'mobile_money',
          'method_ref': '255754000891',
          'operator': 'mpesa',
          'provider': 'MPESA',
          'provider_ref': 'ws_CO_1',
          'note': '',
          'ledger_entry': null,
          'created_at': '2026-07-10T21:05:00Z',
        },
      );

      final receipt = await RestWalletRepository(client).transfer(
        TransferCommand(
          recipient: fatima,
          amount: Money.major(250000, Currency.tzs),
          fee: Money.zero(Currency.tzs),
          idempotencyKey: 'send_test_1',
          note: 'lunch',
        ),
      );

      expect(client.lastPostPath, 'payments/transfers');
      expect(client.lastIdempotencyKey, 'send_test_1');
      expect(client.lastBody!['amount_minor'], 25000000);
      expect(client.lastBody!['method_kind'], 'mobile_money');
      expect(client.lastBody!['operator'], 'mpesa');
      expect(client.lastBody!['method_ref'], '+255754000891');

      expect(receipt.transaction.status, TransactionStatus.processing);
      expect(receipt.ledgerEntry, isNull); // the server owns the ledger
    });

    test('maps a 422 contract error to a WalletException', () async {
      final client = FakeApiClient(
        throwOnPost: const ApiStatusException(422, 'Amount below minimum.'),
      );

      expect(
        () => RestWalletRepository(client).transfer(
          TransferCommand(
            recipient: fatima,
            amount: Money.major(1, Currency.tzs),
            fee: Money.zero(Currency.tzs),
            idempotencyKey: 'send_test_2',
          ),
        ),
        throwsA(isA<WalletException>()),
      );
    });

    test(
      'a declined (failed) transaction throws rather than debiting',
      () async {
        final client = FakeApiClient(
          postResponse: {
            'id': 'txn-10',
            'type': 'send_money',
            'status': 'failed',
            'direction': 'debit',
            'amount_minor': 25000000,
            'fee_minor': 0,
            'currency': 'TZS',
            'counterparty': 'Fatima Salim',
            'method_kind': 'mobile_money',
            'method_ref': '255754000891',
            'operator': 'mpesa',
            'provider': '',
            'provider_ref': '',
            'note': '',
            'ledger_entry': null,
            'created_at': '2026-07-10T21:05:00Z',
          },
        );

        expect(
          () => RestWalletRepository(client).transfer(
            TransferCommand(
              recipient: fatima,
              amount: Money.major(250000, Currency.tzs),
              fee: Money.zero(Currency.tzs),
              idempotencyKey: 'send_test_3',
            ),
          ),
          throwsA(isA<WalletException>()),
        );
      },
    );
  });

  group('RestWalletRepository.topUp', () {
    test(
      'POSTs /payments/topups with STK fields and idempotency key',
      () async {
        final client = FakeApiClient(
          postResponse: {
            'id': 'txn-top-1',
            'type': 'top_up',
            'status': 'processing',
            'direction': 'credit',
            'amount_minor': 5000000,
            'fee_minor': 0,
            'currency': 'TZS',
            'counterparty': 'Top-up',
            'method_kind': 'mobile_money',
            'method_ref': '255754000210',
            'operator': 'mpesa',
            'provider': 'MPESA',
            'provider_ref': 'ws_CO_top1',
            'note': 'Wallet top-up',
            'ledger_entry': null,
            'created_at': '2026-07-14T21:05:00Z',
          },
        );

        final receipt = await RestWalletRepository(client).topUp(
          TopUpCommand(
            amount: Money.major(50000, Currency.tzs),
            msisdn: '+255 754 ••• 210',
            operator: MobileMoneyOperator.mpesa,
            idempotencyKey: 'topup_test_1',
            note: 'Wallet top-up',
          ),
        );

        expect(client.lastPostPath, 'payments/topups');
        expect(client.lastIdempotencyKey, 'topup_test_1');
        expect(client.lastBody!['amount_minor'], 5000000);
        expect(client.lastBody!['operator'], 'mpesa');
        expect(client.lastBody!['msisdn'], contains('255754'));
        expect(receipt.transaction.status, TransactionStatus.processing);
        expect(receipt.newBalance, isNull);
      },
    );

    test(
      'completeDemoTopUp posts demo-complete and maps succeeded txn',
      () async {
        final client = FakeApiClient(
          postResponse: {
            'id': 'txn-top-1',
            'type': 'top_up',
            'status': 'succeeded',
            'direction': 'credit',
            'amount_minor': 5000000,
            'fee_minor': 0,
            'currency': 'TZS',
            'counterparty': 'Top-up',
            'method_kind': 'mobile_money',
            'method_ref': '255754000210',
            'operator': 'mpesa',
            'provider': 'MPESA',
            'provider_ref': 'ws_CO_top1',
            'note': 'Wallet top-up',
            'ledger_entry': 'led-1',
            'created_at': '2026-07-14T21:05:00Z',
          },
        );

        final receipt = await RestWalletRepository(
          client,
        ).completeDemoTopUp('txn-top-1');
        expect(client.lastPostPath, 'payments/topups/txn-top-1/demo-complete');
        expect(receipt.transaction.status, TransactionStatus.succeeded);
      },
    );

    test('pollTopUpStatus posts poll-status and maps succeeded txn', () async {
      final client = FakeApiClient(
        postResponse: {
          'id': 'txn-top-1',
          'type': 'top_up',
          'status': 'succeeded',
          'direction': 'credit',
          'amount_minor': 5000000,
          'fee_minor': 0,
          'currency': 'TZS',
          'counterparty': 'Top-up',
          'method_kind': 'mobile_money',
          'method_ref': '255754000210',
          'operator': 'mpesa',
          'provider': 'MPESA',
          'provider_ref': 'ws_CO_top1',
          'note': 'Wallet top-up',
          'ledger_entry': 'led-1',
          'created_at': '2026-07-14T21:05:00Z',
        },
      );

      final receipt = await RestWalletRepository(
        client,
      ).pollTopUpStatus('txn-top-1');
      expect(client.lastPostPath, 'payments/topups/txn-top-1/poll-status');
      expect(receipt.transaction.status, TransactionStatus.succeeded);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:taifa/data/wallet/payment_api_paths.dart';

void main() {
  test('PaymentApiPaths stay aligned with backend OpenAPI payment surface', () {
    // Fragments under /api/v1/ — must match apps/backend/openapi.yaml paths.
    expect(PaymentApiPaths.wallet, 'payments/wallet');
    expect(PaymentApiPaths.topups, 'payments/topups');
    expect(PaymentApiPaths.transfers, 'payments/transfers');
    expect(PaymentApiPaths.withdrawals, 'payments/withdrawals');
    expect(PaymentApiPaths.refunds, 'payments/refunds');
    expect(
      PaymentApiPaths.demoComplete('abc'),
      'payments/topups/abc/demo-complete',
    );
    expect(
      PaymentApiPaths.pollStatus('abc'),
      'payments/topups/abc/poll-status',
    );
    expect(PaymentApiPaths.transaction('abc'), 'payments/transactions/abc');
    expect(PaymentApiPaths.reverse('abc'), 'payments/transactions/abc/reverse');
  });
}

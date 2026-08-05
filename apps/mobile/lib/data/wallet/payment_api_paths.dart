/// Canonical REST path fragments used by [RestWalletRepository].
/// Kept in one place so contract tests can lock them against the backend
/// OpenAPI surface without regenerating a full Dart client yet.
class PaymentApiPaths {
  const PaymentApiPaths._();

  static const wallet = 'payments/wallet';
  static const topups = 'payments/topups';
  static const transfers = 'payments/transfers';
  static const withdrawals = 'payments/withdrawals';
  static const refunds = 'payments/refunds';

  static String demoComplete(String transactionId) =>
      'payments/topups/$transactionId/demo-complete';

  static String pollStatus(String transactionId) =>
      'payments/topups/$transactionId/poll-status';

  static String transaction(String transactionId) =>
      'payments/transactions/$transactionId';

  static String withdrawalApprove(String transactionId) =>
      'payments/withdrawals/$transactionId/approve';

  static String withdrawalReject(String transactionId) =>
      'payments/withdrawals/$transactionId/reject';

  static String withdrawalProcess(String transactionId) =>
      'payments/withdrawals/$transactionId/process';

  static String reverse(String transactionId) =>
      'payments/transactions/$transactionId/reverse';
}

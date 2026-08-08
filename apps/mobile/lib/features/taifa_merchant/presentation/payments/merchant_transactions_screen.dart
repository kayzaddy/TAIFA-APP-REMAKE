import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/merchant_api_client.dart';

class MerchantTransactionsScreen extends HookConsumerWidget {
  const MerchantTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.watch(merchantApiClientProvider);
    final txs = useFuture(useMemoized(api.listTransactions));

    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: txs.connectionState == ConnectionState.waiting
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: (txs.data ?? []).length,
              itemBuilder: (_, i) {
                final tx = txs.data![i] as Map<String, dynamic>;
                return ListTile(
                  title: Text('${tx['amount']} ${tx['currency']}'),
                  subtitle: Text('${tx['channel']} · ${tx['status']}'),
                  trailing: Text(tx['merchant_reference']?.toString() ?? ''),
                );
              },
            ),
    );
  }
}

class MerchantPaymentAnalyticsScreen extends HookConsumerWidget {
  const MerchantPaymentAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.watch(merchantApiClientProvider);
    final stats = useFuture(useMemoized(api.paymentAnalyticsToday));

    return Scaffold(
      appBar: AppBar(title: const Text('Today')),
      body: stats.connectionState == ConnectionState.waiting
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Revenue: ${stats.data?['revenue']} ${stats.data?['currency']}'),
                  Text('Transactions: ${stats.data?['transaction_count']}'),
                  Text('Successful: ${stats.data?['successful_payments']}'),
                  Text('Failed: ${stats.data?['failed_payments']}'),
                  Text('Refunds: ${stats.data?['refund_count']}'),
                ],
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/merchant_api_client.dart';

class MerchantQrPaymentsScreen extends HookConsumerWidget {
  const MerchantQrPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.watch(merchantApiClientProvider);
    final amount = useTextEditingController(text: '500');
    final payload = useState<String?>(null);

    return Scaffold(
      appBar: AppBar(title: const Text('QR payments')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: amount,
            decoration: const InputDecoration(labelText: 'Amount', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () async {
              final qr = await api.createQr({
                'qr_type': 'dynamic',
                'amount': amount.text,
                'expires_in_seconds': 3600,
              });
              payload.value = qr['payload']?.toString();
              await api.completeQr(qr['id'].toString());
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('QR payment completed (dev)')));
              }
            },
            child: const Text('Generate dynamic QR & complete (dev)'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () async {
              final qr = await api.createQr({'qr_type': 'static'});
              payload.value = qr['payload']?.toString();
            },
            child: const Text('Generate static QR'),
          ),
          if (payload.value != null) ...[
            const SizedBox(height: 24),
            SelectableText(payload.value!),
          ],
        ],
      ),
    );
  }
}

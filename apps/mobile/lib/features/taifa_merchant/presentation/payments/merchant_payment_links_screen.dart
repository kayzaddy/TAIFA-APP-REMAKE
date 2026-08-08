import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/merchant_api_client.dart';

class MerchantPaymentLinksScreen extends HookConsumerWidget {
  const MerchantPaymentLinksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.watch(merchantApiClientProvider);
    final amount = useTextEditingController(text: '2000');
    final linkUrl = useState<String?>(null);

    return Scaffold(
      appBar: AppBar(title: const Text('Payment links')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: amount,
              decoration: const InputDecoration(labelText: 'Amount', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () async {
                final link = await api.createPaymentLink({
                  'amount': amount.text,
                  'description': 'Customer invoice',
                  'share': {'whatsapp': true, 'sms': true, 'email': true},
                });
                linkUrl.value = link['url']?.toString();
              },
              child: const Text('Create link'),
            ),
            if (linkUrl.value != null) ...[
              const SizedBox(height: 16),
              SelectableText(linkUrl.value!),
            ],
          ],
        ),
      ),
    );
  }
}

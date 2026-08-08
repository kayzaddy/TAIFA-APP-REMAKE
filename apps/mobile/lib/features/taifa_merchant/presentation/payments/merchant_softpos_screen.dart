import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/merchant_api_client.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MerchantSoftposScreen extends HookConsumerWidget {
  const MerchantSoftposScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.watch(merchantApiClientProvider);
    final amount = useTextEditingController(text: '1000');
    final devices = useFuture(useMemoized(api.listDevices));
    final status = useState<String?>(null);
    final busy = useState(false);

    return Scaffold(
      appBar: AppBar(title: const Text('Tap to Pay')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: amount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount (TZS)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            if (devices.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if ((devices.data ?? []).isEmpty)
              const Text('Register and activate a device first.')
            else
              FilledButton.icon(
                onPressed: busy.value
                    ? null
                    : () async {
                        busy.value = true;
                        status.value = null;
                        try {
                          final deviceList = devices.data!;
                          final device = deviceList.first as Map<String, dynamic>;
                          final deviceId = device['id'].toString();
                          await api.registerTerminal(deviceId);
                          final session = await api.startSoftposSession({
                            'device_id': deviceId,
                            'amount': amount.text,
                            'merchant_reference': 'POS-${DateTime.now().millisecondsSinceEpoch}',
                          });
                          final result = await api.confirmSoftpos(
                            session['id'].toString(),
                            {'nfc_token': 'emulated-tap', 'wallet_hint': 'wallet'},
                          );
                          final tx = result['transaction'] as Map<String, dynamic>;
                          status.value = 'Paid ${tx['amount']} ${tx['status']}';
                        } catch (e) {
                          status.value = 'Failed: $e';
                        } finally {
                          busy.value = false;
                        }
                      },
                icon: const Icon(LucideIcons.wifi),
                label: const Text('Tap to Pay (emulated NFC)'),
              ),
            if (status.value != null) ...[
              const SizedBox(height: 16),
              Text(status.value!, style: Theme.of(context).textTheme.titleMedium),
            ],
            const Spacer(),
            const Text(
              'Production: device attestation + certified EMV kernel via TNPI MAP. '
              'No card data stored in merchant app.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

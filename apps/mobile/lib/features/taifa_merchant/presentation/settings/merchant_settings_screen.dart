import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../application/merchant_workspace_providers.dart';
import '../../core/merchant_api_client.dart';

class MerchantSettingsScreen extends ConsumerWidget {
  const MerchantSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(merchantSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Business settings')),
      body: settings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Unable to load settings: $e')),
        data: (snap) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              title: const Text('Language'),
              subtitle: Text(snap.language),
              trailing: DropdownButton<String>(
                value: snap.language,
                items: const [
                  DropdownMenuItem(value: 'sw', child: Text('Swahili')),
                  DropdownMenuItem(value: 'en', child: Text('English')),
                ],
                onChanged: (v) async {
                  if (v == null) return;
                  await ref.read(merchantApiClientProvider).updateSettings({'language': v});
                  ref.invalidate(merchantSettingsProvider);
                },
              ),
            ),
            ListTile(title: const Text('Currency'), subtitle: Text(snap.currency)),
            ListTile(title: const Text('Timezone'), subtitle: Text(snap.timezone)),
            const Divider(),
            const ListTile(
              title: Text('Payment preferences'),
              subtitle: Text('Configured for Sprint 3 — no processing in Sprint 2'),
            ),
            SwitchListTile(
              title: const Text('Mark ready for payment acceptance prep'),
              value: snap.paymentPreferences['sprint3_ready'] == true,
              onChanged: (on) async {
                await ref.read(merchantApiClientProvider).updateSettings({
                  'payment_preferences': {...snap.paymentPreferences, 'sprint3_ready': on},
                });
                ref.invalidate(merchantSettingsProvider);
              },
            ),
            const Divider(),
            const ListTile(title: Text('Receipt branding'), subtitle: Text('Footer & logo via settings API')),
            Text(snap.receiptBranding['footer_text']?.toString() ?? ''),
          ],
        ),
      ),
    );
  }
}

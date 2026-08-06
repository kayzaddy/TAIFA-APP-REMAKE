import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/merchant_api_client.dart';

class MerchantDevicesScreen extends HookConsumerWidget {
  const MerchantDevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.watch(merchantApiClientProvider);
    final devices = useFuture(useMemoized(api.listDevices));
    final deviceName = useTextEditingController(text: 'Counter device');

    return Scaffold(
      appBar: AppBar(title: const Text('Devices')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: () async {
                final d = await api.registerDevice({'name': deviceName.text, 'device_type': 'mobile'});
                await api.activateDevice(d['id'] as String);
              },
              child: const Text('Register & activate device'),
            ),
          ),
          Expanded(
            child: devices.connectionState == ConnectionState.waiting
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: (devices.data ?? []).length,
                    itemBuilder: (_, i) {
                      final d = devices.data![i] as Map<String, dynamic>;
                      return ListTile(
                        title: Text(d['name']?.toString() ?? ''),
                        subtitle: Text('${d['device_type']} · ${d['status']} · ${d['health']}'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

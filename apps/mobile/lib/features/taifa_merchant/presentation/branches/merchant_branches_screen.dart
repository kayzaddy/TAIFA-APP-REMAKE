import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/merchant_api_client.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MerchantBranchesScreen extends HookConsumerWidget {
  const MerchantBranchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.watch(merchantApiClientProvider);
    final branches = useFuture(useMemoized(api.listBranches));
    final name = useTextEditingController();
    final code = useTextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Branches')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await api.createBranch({'name': name.text, 'code': code.text, 'city': 'Dar es Salaam'});
          if (context.mounted) Navigator.pop(context);
        },
        child: const Icon(LucideIcons.plus),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(child: TextField(controller: name, decoration: const InputDecoration(labelText: 'Name'))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: code, decoration: const InputDecoration(labelText: 'Code'))),
              ],
            ),
          ),
          Expanded(
            child: branches.connectionState == ConnectionState.waiting
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: (branches.data ?? []).length,
                    itemBuilder: (_, i) {
                      final b = branches.data![i] as Map<String, dynamic>;
                      return ListTile(title: Text(b['name']?.toString() ?? ''), subtitle: Text(b['city']?.toString() ?? ''));
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

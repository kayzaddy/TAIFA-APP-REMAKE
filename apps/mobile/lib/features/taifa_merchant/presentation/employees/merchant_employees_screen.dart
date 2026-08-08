import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/merchant_api_client.dart';

class MerchantEmployeesScreen extends HookConsumerWidget {
  const MerchantEmployeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.watch(merchantApiClientProvider);
    final employees = useFuture(useMemoized(api.listEmployees));
    final email = useTextEditingController(text: '');
    final name = useTextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Employees')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Full name')),
                TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () async {
                    await api.inviteEmployee({'email': email.text, 'full_name': name.text, 'role': 'cashier'});
                  },
                  child: const Text('Invite cashier'),
                ),
              ],
            ),
          ),
          Expanded(
            child: employees.connectionState == ConnectionState.waiting
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: (employees.data ?? []).length,
                    itemBuilder: (_, i) {
                      final e = employees.data![i] as Map<String, dynamic>;
                      return ListTile(
                        title: Text(e['full_name']?.toString() ?? e['email']?.toString() ?? ''),
                        subtitle: Text('${e['role']} · ${e['status']}'),
                        trailing: e['status'] == 'active'
                            ? IconButton(
                                icon: const Icon(Icons.pause_circle_outline),
                                onPressed: () async {
                                  await api.suspendEmployee(e['id'].toString());
                                },
                              )
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

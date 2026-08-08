import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/merchant_api_client.dart';

class MerchantProfileScreen extends HookConsumerWidget {
  const MerchantProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.watch(merchantApiClientProvider);
    final load = useFuture(useMemoized(api.getBusinessProfile));
    final description = useTextEditingController();
    final category = useTextEditingController();
  final saving = useState(false);

    useEffect(() {
      final data = load.data;
      if (data != null) {
        final profile = data['profile'] as Map<String, dynamic>? ?? {};
        description.text = profile['description']?.toString() ?? '';
        category.text = profile['business_category']?.toString() ?? '';
      }
      return null;
    }, [load.data]);

    return Scaffold(
      appBar: AppBar(title: const Text('Business profile')),
      body: load.connectionState == ConnectionState.waiting
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: description,
                  decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: category,
                  decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: saving.value
                      ? null
                      : () async {
                          saving.value = true;
                          try {
                            await api.updateBusinessProfile({
                              'description': description.text,
                              'business_category': category.text,
                            });
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Profile saved')),
                              );
                            }
                          } finally {
                            saving.value = false;
                          }
                        },
                  child: saving.value ? const CircularProgressIndicator() : const Text('Save profile'),
                ),
              ],
            ),
    );
  }
}

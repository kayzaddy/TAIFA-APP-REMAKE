import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/merchant_auth_controller.dart';
import '../../core/auth_token_storage.dart';
import '../../core/merchant_api_client.dart';

class MerchantSignupScreen extends HookConsumerWidget {
  const MerchantSignupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = useTextEditingController();
    final email = useTextEditingController();
    final password = useTextEditingController();
    final auth = ref.watch(merchantAuthControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Full name')),
            const SizedBox(height: 12),
            TextField(controller: email, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            TextField(controller: password, decoration: const InputDecoration(labelText: 'Password (min 8)'), obscureText: true),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: auth.isLoading
                  ? null
                  : () async {
                      final ok = await ref.read(merchantAuthControllerProvider.notifier).signup(
                            email: email.text.trim(),
                            password: password.text,
                            fullName: name.text.trim(),
                          );
                      if (ok && context.mounted) context.go('/taifa-merchant/register-business');
                    },
              child: const Text('Sign up'),
            ),
          ],
        ),
      ),
    );
  }
}

class MerchantRegisterBusinessScreen extends HookConsumerWidget {
  const MerchantRegisterBusinessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final legalName = useTextEditingController();
    final category = useTextEditingController();
    final city = useTextEditingController();
    final loading = useState(false);
    final api = ref.watch(merchantApiClientProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Register business')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(controller: legalName, decoration: const InputDecoration(labelText: 'Legal business name')),
          const SizedBox(height: 12),
          TextField(controller: category, decoration: const InputDecoration(labelText: 'Category')),
          const SizedBox(height: 12),
          TextField(controller: city, decoration: const InputDecoration(labelText: 'City')),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: loading.value
                ? null
                : () async {
                    loading.value = true;
                    try {
                      final res = await api.registerMerchant({
                        'legal_name': legalName.text.trim(),
                        'business_category': category.text.trim(),
                        'city': city.text.trim(),
                      });
                      final token = res['access_token'] as String?;
                      if (token != null) {
                        await ref.read(merchantAuthStorageProvider).writeAccessToken(token);
                      }
                      if (context.mounted) context.go('/taifa-merchant/dashboard');
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                      }
                    } finally {
                      loading.value = false;
                    }
                  },
            child: loading.value ? const CircularProgressIndicator() : const Text('Submit KYB'),
          ),
        ],
      ),
    );
  }
}

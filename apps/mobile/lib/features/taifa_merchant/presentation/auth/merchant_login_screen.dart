import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/merchant_auth_controller.dart';

class MerchantLoginScreen extends HookConsumerWidget {
  const MerchantLoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = useTextEditingController();
    final password = useTextEditingController();
    final auth = ref.watch(merchantAuthControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Taifa Merchant')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Sign in', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            TextField(
              controller: email,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: password,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            if (auth.error != null) ...[
              const SizedBox(height: 12),
              Text(auth.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: auth.isLoading
                  ? null
                  : () async {
                      final ok = await ref.read(merchantAuthControllerProvider.notifier).login(
                            email: email.text.trim(),
                            password: password.text,
                          );
                      if (ok && context.mounted) context.go('/taifa-merchant/dashboard');
                    },
              child: auth.isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Login'),
            ),
            TextButton(
              onPressed: () => context.push('/taifa-merchant/signup'),
              child: const Text('Create account'),
            ),
          ],
        ),
      ),
    );
  }
}

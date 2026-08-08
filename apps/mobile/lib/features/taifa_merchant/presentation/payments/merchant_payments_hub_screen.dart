import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MerchantPaymentsHubScreen extends StatelessWidget {
  const MerchantPaymentsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accept payments')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.contactless),
            title: const Text('Tap to Pay (SoftPOS)'),
            subtitle: const Text('NFC — TNPI MAP'),
            onTap: () => context.push('/taifa-merchant/payments/softpos'),
          ),
          ListTile(
            leading: const Icon(Icons.qr_code),
            title: const Text('QR payments'),
            onTap: () => context.push('/taifa-merchant/payments/qr'),
          ),
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text('Payment links'),
            onTap: () => context.push('/taifa-merchant/payments/links'),
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('Transactions'),
            onTap: () => context.push('/taifa-merchant/payments/transactions'),
          ),
          ListTile(
            leading: const Icon(Icons.insights),
            title: const Text('Today\'s analytics'),
            onTap: () => context.push('/taifa-merchant/payments/analytics'),
          ),
        ],
      ),
    );
  }
}

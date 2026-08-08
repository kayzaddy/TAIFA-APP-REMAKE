import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MerchantPaymentsHubScreen extends StatelessWidget {
  const MerchantPaymentsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accept payments')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(LucideIcons.wifi),
            title: const Text('Tap to Pay (SoftPOS)'),
            subtitle: const Text('NFC — TNPI MAP'),
            onTap: () => context.push('/taifa-merchant/payments/softpos'),
          ),
          ListTile(
            leading: const Icon(LucideIcons.qrCode),
            title: const Text('QR payments'),
            onTap: () => context.push('/taifa-merchant/payments/qr'),
          ),
          ListTile(
            leading: const Icon(LucideIcons.link),
            title: const Text('Payment links'),
            onTap: () => context.push('/taifa-merchant/payments/links'),
          ),
          ListTile(
            leading: const Icon(LucideIcons.receipt),
            title: const Text('Transactions'),
            onTap: () => context.push('/taifa-merchant/payments/transactions'),
          ),
          ListTile(
            leading: const Icon(LucideIcons.chartLine),
            title: const Text('Today\'s analytics'),
            onTap: () => context.push('/taifa-merchant/payments/analytics'),
          ),
        ],
      ),
    );
  }
}

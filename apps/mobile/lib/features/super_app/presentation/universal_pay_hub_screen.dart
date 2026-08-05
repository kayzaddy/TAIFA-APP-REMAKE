import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';

/// Universal Pay hub — deep-links into Wallet + MAP. No new payment engine.
class UniversalPayHubScreen extends StatelessWidget {
  const UniversalPayHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pay'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(TaifaSpacing.screenH),
        children: [
          Text(
            'Universal Pay',
            style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: TaifaSpacing.sm),
          Text(
            'One wallet. One ledger. Many ways to pay — all via Taifa Payments.',
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: TaifaSpacing.xl),
          _tile(context, Icons.qr_code_scanner_rounded, 'Scan QR', 'Merchant · invoice · ride', '/scan', TaifaColors.ocean500),
          _tile(context, Icons.contactless, 'Tap & Pay', 'NFC · SoftPOS · biometric', '/tap', TaifaColors.emerald600),
          _tile(context, Icons.link_rounded, 'Pay with code / link', 'MAP customer pay', '/map/pay', TaifaColors.emerald600),
          _tile(context, Icons.north_east_rounded, 'Send money', 'P2P transfer', '/wallet/send', TaifaColors.gold500),
          _tile(context, Icons.add_rounded, 'Top up', 'Mobile money STK', '/wallet/topup', TaifaColors.ocean400),
          _tile(context, Icons.account_balance_wallet_rounded, 'Wallet & history', 'Balances · receipts', '/wallet', TaifaColors.emerald700),
          _tile(context, Icons.storefront_outlined, 'Merchant accept', 'Issue QR · invoices', '/map/merchant', TaifaColors.ocean500),
          _tile(context, Icons.account_balance_rounded, 'Government payments', 'Huduma requests', '/gov', TaifaColors.violetSoft),
          const SizedBox(height: TaifaSpacing.lg),
          Text(
            'AI never authorizes payments. You always approve.',
            style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    String route,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TaifaSpacing.sm),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        tileColor: color.withValues(alpha: 0.08),
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(route),
      ),
    );
  }
}

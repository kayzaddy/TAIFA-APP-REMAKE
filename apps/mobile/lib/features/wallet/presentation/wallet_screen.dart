import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/taifa_dimens.dart';
import '../../../app/theme/taifa_theme.dart';
import '../../../app/theme/taifa_typography.dart';
import '../../../shared/widgets/quick_action_button.dart';
import '../application/wallet_providers.dart';
import '../domain/currency.dart';
import 'widgets/currency_switcher.dart';
import 'widgets/platinum_card.dart';
import 'widgets/transaction_tile.dart';

/// Screen 04 — Digital Wallet ("Pesa Yangu").
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  static const _switcherCurrencies = [
    Currency.tzs,
    Currency.usd,
    Currency.eur,
    Currency.kes,
    Currency.btc,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.taifa;
    final asyncState = ref.watch(walletControllerProvider);
    final engine = ref.watch(currencyEngineProvider);

    return SafeArea(
      bottom: false,
      child: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Could not load wallet.\n$e',
            textAlign: TextAlign.center,
          ),
        ),
        data: (walletState) {
          final snap = walletState.snapshot!;
          final display = walletState.displayCurrency;
          final shownBalance = engine.convert(snap.balance, display);

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              TaifaSpacing.screenH,
              TaifaSpacing.md,
              TaifaSpacing.screenH,
              120,
            ),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Wallet',
                        style: TextStyle(
                          fontSize: 13,
                          color: palette.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Pesa Yangu',
                        style: TaifaTypography.sectionTitle(
                          palette.textPrimary,
                        ).copyWith(fontSize: 22),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.tune_rounded,
                      size: 18,
                      color: palette.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TaifaSpacing.md),
              PlatinumCard(
                cardholderName: snap.cardholderName,
                tier: snap.cardTier,
                maskedPan: snap.maskedPan,
                balanceLabel: shownBalance.format(),
              ),
              const SizedBox(height: TaifaSpacing.md),
              CurrencySwitcher(
                currencies: _switcherCurrencies,
                selected: display,
                onSelected: (c) => ref
                    .read(walletControllerProvider.notifier)
                    .setDisplayCurrency(c),
              ),
              const SizedBox(height: TaifaSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.north_east_rounded,
                      label: 'Send',
                      onTap: () => context.go('/wallet/send'),
                    ),
                  ),
                  const SizedBox(width: TaifaSpacing.sm),
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.add_rounded,
                      label: 'Top Up',
                      onTap: () => context.go('/wallet/topup'),
                    ),
                  ),
                  const SizedBox(width: TaifaSpacing.sm),
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.qr_code_scanner_rounded,
                      label: 'Pay QR',
                      onTap: () => context.go('/wallet/qr'),
                    ),
                  ),
                  const SizedBox(width: TaifaSpacing.sm),
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.receipt_long_rounded,
                      label: 'Split Bill',
                      onTap: () => context.go('/wallet/bills'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TaifaSpacing.lg),
              _MoreLinksRow(),
              const SizedBox(height: TaifaSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'All',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: palette.accent,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 12,
                        color: palette.accent,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: TaifaSpacing.xs),
              for (var i = 0; i < snap.transactions.length; i++) ...[
                if (i > 0) Divider(height: 1, color: palette.border),
                TransactionTile(transaction: snap.transactions[i]),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Entry points into the social-payments surface that don't fit the four
/// primary quick actions: requests, standing orders, contacts, notifications,
/// history, analytics, spending cap, and profile/merchant settings.
class _MoreLinksRow extends StatelessWidget {
  const _MoreLinksRow();

  static const _links = [
    (Icons.link_rounded, 'Payment\nLinks', '/wallet/links'),
    (Icons.request_page_rounded, 'Requests', '/wallet/requests'),
    (Icons.autorenew_rounded, 'Standing\nOrders', '/wallet/recurring'),
    (Icons.contacts_rounded, 'Contacts', '/wallet/contacts'),
    (Icons.notifications_none_rounded, 'Alerts', '/wallet/notifications'),
    (Icons.history_rounded, 'History', '/wallet/history'),
    (Icons.insights_rounded, 'Analytics', '/wallet/analytics'),
    (Icons.shield_outlined, 'Spending\nCap', '/wallet/spending-cap'),
    (Icons.storefront_rounded, 'Profile &\nMerchant', '/wallet/profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return SizedBox(
      height: 74,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _links.length,
        separatorBuilder: (_, _) => const SizedBox(width: TaifaSpacing.sm),
        itemBuilder: (context, i) {
          final (icon, label, route) = _links[i];
          return InkWell(
            onTap: () => context.go(route),
            borderRadius: BorderRadius.circular(TaifaRadii.md),
            child: Container(
              width: 64,
              padding: const EdgeInsets.symmetric(vertical: TaifaSpacing.xs),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(TaifaRadii.md),
                border: Border.all(color: palette.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18, color: palette.accent),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, height: 1.1, color: palette.textSecondary),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

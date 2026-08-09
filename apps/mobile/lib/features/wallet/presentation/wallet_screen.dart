import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/taifa_dimens.dart';
import '../../../app/theme/taifa_icons.dart';
import '../../../app/theme/taifa_theme.dart';
import '../../../app/theme/taifa_typography.dart';
import '../../../shared/widgets/quick_action_button.dart';
import '../../../shared/widgets/taifa_icon_tile.dart';
import '../../../shared/widgets/taifa_skeleton.dart';
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
        loading: () => const _WalletSkeleton(),
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
                      TaifaIcons.filter,
                      size: TaifaIconSize.md,
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
                      icon: TaifaIcons.sendMoney,
                      label: 'Send',
                      hue: TaifaIconHue.gold,
                      onTap: () => context.go('/wallet/send'),
                    ),
                  ),
                  const SizedBox(width: TaifaSpacing.sm),
                  Expanded(
                    child: QuickActionButton(
                      icon: TaifaIcons.topUp,
                      label: 'Top Up',
                      hue: TaifaIconHue.emerald,
                      onTap: () => context.go('/wallet/topup'),
                    ),
                  ),
                  const SizedBox(width: TaifaSpacing.sm),
                  Expanded(
                    child: QuickActionButton(
                      icon: TaifaIcons.scanQr,
                      label: 'My QR',
                      hue: TaifaIconHue.ocean,
                      onTap: () => context.go('/wallet/qr'),
                    ),
                  ),
                  const SizedBox(width: TaifaSpacing.sm),
                  Expanded(
                    child: QuickActionButton(
                      icon: TaifaIcons.splitBill,
                      label: 'Split Bill',
                      hue: TaifaIconHue.gold,
                      onTap: () => context.go('/wallet/bills'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TaifaSpacing.xl),
              const _MoneyToolsGrid(),
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
                  // Was a decorative label; now it actually opens the
                  // searchable history screen.
                  InkWell(
                    onTap: () => context.go('/wallet/history'),
                    borderRadius: BorderRadius.circular(TaifaRadii.sm),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: TaifaSpacing.xs,
                        vertical: TaifaSpacing.xxs,
                      ),
                      child: Row(
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
                            TaifaIcons.chevronRight,
                            size: 12,
                            color: palette.accent,
                          ),
                        ],
                      ),
                    ),
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

/// Loading state shaped like the real wallet: card, currency switcher, action
/// row, then transactions. Reserving the layout means nothing jumps when the
/// balance lands.
class _WalletSkeleton extends StatelessWidget {
  const _WalletSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        TaifaSpacing.screenH,
        TaifaSpacing.md,
        TaifaSpacing.screenH,
        120,
      ),
      children: const [
        TaifaSkeleton(width: double.infinity, height: 26, radius: TaifaRadii.sm),
        SizedBox(height: TaifaSpacing.md),
        TaifaSkeleton(width: double.infinity, height: 170, radius: TaifaRadii.xxl),
        SizedBox(height: TaifaSpacing.md),
        TaifaSkeleton(width: double.infinity, height: 34, radius: TaifaRadii.md),
        SizedBox(height: TaifaSpacing.lg),
        TaifaSkeleton(width: double.infinity, height: 72, radius: TaifaRadii.lg),
        SizedBox(height: TaifaSpacing.xl),
        TaifaSkeletonCard(),
        SizedBox(height: TaifaSpacing.sm),
        TaifaSkeletonCard(),
      ],
    );
  }
}

/// Everything in the money surface that isn't one of the four primary quick
/// actions, as a proper grid.
///
/// This replaced a horizontally-scrolling strip of 64px tiles with 8px
/// labels: the tap targets were under the 44pt minimum, half the items were
/// hidden off-screen with no affordance, and the labels were below a
/// readable size. A wrapped grid shows the whole vocabulary at once.
class _MoneyToolsGrid extends StatelessWidget {
  const _MoneyToolsGrid();

  static const _tools = <(IconData, String, String, TaifaIconHue)>[
    (TaifaIcons.paymentLink, 'Payment\nLinks', '/wallet/links', TaifaIconHue.gold),
    (TaifaIcons.moneyRequest, 'Requests', '/wallet/requests', TaifaIconHue.emerald),
    (TaifaIcons.splitBill, 'Split\nBills', '/wallet/bills', TaifaIconHue.gold),
    (TaifaIcons.standingOrder, 'Standing\nOrders', '/wallet/recurring', TaifaIconHue.ocean),
    (TaifaIcons.contacts, 'Contacts', '/wallet/contacts', TaifaIconHue.violet),
    (TaifaIcons.notifications, 'Alerts', '/wallet/notifications', TaifaIconHue.gold),
    (TaifaIcons.history, 'History', '/wallet/history', TaifaIconHue.ocean),
    (TaifaIcons.analytics, 'Analytics', '/wallet/analytics', TaifaIconHue.emerald),
    (TaifaIcons.spendingCap, 'Spending\nCap', '/wallet/spending-cap', TaifaIconHue.violet),
    (TaifaIcons.merchant, 'Profile &\nMerchant', '/wallet/profile', TaifaIconHue.gold),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MONEY TOOLS',
          style: TaifaTypography.eyebrow(
            palette.textMuted,
          ).copyWith(fontSize: 10, letterSpacing: 2),
        ),
        const SizedBox(height: TaifaSpacing.sm),
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          // Max-extent + a fixed row height, rather than a fixed column count
          // with an aspect ratio: a phone gets 4 columns, a tablet or the web
          // build simply gets more of the same-sized tiles instead of the
          // enormous stretched cells an aspect ratio produces when wide.
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 104,
            mainAxisExtent: 86,
            mainAxisSpacing: TaifaSpacing.xs,
            crossAxisSpacing: TaifaSpacing.xs,
          ),
          children: [
            for (final (icon, label, route, hue) in _tools)
              TaifaFeatureTile(
                icon: icon,
                label: label.replaceAll('\n', ' '),
                hue: hue,
                onTap: () => context.go(route),
              ),
          ],
        ),
      ],
    );
  }
}

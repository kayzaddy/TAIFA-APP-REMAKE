import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/taifa_colors.dart';
import '../../../../app/theme/taifa_dimens.dart';
import '../../../wallet/application/wallet_providers.dart';
import '../../application/brokerage_providers.dart';
import '../../domain/brokerage_models.dart';
import '../widgets/experience_kit.dart';
import '../widgets/winga_ui.dart';

/// Customer journey app — discover → compare → deal → pay → review.
class WingaCustomerApp extends ConsumerStatefulWidget {
  const WingaCustomerApp({super.key});

  @override
  ConsumerState<WingaCustomerApp> createState() => _WingaCustomerAppState();
}

class _WingaCustomerAppState extends ConsumerState<WingaCustomerApp> {
  int _tab = 0;
  final _search = TextEditingController();
  WingaOffering? _comparing;

  static const _journey = [
    'Discover',
    'Compare',
    'Quote',
    'Pay',
    'Track',
    'Review',
  ];

  int get _journeyIndex {
    final deals = ref.watch(brokerageControllerProvider).deals;
    if (deals.any((d) => d.isPaid)) return 4;
    if (deals.isNotEmpty) return 3;
    if (_comparing != null) return 1;
    return 0;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(brokerageControllerProvider.notifier)
          .bootstrap(dealsRole: 'customer');
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(brokerageControllerProvider);
    final ctrl = ref.read(brokerageControllerProvider.notifier);
    final useRemote = ref.watch(apiConfigProvider).useRemoteBackend;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find & book'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Help',
            onPressed: () => _showHelp(context),
            icon: const Icon(Icons.help_outline),
          ),
          IconButton(
            onPressed: () => context.push('/wallet'),
            icon: const Icon(Icons.account_balance_wallet_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!useRemote) const WingaOfflineBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TaifaSpacing.screenH,
              TaifaSpacing.md,
              TaifaSpacing.screenH,
              0,
            ),
            child: WingaJourneyStepper(
              steps: _journey,
              currentIndex: _journeyIndex,
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: [
                _Discover(
                  state: state,
                  search: _search,
                  comparing: _comparing,
                  onSearch: ctrl.search,
                  onDomain: ctrl.filterDomain,
                  onFavorite: ctrl.toggleFavorite,
                  onSelect: (o) => setState(() {
                    _comparing = o;
                    _tab = 1;
                  }),
                ),
                _Compare(
                  offering: _comparing,
                  wingas: state.wingas,
                  onRequest: (o) async {
                    final deal = await ctrl.requestDeal(
                      offering: o,
                      customerPrincipal: 'customer:mobile',
                    );
                    if (!context.mounted || deal == null) return;
                    setState(() => _tab = 2);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Quote path opened · ${deal.reference}'),
                      ),
                    );
                  },
                  onBack: () => setState(() => _tab = 0),
                ),
                _Deals(
                  state: state,
                  onPay: (id) async {
                    final paid = await ctrl.payDeal(id);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          paid == null
                              ? (state.error ?? 'Payment failed')
                              : 'Paid securely · receipt ${paid.paymentRef}',
                        ),
                      ),
                    );
                  },
                ),
                _Assist(
                  state: state,
                  onRefresh: () => ctrl.runAssist('recommendations'),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab.clamp(0, 3),
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.compare_arrows),
            label: 'Compare',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Deals',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            label: 'Assist',
          ),
        ],
      ),
    );
  }

  void _showHelp(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => const Padding(
        padding: EdgeInsets.all(TaifaSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How Winga works for you',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            SizedBox(height: 12),
            Text('1. Discover verified offerings'),
            Text('2. Compare with a trusted Winga'),
            Text('3. Accept and pay via Taifa Wallet'),
            Text('4. Track progress and leave a review'),
            SizedBox(height: 12),
            Text('Payments are ledger-backed. AI never authorizes charges.'),
          ],
        ),
      ),
    );
  }
}

class _Discover extends StatelessWidget {
  const _Discover({
    required this.state,
    required this.search,
    required this.comparing,
    required this.onSearch,
    required this.onDomain,
    required this.onFavorite,
    required this.onSelect,
  });

  final BrokerageHomeState state;
  final TextEditingController search;
  final WingaOffering? comparing;
  final ValueChanged<String> onSearch;
  final ValueChanged<String?> onDomain;
  final ValueChanged<String> onFavorite;
  final ValueChanged<WingaOffering> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(TaifaSpacing.screenH),
      children: [
        const WingaGoalHeader(
          goal: 'What do you need today?',
          hint: 'Search across hotels, insurance, property, and more.',
        ),
        const SizedBox(height: TaifaSpacing.lg),
        if (comparing == null && state.deals.isEmpty)
          WingaNextActionBar(
            title: 'Start with a search',
            subtitle: 'Or pick a popular category below.',
            actionLabel: 'Focus search',
            onAction: () => FocusScope.of(context).requestFocus(FocusNode()),
          ),
        if (state.deals.isNotEmpty && !state.deals.first.isPaid) ...[
          const SizedBox(height: TaifaSpacing.md),
          WingaNextActionBar(
            title: 'You have an open deal',
            subtitle: state.deals.first.reference,
            actionLabel: 'Review & pay',
            onAction: () {},
          ),
        ],
        const SizedBox(height: TaifaSpacing.lg),
        TextField(
          controller: search,
          decoration: const InputDecoration(
            hintText: 'Try “hotel Dar” or “motor insurance”',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onSubmitted: onSearch,
        ),
        const SizedBox(height: TaifaSpacing.md),
        WingaChipRow(
          labels: state.domains.map((d) => d.code).toList(),
          selected: state.selectedDomainCode,
          onSelected: onDomain,
        ),
        const SizedBox(height: TaifaSpacing.lg),
        const WingaSectionHeader('Trusted Wingas nearby'),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: state.wingas.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final w = state.wingas[i];
              return SizedBox(
                width: 168,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(TaifaSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          w.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        WingaTrustBadge(
                          label: w.isVerified ? 'Verified Winga' : 'Pending',
                          verified: w.isVerified,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: TaifaSpacing.lg),
        const WingaSectionHeader('Offerings'),
        if (state.isBusy) const WingaLoadingBlock(label: 'Finding matches…'),
        if (!state.isBusy && state.offerings.isEmpty)
          const WingaEmptyState(message: 'No matches — try another category')
        else
          ...state.offerings.map(
            (o) => Padding(
              padding: const EdgeInsets.only(bottom: TaifaSpacing.sm),
              child: WingaOfferingTile(
                title: o.title,
                subtitle: o.description.isEmpty ? o.kind : o.description,
                priceMinor: o.priceMinor,
                kind: o.kind,
                favorited: state.favorites.contains(o.id),
                onFavorite: () => onFavorite(o.id),
                onTap: () => onSelect(o),
              ),
            ),
          ),
      ],
    );
  }
}

class _Compare extends StatelessWidget {
  const _Compare({
    required this.offering,
    required this.wingas,
    required this.onRequest,
    required this.onBack,
  });

  final WingaOffering? offering;
  final List<WingaBrokerProfile> wingas;
  final ValueChanged<WingaOffering> onRequest;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    if (offering == null) {
      return const WingaEmptyState(
        message: 'Select an offering to compare and request a quote',
        icon: Icons.compare_arrows,
      );
    }
    final o = offering!;
    final winga = wingas.isNotEmpty ? wingas.first : null;
    return ListView(
      padding: const EdgeInsets.all(TaifaSpacing.screenH),
      children: [
        const WingaGoalHeader(
          goal: 'Compare before you commit',
          hint: 'See price, trust, and who helps you close.',
        ),
        const SizedBox(height: TaifaSpacing.lg),
        WingaOfferingTile(
          title: o.title,
          subtitle: o.description,
          priceMinor: o.priceMinor,
          kind: o.kind,
        ),
        const SizedBox(height: TaifaSpacing.md),
        if (winga != null)
          Card(
            child: ListTile(
              leading: const Icon(Icons.handshake_outlined),
              title: Text(winga.displayName),
              subtitle: Text(winga.bio),
              trailing: WingaTrustBadge(
                label: 'Winga',
                verified: winga.isVerified,
              ),
            ),
          ),
        const SizedBox(height: TaifaSpacing.lg),
        WingaNextActionBar(
          title: 'Request a quote path',
          subtitle: 'Opens a deal with a verified Winga. Pay only when you accept.',
          actionLabel: 'Continue',
          secondaryLabel: 'Back',
          onSecondary: onBack,
          onAction: () => onRequest(o),
        ),
      ],
    );
  }
}

class _Deals extends StatelessWidget {
  const _Deals({required this.state, required this.onPay});
  final BrokerageHomeState state;
  final ValueChanged<String> onPay;

  @override
  Widget build(BuildContext context) {
    if (state.deals.isEmpty) {
      return const WingaEmptyState(
        message: 'Your quotes, bookings, and receipts will show here',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(TaifaSpacing.screenH),
      itemCount: state.deals.length,
      separatorBuilder: (_, _) => const SizedBox(height: TaifaSpacing.md),
      itemBuilder: (context, i) {
        final d = state.deals[i];
        return Column(
          children: [
            WingaPaymentSummary(
              amountMinor: d.amountMinor,
              currency: d.currency,
              payee: 'Provider via Winga',
              status: d.isPaid ? 'Paid' : 'Awaiting payment',
              paymentRef: d.paymentRef,
            ),
            if (!d.isPaid)
              Padding(
                padding: const EdgeInsets.only(top: TaifaSpacing.sm),
                child: WingaNextActionBar(
                  title: 'Pay securely',
                  subtitle: 'Taifa Wallet · ledger receipt · Instant confirmation',
                  actionLabel: 'Pay now',
                  onAction: () => onPay(d.id),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Assist extends StatelessWidget {
  const _Assist({required this.state, required this.onRefresh});
  final BrokerageHomeState state;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(TaifaSpacing.screenH),
      children: [
        const WingaGoalHeader(
          goal: 'Your assistant',
          hint: 'Recommendations and comparisons — never payment approval.',
        ),
        const SizedBox(height: TaifaSpacing.lg),
        FilledButton.tonal(
          onPressed: onRefresh,
          child: const Text('Refresh suggestions'),
        ),
        const SizedBox(height: TaifaSpacing.lg),
        if (state.assistTips.isEmpty)
          const WingaEmptyState(message: 'Tap refresh for personalized tips')
        else
          ...state.assistTips.map(
            (t) => Card(
              child: ListTile(
                leading: const Icon(Icons.lightbulb_outline),
                title: Text(t),
              ),
            ),
          ),
        if (state.error != null)
          Text(state.error!, style: const TextStyle(color: TaifaColors.danger)),
      ],
    );
  }
}

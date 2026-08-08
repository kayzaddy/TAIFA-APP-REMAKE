import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/taifa_colors.dart';
import '../../../../app/theme/taifa_dimens.dart';
import '../../application/brokerage_providers.dart';
import '../widgets/experience_kit.dart';
import '../widgets/winga_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Provider business app — offerings, campaigns pulse, settlements visibility.
class WingaProviderApp extends ConsumerStatefulWidget {
  const WingaProviderApp({super.key});

  @override
  ConsumerState<WingaProviderApp> createState() => _WingaProviderAppState();
}

class _WingaProviderAppState extends ConsumerState<WingaProviderApp> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(brokerageControllerProvider.notifier).bootstrap(dealsRole: 'provider');
      ref.read(brokerageControllerProvider.notifier).runAssist('campaign_optimization');
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(brokerageControllerProvider);
    final ctrl = ref.read(brokerageControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Hub'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Opportunities',
            onPressed: () => context.push('/winga/opportunities'),
            icon: const Icon(LucideIcons.megaphone),
          ),
          IconButton(
            onPressed: () => context.push('/wallet'),
            icon: const Icon(LucideIcons.wallet),
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          _ProviderHome(
            state: state,
            onOpenLeads: () => setState(() => _tab = 2),
            onOpenCatalog: () => setState(() => _tab = 1),
            onOpenCampaigns: () => setState(() => _tab = 3),
          ),
          _Offerings(state: state),
          _InboundDeals(state: state),
          _CampaignAssist(
            state: state,
            onRefresh: () => ctrl.runAssist('demand_forecast'),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(LucideIcons.house), label: 'Home'),
          NavigationDestination(icon: Icon(LucideIcons.package), label: 'Catalog'),
          NavigationDestination(icon: Icon(LucideIcons.inbox), label: 'Leads'),
          NavigationDestination(icon: Icon(LucideIcons.megaphone), label: 'Campaigns'),
        ],
      ),
    );
  }
}

class _ProviderHome extends StatelessWidget {
  const _ProviderHome({
    required this.state,
    required this.onOpenLeads,
    required this.onOpenCatalog,
    required this.onOpenCampaigns,
  });
  final BrokerageHomeState state;
  final VoidCallback onOpenLeads;
  final VoidCallback onOpenCatalog;
  final VoidCallback onOpenCampaigns;

  @override
  Widget build(BuildContext context) {
    final unpaid = state.deals.where((d) => !d.isPaid).length;
    return ListView(
      padding: const EdgeInsets.all(TaifaSpacing.screenH),
      children: [
        const WingaGoalHeader(
          goal: 'Grow with Wingas',
          hint: 'Catalog clarity, inbound deals, and campaign ROI — one glance.',
        ),
        const SizedBox(height: TaifaSpacing.lg),
        WingaNextActionBar(
          title: unpaid > 0
              ? '$unpaid deals awaiting payment'
              : state.offerings.isEmpty
                  ? 'Publish your first offering'
                  : 'Review Winga partners',
          subtitle: unpaid > 0
              ? 'Customers pay via Taifa — you see settlement progress'
              : 'Visibility drives quality leads from verified Wingas',
          actionLabel: unpaid > 0
              ? 'Open leads'
              : state.offerings.isEmpty
                  ? 'Catalog'
                  : 'Campaigns',
          onAction: () {
            if (unpaid > 0) {
              onOpenLeads();
            } else if (state.offerings.isEmpty) {
              onOpenCatalog();
            } else {
              onOpenCampaigns();
            }
          },
          secondaryLabel: 'Wallet',
          onSecondary: () => context.push('/wallet'),
        ),
        const SizedBox(height: TaifaSpacing.lg),
        Wrap(
          spacing: TaifaSpacing.sm,
          runSpacing: TaifaSpacing.sm,
          children: const [
            WingaTrustBadge(label: 'Business verified'),
            WingaTrustBadge(label: 'Settlement ready'),
          ],
        ),
        const SizedBox(height: TaifaSpacing.lg),
        WingaStatCard(
          label: 'Active offerings',
          value: '${state.offerings.length}',
          accent: TaifaColors.gold500,
        ),
        const SizedBox(height: TaifaSpacing.sm),
        WingaStatCard(
          label: 'Inbound deals',
          value: '${state.deals.length}',
          accent: TaifaColors.ocean500,
        ),
        const SizedBox(height: TaifaSpacing.sm),
        WingaStatCard(
          label: 'Partner Wingas',
          value: '${state.wingas.length}',
          accent: TaifaColors.emerald600,
        ),
        const SizedBox(height: TaifaSpacing.xl),
        const WingaSectionHeader('Winga relationships'),
        ...state.wingas.take(5).map(
              (w) => ListTile(
                leading: const Icon(LucideIcons.handshake),
                title: Text(w.displayName),
                subtitle: Text(w.bio.isEmpty ? w.kind : w.bio),
                trailing: Text('${w.reputationScoreE4 ~/ 1000}★'),
              ),
            ),
        if (state.isBusy) const WingaLoadingBlock(),
      ],
    );
  }
}

class _Offerings extends StatelessWidget {
  const _Offerings({required this.state});
  final BrokerageHomeState state;

  @override
  Widget build(BuildContext context) {
    if (state.offerings.isEmpty) {
      return const WingaEmptyState(message: 'Publish offerings from the backend catalog APIs');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(TaifaSpacing.screenH),
      itemCount: state.offerings.length,
      separatorBuilder: (_, _) => const SizedBox(height: TaifaSpacing.sm),
      itemBuilder: (context, i) {
        final o = state.offerings[i];
        return WingaOfferingTile(
          title: o.title,
          subtitle: o.kind,
          priceMinor: o.priceMinor,
          kind: o.kind,
        );
      },
    );
  }
}

class _InboundDeals extends StatelessWidget {
  const _InboundDeals({required this.state});
  final BrokerageHomeState state;

  @override
  Widget build(BuildContext context) {
    if (state.deals.isEmpty) {
      return const WingaEmptyState(
        message: 'Deals from Wingas land in your inbox here',
        icon: LucideIcons.inbox,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(TaifaSpacing.screenH),
      itemCount: state.deals.length,
      separatorBuilder: (_, _) => const SizedBox(height: TaifaSpacing.sm),
      itemBuilder: (context, i) {
        final d = state.deals[i];
        return WingaPipelineCard(
          title: d.reference,
          stage: d.stage.name,
          subtitle: d.isPaid ? 'Paid' : 'Awaiting payment',
        );
      },
    );
  }
}

class _CampaignAssist extends StatelessWidget {
  const _CampaignAssist({required this.state, required this.onRefresh});
  final BrokerageHomeState state;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(TaifaSpacing.screenH),
      children: [
        const WingaSectionHeader('Campaign intelligence'),
        Text(
          'AI suggests optimization only — you approve campaigns and money moves on the server.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: TaifaSpacing.md),
        const WingaGoalHeader(
          goal: 'Campaign performance',
          hint: 'Commission campaigns stay on the backend; this surface guides action.',
        ),
        const SizedBox(height: TaifaSpacing.md),
        Card(
          color: TaifaColors.gold500.withValues(alpha: 0.12),
          child: const ListTile(
            title: Text('Example campaign'),
            subtitle: Text('Book 50 hotel rooms · 12% Winga commission · Dar region'),
          ),
        ),
        const SizedBox(height: TaifaSpacing.md),
        FilledButton.tonal(onPressed: onRefresh, child: const Text('Optimize with AI')),
        const SizedBox(height: TaifaSpacing.lg),
        ...state.assistTips.map(
          (t) => ListTile(
            leading: const Icon(LucideIcons.chartLine),
            title: Text(t),
          ),
        ),
      ],
    );
  }
}

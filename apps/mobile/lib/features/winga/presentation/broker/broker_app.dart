import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/taifa_colors.dart';
import '../../../../app/theme/taifa_dimens.dart';
import '../../application/brokerage_providers.dart';
import '../widgets/experience_kit.dart';
import '../widgets/winga_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Winga (broker) business OS — CRM, pipeline, commissions, AI coach.
class WingaBrokerApp extends ConsumerStatefulWidget {
  const WingaBrokerApp({super.key});

  @override
  ConsumerState<WingaBrokerApp> createState() => _WingaBrokerAppState();
}

class _WingaBrokerAppState extends ConsumerState<WingaBrokerApp> {
  int _tab = 0;
  final _leadTitle = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(brokerageControllerProvider.notifier).bootstrap(dealsRole: 'winga');
      ref.read(brokerageControllerProvider.notifier).runAssist('lead_prioritization');
    });
  }

  @override
  void dispose() {
    _leadTitle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(brokerageControllerProvider);
    final ctrl = ref.read(brokerageControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Winga Desk'),
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
      floatingActionButton: _tab == 1
          ? FloatingActionButton.extended(
              onPressed: () => _showNewLead(context, state, ctrl),
              icon: const Icon(LucideIcons.userPlus),
              label: const Text('New lead'),
            )
          : null,
      body: IndexedStack(
        index: _tab,
        children: [
          _Dashboard(
            state: state,
            onOpenCrm: () => setState(() => _tab = 1),
            onOpenEarn: () => setState(() => _tab = 2),
          ),
          _Pipeline(state: state),
          _Commissions(
            state: state,
            onSettle: (dealId) async {
              await ctrl.settleDealCommission(dealId);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Commission settlement requested')),
              );
            },
          ),
          _Providers(state: state),
          _Coach(state: state, onRefresh: () => ctrl.runAssist('sales_coaching')),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(LucideIcons.layoutGrid), label: 'Home'),
          NavigationDestination(icon: Icon(LucideIcons.funnel), label: 'CRM'),
          NavigationDestination(icon: Icon(LucideIcons.banknote), label: 'Earn'),
          NavigationDestination(icon: Icon(LucideIcons.store), label: 'Providers'),
          NavigationDestination(icon: Icon(LucideIcons.brain), label: 'Coach'),
        ],
      ),
    );
  }

  Future<void> _showNewLead(
    BuildContext context,
    BrokerageHomeState state,
    BrokerageController ctrl,
  ) async {
    _leadTitle.clear();
    final domainId = state.domains.isNotEmpty ? state.domains.first.id : null;
    if (domainId == null) return;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: TaifaSpacing.screenH,
          right: TaifaSpacing.screenH,
          bottom: MediaQuery.viewInsetsOf(ctx).bottom + TaifaSpacing.xxl,
          top: TaifaSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Capture lead', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: TaifaSpacing.md),
            TextField(
              controller: _leadTitle,
              decoration: const InputDecoration(
                labelText: 'Opportunity title',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: TaifaSpacing.lg),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save lead'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || _leadTitle.text.trim().isEmpty) return;
    await ctrl.createLead(
      title: _leadTitle.text.trim(),
      domainId: domainId,
      customerPrincipal: 'prospect:mobile',
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({
    required this.state,
    required this.onOpenCrm,
    required this.onOpenEarn,
  });
  final BrokerageHomeState state;
  final VoidCallback onOpenCrm;
  final VoidCallback onOpenEarn;

  @override
  Widget build(BuildContext context) {
    final a = state.analytics;
    final hasPending = state.pendingCommissionMinor > 0;
    return ListView(
      padding: const EdgeInsets.all(TaifaSpacing.screenH),
      children: [
        const WingaGoalHeader(
          goal: 'Run your desk',
          hint: 'Opportunities, leads, and earnings — visible in seconds.',
        ),
        const SizedBox(height: TaifaSpacing.lg),
        WingaNextActionBar(
          title: hasPending
              ? 'Settle pending commission'
              : state.leads.isEmpty
                  ? 'Capture your first lead'
                  : 'Follow up: ${state.leads.first.title}',
          subtitle: hasPending
              ? 'Transparent breakdown on Earn · settles to your Taifa wallet'
              : state.leads.isEmpty
                  ? 'Browse campaigns or add a CRM lead'
                  : 'Keep pipeline moving — quotes await response',
          actionLabel: hasPending
              ? 'Open Earn'
              : state.leads.isEmpty
                  ? 'Opportunities'
                  : 'Open CRM',
          onAction: () {
            if (hasPending) {
              onOpenEarn();
            } else if (state.leads.isEmpty) {
              context.push('/winga/opportunities');
            } else {
              onOpenCrm();
            }
          },
          secondaryLabel: 'Wallet',
          onSecondary: () => context.push('/wallet'),
        ),
        const SizedBox(height: TaifaSpacing.lg),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: TaifaSpacing.sm,
          crossAxisSpacing: TaifaSpacing.sm,
          childAspectRatio: 1.35,
          children: [
            WingaStatCard(
              label: 'Pending commission',
              value: _shortMoney(state.pendingCommissionMinor),
              accent: TaifaColors.gold500,
            ),
            WingaStatCard(
              label: 'Settled',
              value: _shortMoney(state.settledCommissionMinor),
              accent: TaifaColors.emerald600,
            ),
            WingaStatCard(
              label: 'Open leads',
              value: '${state.leads.length}',
              accent: TaifaColors.ocean500,
            ),
            WingaStatCard(
              label: 'Active deals',
              value: '${state.deals.length}',
              accent: TaifaColors.emerald700,
            ),
          ],
        ),
        const SizedBox(height: TaifaSpacing.xl),
        const WingaSectionHeader('Marketplace pulse'),
        ListTile(
          leading: const Icon(LucideIcons.chartLine),
          title: Text('Verified Wingas · ${a?.wingasVerified ?? 0}'),
          subtitle: Text('Providers · ${a?.providersVerified ?? 0}'),
        ),
        if (state.isBusy) const WingaLoadingBlock(),
      ],
    );
  }

  String _shortMoney(int minor) {
    final v = minor / 100;
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}k';
    return v.toStringAsFixed(0);
  }
}

class _Pipeline extends StatelessWidget {
  const _Pipeline({required this.state});
  final BrokerageHomeState state;

  @override
  Widget build(BuildContext context) {
    if (state.leads.isEmpty && state.deals.isEmpty) {
      return const WingaEmptyState(
        message: 'Your CRM pipeline is empty — add a lead to start earning',
        icon: LucideIcons.funnel,
      );
    }
    return ListView(
      padding: const EdgeInsets.all(TaifaSpacing.screenH),
      children: [
        const WingaSectionHeader('Leads'),
        ...state.leads.map(
          (l) => Padding(
            padding: const EdgeInsets.only(bottom: TaifaSpacing.sm),
            child: WingaPipelineCard(
              title: l.title,
              stage: l.pipelineStage,
              subtitle: l.notes.isEmpty ? l.customerPrincipal : l.notes,
            ),
          ),
        ),
        const SizedBox(height: TaifaSpacing.lg),
        const WingaSectionHeader('Deals'),
        ...state.deals.map(
          (d) => Padding(
            padding: const EdgeInsets.only(bottom: TaifaSpacing.sm),
            child: WingaPipelineCard(
              title: d.reference,
              stage: d.stage.name,
              subtitle: '${d.currency} · ${d.amountMinor ~/ 100}',
            ),
          ),
        ),
      ],
    );
  }
}

class _Commissions extends StatelessWidget {
  const _Commissions({required this.state, required this.onSettle});
  final BrokerageHomeState state;
  final ValueChanged<String> onSettle;

  @override
  Widget build(BuildContext context) {
    if (state.commissions.isEmpty) {
      return const WingaEmptyState(
        message: 'Commission events appear after customers pay deals',
        icon: LucideIcons.banknote,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(TaifaSpacing.screenH),
      itemCount: state.commissions.length,
      separatorBuilder: (_, _) => const SizedBox(height: TaifaSpacing.sm),
      itemBuilder: (context, i) {
        final c = state.commissions[i];
        final deal = state.deals.where((d) => d.id == c.dealId).firstOrNull;
        return Column(
          children: [
            WingaCommissionBreakdown(
              dealAmountMinor: deal?.amountMinor ?? c.commissionMinor * 10,
              commissionMinor: c.commissionMinor,
              status: c.status,
              currency: c.currency,
              bps: c.bpsApplied,
              providerName: deal?.reference ?? c.dealId,
            ),
            if (c.isPending)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => onSettle(c.dealId),
                  child: const Text('Settle to wallet'),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Providers extends StatelessWidget {
  const _Providers({required this.state});
  final BrokerageHomeState state;

  @override
  Widget build(BuildContext context) {
    if (state.providers.isEmpty) {
      return const WingaEmptyState(message: 'Provider directory loading…');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(TaifaSpacing.screenH),
      itemCount: state.providers.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final p = state.providers[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: TaifaColors.gold500.withValues(alpha: 0.2),
            child: Text(p.displayName.isEmpty ? '?' : p.displayName[0]),
          ),
          title: Text(p.displayName),
          subtitle: Text(
            p.locations.isEmpty ? p.legalName : p.locations.join(' · '),
          ),
          trailing: Chip(
            label: Text(p.isVerified ? 'Verified' : 'Pending'),
            visualDensity: VisualDensity.compact,
          ),
        );
      },
    );
  }
}

class _Coach extends StatelessWidget {
  const _Coach({required this.state, required this.onRefresh});
  final BrokerageHomeState state;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(TaifaSpacing.screenH),
      children: [
        const WingaSectionHeader('Sales coach'),
        Text(
          'AI drafts follow-ups and priorities. It cannot move money.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: TaifaSpacing.md),
        FilledButton.tonal(onPressed: onRefresh, child: const Text('Coach me')),
        const SizedBox(height: TaifaSpacing.lg),
        ...state.assistTips.map(
          (t) => Card(
            child: ListTile(
              leading: const Icon(LucideIcons.lightbulb),
              title: Text(t),
            ),
          ),
        ),
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.only(top: TaifaSpacing.md),
            child: Text(state.error!, style: const TextStyle(color: TaifaColors.danger)),
          ),
      ],
    );
  }
}

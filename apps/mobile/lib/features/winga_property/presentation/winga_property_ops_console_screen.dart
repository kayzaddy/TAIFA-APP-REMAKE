import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../../../app/theme/taifa_theme.dart';
import '../../../shared/widgets/taifa_logo.dart';
import '../application/property_ops_console_providers.dart';
import '../domain/property_models.dart';

/// Dedicated Winga Property ops console — web and mobile.
class WingaPropertyOpsConsoleScreen extends ConsumerStatefulWidget {
  const WingaPropertyOpsConsoleScreen({super.key});

  @override
  ConsumerState<WingaPropertyOpsConsoleScreen> createState() =>
      _WingaPropertyOpsConsoleScreenState();
}

class _WingaPropertyOpsConsoleScreenState extends ConsumerState<WingaPropertyOpsConsoleScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(propertyOpsConsoleProvider.notifier).bootstrap();
    });
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) {
        ref.read(propertyOpsConsoleProvider.notifier).setTab(_tabs.index);
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(propertyOpsConsoleProvider);
    final ctrl = ref.read(propertyOpsConsoleProvider.notifier);
    final palette = context.taifa;
    final console = state.console;
    final isForbidden = state.error?.contains('403') == true;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.surface,
        title: Row(
          children: [
            const TaifaLogo(variant: TaifaLogoVariant.mark, size: 28),
            const SizedBox(width: 8),
            const Text('Winga Property Ops'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: state.isBusy ? null : ctrl.bootstrap,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Moderation'),
            Tab(text: 'Disputes'),
            Tab(text: 'Audit'),
          ],
        ),
      ),
      body: Column(
        children: [
          if (state.isBusy) const LinearProgressIndicator(),
          if (state.error != null)
            MaterialBanner(
              content: Text(
                isForbidden
                    ? 'Access denied. Assign winga.property.ops.read to your principal.'
                    : state.error!,
              ),
              actions: [
                TextButton(onPressed: ctrl.bootstrap, child: const Text('Retry')),
              ],
            ),
          Expanded(
            child: console == null
                ? Center(child: Text('Loading ops console…', style: TextStyle(color: palette.textMuted)))
                : TabBarView(
                    controller: _tabs,
                    children: [
                      _OverviewTab(dashboard: console.dashboard),
                      _ModerationTab(
                        reports: console.moderationReports,
                        onDismiss: ctrl.dismissReport,
                        onSuspend: ctrl.suspendFromReport,
                      ),
                      _DisputesTab(disputes: console.disputes),
                      _AuditTab(events: console.recentAudit),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/winga-property'),
        icon: const Icon(Icons.home_work_rounded),
        label: const Text('Browse listings'),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.dashboard});

  final PropertyOpsDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return ListView(
      padding: const EdgeInsets.all(TaifaSpacing.screenH),
      children: [
        Text('Executive dashboard', style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _Kpi(label: 'Verified listings', value: '${dashboard.listingsVerified}/${dashboard.listingsTotal}'),
            _Kpi(label: 'Applications', value: '${dashboard.applicationsTotal}'),
            _Kpi(label: 'Active leases', value: '${dashboard.leasesActive}'),
            _Kpi(label: 'GMV (minor)', value: '${dashboard.gmvMinor}'),
            _Kpi(label: 'Open disputes', value: '${dashboard.disputesOpen}'),
            _Kpi(label: 'Moderation queue', value: '${dashboard.moderationPending}'),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Fraud ML is advisory only — Taifa Payments risk engine remains authoritative for holds.',
          style: TextStyle(color: palette.textMuted, fontSize: 12),
        ),
      ],
    );
  }
}

class _ModerationTab extends StatelessWidget {
  const _ModerationTab({
    required this.reports,
    required this.onDismiss,
    required this.onSuspend,
  });

  final List<PropertyModerationReport> reports;
  final Future<void> Function(String id) onDismiss;
  final Future<void> Function(String id) onSuspend;

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      return const Center(child: Text('Moderation queue is clear'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(TaifaSpacing.screenH),
      itemCount: reports.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final r = reports[i];
        return ListTile(
          title: Text(r.listingTitle),
          subtitle: Text('${r.reason} · ${r.status}\n${r.notes}'),
          isThreeLine: true,
          trailing: Wrap(
            spacing: 4,
            children: [
              TextButton(onPressed: () => onDismiss(r.id), child: const Text('Dismiss')),
              FilledButton(
                onPressed: () => onSuspend(r.id),
                child: const Text('Suspend'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DisputesTab extends StatelessWidget {
  const _DisputesTab({required this.disputes});

  final List<PropertyDispute> disputes;

  @override
  Widget build(BuildContext context) {
    if (disputes.isEmpty) {
      return const Center(child: Text('No disputes'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(TaifaSpacing.screenH),
      itemCount: disputes.length,
      itemBuilder: (_, i) {
        final d = disputes[i];
        return Card(
          child: ListTile(
            title: Text(d.reason),
            subtitle: Text('${d.subjectType} · ${d.status}'),
            trailing: Chip(
              label: Text(d.status, style: const TextStyle(fontSize: 10)),
              visualDensity: VisualDensity.compact,
            ),
          ),
        );
      },
    );
  }
}

class _AuditTab extends StatelessWidget {
  const _AuditTab({required this.events});

  final List<PropertyOpsAuditEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Center(child: Text('No audit events yet'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(TaifaSpacing.screenH),
      itemCount: events.length,
      itemBuilder: (_, i) {
        final e = events[i];
        return ListTile(
          dense: true,
          leading: const Icon(Icons.history_rounded, size: 18, color: TaifaColors.gold400),
          title: Text(e.action),
          subtitle: Text('${e.entityType} · ${e.actor}'),
          trailing: Text(e.createdAt, style: const TextStyle(fontSize: 10)),
        );
      },
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: palette.textMuted, fontSize: 11)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w800, fontSize: 18)),
        ],
      ),
    );
  }
}

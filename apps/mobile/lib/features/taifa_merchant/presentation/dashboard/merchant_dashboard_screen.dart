import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../application/merchant_auth_controller.dart';
import '../../application/merchant_workspace_providers.dart';
import '../../data/models/merchant_workspace_models.dart';
import '../widgets/merchant_section_header.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MerchantDashboardScreen extends ConsumerWidget {
  const MerchantDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dash = ref.watch(merchantDashboardSnapshotProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Merchant workspace'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.monitorSmartphone),
            onPressed: () => context.push('/taifa-merchant/devices'),
          ),
          IconButton(
            icon: const Icon(LucideIcons.logOut),
            onPressed: () async {
              await ref.read(merchantAuthControllerProvider.notifier).logout();
              if (context.mounted) context.go('/taifa-merchant/login');
            },
          ),
        ],
      ),
      body: dash.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Complete business registration to open your workspace.'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => context.go('/taifa-merchant/register-business'),
                child: const Text('Register business'),
              ),
            ],
          ),
        ),
        data: (snapshot) {
          final counts = snapshot.counts ?? const MerchantCounts();
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(merchantDashboardSnapshotProvider);
              await ref.read(merchantDashboardSnapshotProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                MerchantSectionHeader(
                  title: 'Business summary',
                  subtitle: 'Health: ${snapshot.merchantHealth} · ${snapshot.verificationStatus}',
                ),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _StatCard(
                      label: 'Branches',
                      value: '${counts.branches}',
                      onTap: () => context.push('/taifa-merchant/branches'),
                    ),
                    _StatCard(
                      label: 'Employees',
                      value: '${counts.employees}',
                      onTap: () => context.push('/taifa-merchant/employees'),
                    ),
                    _StatCard(
                      label: 'Devices',
                      value: '${counts.devices}',
                      onTap: () => context.push('/taifa-merchant/devices'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const MerchantSectionHeader(title: 'Quick actions'),
                Wrap(
                  spacing: 8,
                  children: [
                    ActionChip(label: const Text('Branches'), onPressed: () => context.push('/taifa-merchant/branches')),
                    ActionChip(label: const Text('Invite staff'), onPressed: () => context.push('/taifa-merchant/employees')),
                    ActionChip(label: const Text('Register device'), onPressed: () => context.push('/taifa-merchant/devices')),
                  ],
                ),
                const SizedBox(height: 16),
                const MerchantSectionHeader(title: 'Notification center'),
                if (snapshot.notifications.isEmpty)
                  const ListTile(title: Text('No new alerts'))
                else
                  ...snapshot.notifications.take(3).map(
                        (n) => ListTile(
                          leading: Icon(n.isRead ? LucideIcons.mailOpen : LucideIcons.mail),
                          title: Text(n.title),
                          subtitle: Text(n.body),
                        ),
                      ),
                const SizedBox(height: 8),
                const MerchantSectionHeader(title: 'Activity timeline'),
                if (snapshot.activityTimeline.isEmpty)
                  const ListTile(title: Text('Activity will appear here'))
                else
                  ...snapshot.activityTimeline.take(5).map(
                        (a) => ListTile(
                          dense: true,
                          title: Text(a.summary),
                          subtitle: Text(a.activityType),
                        ),
                      ),
                const SizedBox(height: 16),
                const MerchantSectionHeader(title: 'Payments'),
                ListTile(
                  leading: const Icon(LucideIcons.banknote),
                  title: const Text('Accept payments'),
                  subtitle: const Text('SoftPOS, QR, links — via TNPI'),
                  onTap: () => context.push('/taifa-merchant/payments'),
                ),
                ListTile(
                  leading: const Icon(LucideIcons.chartLine),
                  title: const Text('Today\'s sales'),
                  onTap: () => context.push('/taifa-merchant/payments/analytics'),
                ),
                if (snapshot.pendingTasks.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const MerchantSectionHeader(title: 'Pending tasks'),
                  ...snapshot.pendingTasks.map(
                    (t) => ListTile(
                      leading: const Icon(LucideIcons.hourglass),
                      title: Text(t['title']?.toString() ?? ''),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [Text(value, style: Theme.of(context).textTheme.headlineMedium), Text(label)],
          ),
        ),
      ),
    );
  }
}

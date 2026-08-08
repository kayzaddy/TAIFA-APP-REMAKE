import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/registry_providers.dart';
import '../domain/registry_application.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class RegistryAdminScreen extends ConsumerWidget {
  const RegistryAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(registryAdminControllerProvider);
    final controller = ref.read(registryAdminControllerProvider.notifier);
    final dashboardItems = <MapEntry<String, dynamic>>[];
    for (final entry in state.dashboard.entries) {
      if (entry.value is num) {
        dashboardItems.add(entry);
      } else if (entry.value is Map) {
        for (final nested in (entry.value as Map).entries) {
          dashboardItems.add(
            MapEntry('${entry.key}_${nested.key}', nested.value),
          );
        }
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registry Verification'),
        actions: [
          IconButton(
            onPressed: state.loading ? null : controller.load,
            icon: const Icon(LucideIcons.refreshCw),
          ),
        ],
      ),
      body: Column(
        children: [
          if (state.loading) const LinearProgressIndicator(),
          if (state.error != null)
            MaterialBanner(
              content: Text(
                state.error!.contains('403')
                    ? 'Your account is not authorized for registry verification.'
                    : state.error!,
              ),
              actions: [
                TextButton(
                  onPressed: controller.load,
                  child: const Text('Retry'),
                ),
              ],
            ),
          if (state.dashboard.isNotEmpty)
            SizedBox(
              height: 126,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(12),
                children: dashboardItems
                    .map(
                      (entry) => Card(
                        child: SizedBox(
                          width: 150,
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.key.replaceAll('_', ' '),
                                  maxLines: 2,
                                ),
                                const Spacer(),
                                Text(
                                  '${entry.value}',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          Expanded(
            child: state.queue.isEmpty
                ? const Center(
                    child: Text('No applications in the review queue'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: state.queue.length,
                    itemBuilder: (context, index) {
                      final application = state.queue[index];
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(LucideIcons.clipboardList),
                          ),
                          title: Text(application.number),
                          subtitle: Text(
                            '${application.type.name} • ${application.status.name}\n'
                            '${application.stage} • ${application.region}',
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (action) => _confirm(
                              context,
                              controller,
                              application,
                              action,
                            ),
                            itemBuilder: (_) => [
                              if (application.stage != 'approval')
                                const PopupMenuItem(
                                  value: 'advance',
                                  child: Text('Advance review'),
                                ),
                              if (application.stage == 'approval')
                                const PopupMenuItem(
                                  value: 'approve',
                                  child: Text('Approve'),
                                ),
                              const PopupMenuItem(
                                value: 'reject',
                                child: Text('Reject'),
                              ),
                              if (application.status ==
                                  RegistryApplicationStatus.approved)
                                const PopupMenuItem(
                                  value: 'suspend',
                                  child: Text('Suspend'),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirm(
    BuildContext context,
    RegistryAdminController controller,
    RegistryApplication application,
    String action,
  ) async {
    final reason = TextEditingController();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          '${action[0].toUpperCase()}${action.substring(1)} application',
        ),
        content: TextField(
          controller: reason,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: action == 'advance' || action == 'approve'
                ? 'Review comments'
                : 'Reason (required)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    final value = reason.text.trim();
    reason.dispose();
    if (accepted != true) return;
    if ((action == 'reject' || action == 'suspend') && value.isEmpty) {
      return;
    }
    await controller.action(application, action, reason: value);
  }
}

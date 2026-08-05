import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/ecosystem_modules_provider.dart';
import '../domain/super_app_module_registry.dart';

/// Enable / disable Super App modules — one identity, optional services.
class MyServicesScreen extends ConsumerWidget {
  const MyServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(enabledModulesProvider);
    final ctrl = ref.read(enabledModulesProvider.notifier);

    final core = state.modules.where((m) => m.meta.isCore).toList();
    final services = state.modules.where((m) => m.meta.category == 'service').toList();
    final ops = state.modules.where((m) => m.meta.isOps).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Services'),
        actions: [
          IconButton(
            onPressed: state.isLoading ? null : ctrl.load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          if (state.isLoading) const LinearProgressIndicator(),
          if (state.error != null)
            MaterialBanner(
              content: Text(state.error!),
              actions: [
                TextButton(onPressed: ctrl.load, child: const Text('Retry')),
              ],
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Toggle services on to add them to your Home grid and Menu. '
              'Changes apply immediately — new catalog modules appear after app updates.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                _SectionHeader(title: 'Always on', subtitle: 'Core Taifa services'),
                ...core.map((m) => _ModuleTile(module: m, onToggle: null)),
                _SectionHeader(
                  title: 'Services',
                  subtitle: '${services.where((m) => m.enabled).length} enabled',
                ),
                ...services.map(
                  (m) => _ModuleTile(
                    module: m,
                    onToggle: (v) => ctrl.setEnabled(m.meta.code, v),
                  ),
                ),
                _SectionHeader(
                  title: 'Operations',
                  subtitle: 'Consoles & admin tools',
                ),
                ...ops.map(
                  (m) => _ModuleTile(
                    module: m,
                    onToggle: (v) => ctrl.setEnabled(m.meta.code, v),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          Text(subtitle, style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({required this.module, required this.onToggle});
  final EnabledSuperAppModule module;
  final ValueChanged<bool>? onToggle;

  @override
  Widget build(BuildContext context) {
    final meta = module.meta;
    return SwitchListTile(
      secondary: CircleAvatar(
        backgroundColor: meta.tint.withValues(alpha: 0.15),
        child: Icon(meta.icon, color: meta.tint, size: 20),
      ),
      title: Text(meta.name),
      subtitle: Text(
        meta.subtitle.isNotEmpty
            ? '${meta.subtitle} · ${meta.route}'
            : meta.route,
      ),
      value: module.enabled,
      onChanged: onToggle == null ? null : (v) => onToggle!(v),
    );
  }
}

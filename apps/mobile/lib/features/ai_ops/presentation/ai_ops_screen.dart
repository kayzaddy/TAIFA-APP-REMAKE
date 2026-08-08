import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../wallet/application/wallet_providers.dart' show apiClientProvider;
import '../../../data/ai_os/ai_os_client.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

final aiOsClientProvider = Provider<AiOsClient>(
  (ref) => AiOsClient(ref.watch(apiClientProvider)),
);

/// AI Operations Console — model health, usage, safety.
class AiOpsScreen extends ConsumerStatefulWidget {
  const AiOpsScreen({super.key});

  @override
  ConsumerState<AiOpsScreen> createState() => _AiOpsScreenState();
}

class _AiOpsScreenState extends ConsumerState<AiOpsScreen> {
  Map<String, dynamic> _cc = const {};
  List<Map<String, dynamic>> _agents = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = ref.read(aiOsClientProvider);
      final cc = await client.commandCenter();
      final agents = await client.agents();
      setState(() {
        _cc = cc;
        _agents = agents;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final health = (_cc['health'] as Map?)?.cast<String, dynamic>() ?? const {};
    final today = (_cc['today'] as Map?)?.cast<String, dynamic>() ?? const {};
    final safety =
        ((_cc['safety_events'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
    final byCap =
        ((_cc['by_capability'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Command Center'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(LucideIcons.refreshCw),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            MaterialBanner(
              content: Text(_error!),
              actions: [
                TextButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Text(
                  'Taifa AI OS',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Intelligence layer — advisory, auditable, human-gated for critical actions.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Chip('Status', '${health['status'] ?? '-'}'),
                    _Chip('Models', '${health['models_active'] ?? 0}'),
                    _Chip('Capabilities', '${health['capabilities'] ?? 0}'),
                    _Chip('Agents', '${health['agents'] ?? 0}'),
                    _Chip('Knowledge', '${health['knowledge_docs'] ?? 0}'),
                    _Chip('Invocations', '${today['invocations'] ?? 0}'),
                    _Chip('Latency ms', '${today['avg_latency_ms'] ?? 0}'),
                    _Chip('Tokens', '${today['token_estimate'] ?? 0}'),
                    _Chip('Approvals', '${today['approval_pending'] ?? 0}'),
                    _Chip('Low conf', '${today['low_confidence'] ?? 0}'),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Usage by capability',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                for (final row in byCap.take(12))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${row['capability_code'] ?? '-'}'),
                    subtitle: Text(
                      'inv ${row['invocations'] ?? 0} · err ${row['errors'] ?? 0} · '
                      'tokens ${row['tokens'] ?? 0}',
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  'Domain agents',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                for (final agent in _agents)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${agent['name'] ?? agent['code']}'),
                    subtitle: Text(
                      '${agent['domain_code'] ?? ''} · '
                      '${((agent['capabilities'] as List?) ?? const []).length} caps',
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  'Safety events',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (safety.isEmpty)
                  const Text('No recent safety events.')
                else
                  for (final row in safety.take(10))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('${row['kind'] ?? '-'} · ${row['severity'] ?? ''}'),
                      subtitle: Text('${row['principal'] ?? ''} · ${row['created_at'] ?? ''}'),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text('$label: $value'));
  }
}

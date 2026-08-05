import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../wallet/application/wallet_providers.dart' show apiClientProvider;
import '../../../data/continental/continental_client.dart';

final continentalClientProvider = Provider<ContinentalClient>(
  (ref) => ContinentalClient(ref.watch(apiClientProvider)),
);

class ContinentalOpsScreen extends ConsumerStatefulWidget {
  const ContinentalOpsScreen({super.key});

  @override
  ConsumerState<ContinentalOpsScreen> createState() =>
      _ContinentalOpsScreenState();
}

class _ContinentalOpsScreenState extends ConsumerState<ContinentalOpsScreen> {
  Map<String, dynamic> _ops = const {};
  List<Map<String, dynamic>> _countries = const [];
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
      final client = ref.read(continentalClientProvider);
      final ops = await client.opsCenter();
      final countries = await client.countries();
      setState(() {
        _ops = ops;
        _countries = countries;
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
    final slos = (_ops['slos'] as Map?)?.cast<String, dynamic>() ?? const {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Continental Ops'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
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
                  'Pan-African Digital Infrastructure',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'One platform · many countries · local compliance',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Chip('Active', '${_ops['active_countries'] ?? 0}'),
                    _Chip('Pilot', '${_ops['pilot_countries'] ?? 0}'),
                    _Chip('Corridors', '${_ops['corridors_active'] ?? 0}'),
                    _Chip('Partners', '${_ops['partners_certified'] ?? 0}'),
                    _Chip(
                      'API SLO',
                      '${slos['api_availability_target_e4'] ?? '-'}',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Countries',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                for (final row in _countries)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${row['name'] ?? row['code']} (${row['code']})'),
                    subtitle: Text(
                      '${row['status'] ?? ''} · ${row['default_currency'] ?? ''} · '
                      '${row['default_locale'] ?? ''} · ${row['data_region'] ?? ''}',
                    ),
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

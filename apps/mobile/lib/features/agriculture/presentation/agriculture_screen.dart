import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../ecosystem/application/ecosystem_modules_provider.dart'
    show ecosystemClientProvider;

class AgricultureScreen extends ConsumerStatefulWidget {
  const AgricultureScreen({super.key});

  @override
  ConsumerState<AgricultureScreen> createState() => _AgricultureScreenState();
}

class _AgricultureScreenState extends ConsumerState<AgricultureScreen> {
  List<Map<String, dynamic>> _farms = const [];
  List<Map<String, dynamic>> _listings = const [];
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
      final client = ref.read(ecosystemClientProvider);
      final farms = await client.farms();
      final listings = await client.listings();
      setState(() {
        _farms = farms;
        _listings = listings;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agriculture'),
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
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Farm registry & marketplace',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Payments settle through Taifa Wallet. Logistics use Mobility.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                Text('My farms', style: Theme.of(context).textTheme.titleSmall),
                if (_farms.isEmpty)
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('No farms yet'),
                    subtitle: Text('Register via ecosystem agriculture API'),
                  )
                else
                  for (final farm in _farms)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('${farm['name'] ?? '-'}'),
                      subtitle: Text(
                        '${farm['farm_code'] ?? ''} · ${farm['region'] ?? ''}',
                      ),
                    ),
                const SizedBox(height: 16),
                Text(
                  'Marketplace listings',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (_listings.isEmpty)
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('No open listings'),
                  )
                else
                  for (final row in _listings)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('${row['title'] ?? '-'}'),
                      subtitle: Text(
                        '${row['kind'] ?? ''} · ${row['price_minor'] ?? 0} '
                        '${row['unit'] ?? ''} · ${row['region'] ?? ''}',
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

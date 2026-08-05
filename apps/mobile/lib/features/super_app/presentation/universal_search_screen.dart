import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../application/super_app_providers.dart';
import '../domain/ecosystem_catalog.dart';

class UniversalSearchScreen extends ConsumerStatefulWidget {
  const UniversalSearchScreen({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  ConsumerState<UniversalSearchScreen> createState() => _UniversalSearchScreenState();
}

class _UniversalSearchScreenState extends ConsumerState<UniversalSearchScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery ?? '');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchQueryProvider.notifier).setQuery(_controller.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData _iconFor(EcosystemEntry e) {
    return switch (e.category) {
      'Pay' => Icons.payments_rounded,
      'Mobility' => Icons.local_taxi_rounded,
      'Commerce' => Icons.storefront_rounded,
      'Winga' => Icons.shopping_bag_rounded,
      'Bookings' => Icons.event_available_rounded,
      'Services' => Icons.apps_rounded,
      'Assist' => Icons.auto_awesome_rounded,
      'Account' => Icons.person_rounded,
      _ => Icons.chevron_right_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(searchResultsProvider);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Taifa'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(TaifaSpacing.screenH),
            child: TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search products, rides, hotels, pay, Winga…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          ref.read(searchQueryProvider.notifier).clear();
                          setState(() {});
                        },
                      ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onChanged: (v) {
                ref.read(searchQueryProvider.notifier).setQuery(v);
                setState(() {});
              },
              onSubmitted: (v) {
                ref.read(searchQueryProvider.notifier).setQuery(v);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: TaifaSpacing.screenH),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'One search across the ecosystem — routes to live modules. No duplicate backends.',
                style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ),
          const SizedBox(height: TaifaSpacing.sm),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                TaifaSpacing.screenH,
                0,
                TaifaSpacing.screenH,
                40,
              ),
              itemCount: results.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final e = results[i];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: TaifaColors.ocean500.withValues(alpha: 0.12),
                    child: Icon(_iconFor(e), color: TaifaColors.ocean500, size: 22),
                  ),
                  title: Text(e.title, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  subtitle: Text('${e.category} · ${e.subtitle}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(e.route),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

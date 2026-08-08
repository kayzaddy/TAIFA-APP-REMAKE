import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/taifa_dimens.dart';
import '../../application/experience_providers.dart';
import '../../domain/opportunity_models.dart';
import '../widgets/experience_kit.dart';
import '../widgets/winga_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Opportunity marketplace — campaigns Wingas can apply to.
class WingaOpportunityFeedScreen extends ConsumerStatefulWidget {
  const WingaOpportunityFeedScreen({super.key});

  @override
  ConsumerState<WingaOpportunityFeedScreen> createState() =>
      _WingaOpportunityFeedScreenState();
}

class _WingaOpportunityFeedScreenState
    extends ConsumerState<WingaOpportunityFeedScreen> {
  String? _industry;
  String _query = '';
  bool _trendingOnly = false;
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(experiencePrefsProvider);
    final industries = WingaOpportunityCatalog.all()
        .map((o) => o.industry)
        .toSet()
        .toList()
      ..sort();
    final feed = WingaOpportunityCatalog.filtered(
      industry: _industry,
      query: _query,
      trendingOnly: _trendingOnly,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Opportunities'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'AI matches',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'AI recommends hospitality & insurance based on your profile',
                  ),
                ),
              );
            },
            icon: const Icon(LucideIcons.sparkles),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(TaifaSpacing.screenH),
        children: [
          const WingaGoalHeader(
            goal: 'Find work that pays',
            hint: 'Browse provider campaigns. Commission is shown before you apply.',
          ),
          const SizedBox(height: TaifaSpacing.lg),
          TextField(
            controller: _search,
            decoration: const InputDecoration(
              hintText: 'Search industry, city, or campaign…',
              prefixIcon: Icon(LucideIcons.search),
              border: OutlineInputBorder(),
            ),
            onSubmitted: (v) => setState(() => _query = v),
            textInputAction: TextInputAction.search,
          ),
          const SizedBox(height: TaifaSpacing.md),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('Trending'),
                selected: _trendingOnly,
                onSelected: (v) => setState(() => _trendingOnly = v),
              ),
              ...industries.map(
                (i) => FilterChip(
                  label: Text(i),
                  selected: _industry == i,
                  onSelected: (v) =>
                      setState(() => _industry = v ? i : null),
                ),
              ),
            ],
          ),
          const SizedBox(height: TaifaSpacing.lg),
          if (feed.isEmpty)
            const WingaEmptyState(
              message: 'No campaigns match — try clearing filters',
              icon: LucideIcons.megaphone,
            )
          else
            ...feed.map((o) {
              final saved = prefs.savedOpportunityIds.contains(o.id);
              final applied = prefs.appliedOpportunityIds.contains(o.id);
              return Padding(
                padding: const EdgeInsets.only(bottom: TaifaSpacing.md),
                child: WingaOpportunityCard(
                  title: o.title,
                  industry: o.industry,
                  location: o.location,
                  commissionLabel: o.commissionLabel,
                  urgency: o.urgency,
                  trending: o.trending,
                  onSave: () =>
                      ref.read(experiencePrefsProvider.notifier).toggleSave(o.id),
                  onApply: applied
                      ? null
                      : () {
                          ref.read(experiencePrefsProvider.notifier).apply(o.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                saved
                                    ? 'Applied · also saved'
                                    : 'Applied to “${o.title}”',
                              ),
                            ),
                          );
                        },
                ),
              );
            }),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../../../app/theme/taifa_theme.dart';
import '../../../shared/widgets/taifa_logo.dart';
import '../application/property_providers.dart';
import '../domain/property_models.dart';
import 'property_compare_sheet.dart';
import 'property_detail_sheet.dart';
import 'property_experience_sheets.dart';
import 'property_winga_sheets.dart';
import 'property_transaction_sheets.dart';
import 'property_ops_sheets.dart';
import 'property_map_view.dart';

class WingaPropertyScreen extends ConsumerStatefulWidget {
  const WingaPropertyScreen({super.key});

  @override
  ConsumerState<WingaPropertyScreen> createState() => _WingaPropertyScreenState();
}

class _WingaPropertyScreenState extends ConsumerState<WingaPropertyScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(propertyControllerProvider.notifier).bootstrap();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(propertyControllerProvider);
    final ctrl = ref.read(propertyControllerProvider.notifier);
    final palette = context.taifa;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TaifaSpacing.screenH,
                TaifaSpacing.sm,
                TaifaSpacing.screenH,
                0,
              ),
              child: Row(
                children: [
                  const TaifaLogo(variant: TaifaLogoVariant.mark, size: 36),
                  const SizedBox(width: TaifaSpacing.sm),
                  Expanded(
                    child: Text(
                      'Winga Property',
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  if (state.compareIds.isNotEmpty)
                    TextButton(
                      onPressed: ctrl.runCompare,
                      child: Text('Compare (${state.compareIds.length})'),
                    ),
                  IconButton(
                    onPressed: ctrl.toggleAdvancedFilters,
                    icon: Icon(
                      Icons.tune_rounded,
                      color: state.showAdvancedFilters ? TaifaColors.gold400 : palette.textMuted,
                    ),
                  ),
                  IconButton(
                    onPressed: ctrl.toggleMap,
                    icon: Icon(
                      state.showMap ? Icons.list_rounded : Icons.map_rounded,
                      color: TaifaColors.gold400,
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.push('/winga-property/ops'),
                    icon: Icon(Icons.dashboard_customize_rounded, color: palette.textMuted),
                    tooltip: 'Ops console',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TaifaSpacing.screenH,
                TaifaSpacing.sm,
                TaifaSpacing.screenH,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onSubmitted: ctrl.search,
                      decoration: InputDecoration(
                        hintText: state.useAiSearch
                            ? 'Ask AI: 2-bed near Masaki with good safety…'
                            : 'Search area, beds, neighborhood…',
                        prefixIcon: Icon(
                          state.useAiSearch ? Icons.auto_awesome_rounded : Icons.search_rounded,
                        ),
                        filled: true,
                        fillColor: palette.surfaceAlt,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: palette.border),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: ctrl.toggleAiSearch,
                    tooltip: 'AI search',
                    icon: Icon(
                      Icons.psychology_rounded,
                      color: state.useAiSearch ? TaifaColors.gold400 : palette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (state.showAdvancedFilters) _AdvancedFilters(state: state, ctrl: ctrl),
            if (state.categories.isNotEmpty)
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: TaifaSpacing.screenH),
                  itemCount: state.categories.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    if (i == 0) {
                      return _FilterChip(
                        label: 'All',
                        selected: state.selectedCategory.isEmpty,
                        onTap: () => ctrl.setCategory(''),
                      );
                    }
                    final cat = state.categories[i - 1];
                    return _FilterChip(
                      label: cat.name,
                      selected: state.selectedCategory == cat.code,
                      onTap: () => ctrl.setCategory(cat.code),
                    );
                  },
                ),
              ),
            if (!state.showMap && state.recentlyViewed.isNotEmpty)
              _HorizontalSection(
                title: 'Recently viewed',
                listings: state.recentlyViewed,
                onTap: ctrl.openListing,
              ),
            if (!state.showMap && state.recommendations.isNotEmpty)
              _HorizontalSection(
                title: 'Recommended for you',
                listings: state.recommendations,
                onTap: ctrl.openListing,
              ),
            const SizedBox(height: 8),
            Expanded(
              child: state.showMap
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: TaifaSpacing.screenH),
                      child: PropertyDiscoveryMap(
                        pins: state.pins,
                        clusters: state.clusters,
                        selectedId: state.selected?.id,
                        onTap: ctrl.openListing,
                      ),
                    )
                  : _ListingList(
                      listings: state.listings,
                      isFavorite: ctrl.isFavorite,
                      isInCompare: ctrl.isInCompare,
                      onFavorite: ctrl.toggleFavorite,
                      onCompare: ctrl.toggleCompare,
                      onTap: ctrl.openListing,
                    ),
            ),
          ],
        ),
      ),
      bottomSheet: state.showCompare
          ? PropertyCompareSheet(
              rows: state.compareRows,
              onClose: ctrl.closeCompare,
              onClear: ctrl.clearCompare,
            )
          : state.showExperience && state.experience != null
          ? PropertyExperienceSheet(
              experience: state.experience!,
              onClose: ctrl.closeExperience,
            )
          : state.showViewingPass
          ? PropertyViewingPassSheet(
              plans: state.viewingPassPlans,
              isUnlocked: state.selected?.isUnlocked ?? false,
              onClose: ctrl.closeViewingPass,
              onPurchase: ctrl.purchaseViewingPass,
            )
          : state.showCopilot
          ? PropertyCopilotSheet(
              messages: state.copilotMessages,
              onClose: ctrl.closeCopilot,
              onAsk: ctrl.askCopilot,
            )
          : state.showReport
          ? PropertyReportSheet(
              onClose: ctrl.closeReportListing,
              onSubmit: (reason, notes) => ctrl.submitListingReport(reason, notes),
            )
          : state.showApply && state.selected != null
          ? PropertyApplySheet(
              listing: state.selected!,
              application: state.application,
              lease: state.lease,
              isBusy: state.isBusy,
              onClose: ctrl.closeApply,
              onStartApplication: ctrl.startApplication,
              onSubmit: ctrl.submitApplication,
              onVerifyIdentity: ctrl.verifyApplicationIdentity,
              onVerifyIncome: ctrl.verifyApplicationIncome,
              onApprove: ctrl.approveApplication,
              onGenerateLease: ctrl.generateLease,
              onSignLease: ctrl.signLease,
              onPayDeposit: ctrl.payDeposit,
              onCompleteMoveIn: ctrl.completeMoveIn,
              onRenewLease: ctrl.renewLease,
            )
          : state.showHumanWinga && state.assignment != null
          ? PropertyHumanWingaSheet(
              assignment: state.assignment!,
              messages: state.assignmentChat,
              onClose: ctrl.closeHumanWinga,
              onSend: ctrl.sendWingaChat,
            )
          : state.showLiveSession && state.liveSession != null
          ? PropertyLiveSessionSheet(
              session: state.liveSession!,
              onClose: ctrl.closeLiveSession,
              onEnd: ctrl.endLiveTour,
            )
          : state.selected == null
          ? null
          : PropertyDetailSheet(
              listing: state.selected!,
              isFavorite: ctrl.isFavorite(state.selected!.id),
              intelligence: state.intelligence,
              visitScore: state.visitScore,
              commute: state.commute,
              isInCompare: ctrl.isInCompare(state.selected!.id),
              onToggleCompare: () => ctrl.toggleCompare(state.selected!.id),
              onVirtualTour: ctrl.openExperience,
              onViewingPass: ctrl.openViewingPass,
              onLiveTour: ctrl.requestLiveTour,
              onCopilot: ctrl.openCopilot,
              onHumanWinga: ctrl.assignHumanWinga,
              onApply: ctrl.openApply,
              onReport: ctrl.openReportListing,
              onClose: ctrl.closeDetail,
              onFavorite: () => ctrl.toggleFavorite(state.selected!),
            ),
    );
  }
}

class _AdvancedFilters extends StatelessWidget {
  const _AdvancedFilters({required this.state, required this.ctrl});

  final PropertyUiState state;
  final PropertyController ctrl;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TaifaSpacing.screenH,
        vertical: TaifaSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Advanced filters', style: TextStyle(color: palette.textMuted, fontSize: 12)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              _FilterChip(
                label: '2+ beds',
                selected: state.minBeds == 2,
                onTap: () => ctrl.setMinBeds(state.minBeds == 2 ? null : 2),
              ),
              _FilterChip(
                label: '3+ beds',
                selected: state.minBeds == 3,
                onTap: () => ctrl.setMinBeds(state.minBeds == 3 ? null : 3),
              ),
              _FilterChip(
                label: 'Safe area',
                selected: state.minSafetyE4 == 7000,
                onTap: () => ctrl.setMinSafety(state.minSafetyE4 == 7000 ? null : 7000),
              ),
              _FilterChip(
                label: 'Coastal',
                selected: state.lifestyle == 'upmarket_coastal',
                onTap: () => ctrl.setLifestyle(
                  state.lifestyle == 'upmarket_coastal' ? '' : 'upmarket_coastal',
                ),
              ),
              _FilterChip(
                label: 'Family',
                selected: state.lifestyle == 'family_suburban',
                onTap: () => ctrl.setLifestyle(
                  state.lifestyle == 'family_suburban' ? '' : 'family_suburban',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HorizontalSection extends StatelessWidget {
  const _HorizontalSection({
    required this.title,
    required this.listings,
    required this.onTap,
  });

  final String title;
  final List<PropertyListing> listings;
  final Future<void> Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(TaifaSpacing.screenH, 8, TaifaSpacing.screenH, 4),
          child: Text(
            title,
            style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: TaifaSpacing.screenH),
            itemCount: listings.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final l = listings[i];
              return InkWell(
                onTap: () => onTap(l.id),
                child: SizedBox(
                  width: 140,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (l.primaryPhotoUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(l.primaryPhotoUrl, height: 60, width: 140, fit: BoxFit.cover),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        l.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: palette.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        l.price.format(),
                        style: const TextStyle(color: TaifaColors.gold400, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? TaifaColors.gold500.withValues(alpha: 0.15)
              : palette.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? TaifaColors.gold500 : palette.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? TaifaColors.gold400 : palette.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _ListingList extends StatelessWidget {
  const _ListingList({
    required this.listings,
    required this.isFavorite,
    required this.isInCompare,
    required this.onFavorite,
    required this.onCompare,
    required this.onTap,
  });

  final List<PropertyListing> listings;
  final bool Function(String) isFavorite;
  final bool Function(String) isInCompare;
  final Future<void> Function(PropertyListing) onFavorite;
  final void Function(String) onCompare;
  final Future<void> Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    if (listings.isEmpty) {
      return Center(child: Text('No properties found', style: TextStyle(color: palette.textMuted)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(TaifaSpacing.screenH),
      itemCount: listings.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final l = listings[i];
        return InkWell(
          onTap: () => onTap(l.id),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: palette.surfaceAlt,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isInCompare(l.id) ? TaifaColors.gold500 : palette.border,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (l.primaryPhotoUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      l.primaryPhotoUrl,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        height: 160,
                        color: palette.border,
                        child: const Icon(Icons.home_work_rounded, size: 48),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (l.isVerified)
                              const Text(
                                'VERIFIED',
                                style: TextStyle(
                                  color: TaifaColors.emerald700,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            Text(
                              l.title,
                              style: TextStyle(
                                color: palette.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              l.locationLabel,
                              style: TextStyle(color: palette.textMuted, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${l.price.format()}/mo · ${l.beds} bed · ${l.baths} bath',
                              style: const TextStyle(
                                color: TaifaColors.gold400,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => onCompare(l.id),
                        icon: Icon(
                          isInCompare(l.id) ? Icons.compare_arrows : Icons.compare_arrows_outlined,
                          color: TaifaColors.gold400,
                          size: 20,
                        ),
                      ),
                      IconButton(
                        onPressed: () => onFavorite(l),
                        icon: Icon(
                          isFavorite(l.id) ? Icons.favorite : Icons.favorite_border,
                          color: TaifaColors.gold400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

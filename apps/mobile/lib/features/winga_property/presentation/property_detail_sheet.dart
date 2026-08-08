import 'package:flutter/material.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../../../app/theme/taifa_theme.dart';
import '../domain/property_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PropertyDetailSheet extends StatelessWidget {
  const PropertyDetailSheet({
    super.key,
    required this.listing,
    required this.isFavorite,
    required this.onClose,
    required this.onFavorite,
    this.intelligence,
    this.visitScore,
    this.commute,
    this.isInCompare = false,
    this.onToggleCompare,
    this.onVirtualTour,
    this.onViewingPass,
    this.onLiveTour,
    this.onCopilot,
    this.onHumanWinga,
    this.onApply,
    this.onReport,
  });

  final PropertyListing listing;
  final bool isFavorite;
  final VoidCallback onClose;
  final VoidCallback onFavorite;
  final PropertyNeighborhoodIntel? intelligence;
  final PropertyVisitScore? visitScore;
  final PropertyCommuteEstimate? commute;
  final bool isInCompare;
  final VoidCallback? onToggleCompare;
  final VoidCallback? onVirtualTour;
  final VoidCallback? onViewingPass;
  final VoidCallback? onLiveTour;
  final VoidCallback? onCopilot;
  final VoidCallback? onHumanWinga;
  final VoidCallback? onApply;
  final VoidCallback? onReport;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final photos = listing.media.where((m) => m.kind == 'photo').toList();
    final videos = listing.media.where((m) => m.kind == 'video').toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.82,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: palette.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(onPressed: onClose, icon: const Icon(LucideIcons.x)),
              Expanded(
                child: Text(
                  listing.title,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onToggleCompare != null)
                IconButton(
                  onPressed: onToggleCompare,
                  icon: Icon(
                    isInCompare ? LucideIcons.arrowLeftRight : LucideIcons.arrowLeftRight,
                    color: TaifaColors.gold400,
                  ),
                ),
              IconButton(
                onPressed: onFavorite,
                icon: Icon(
                  isFavorite ? LucideIcons.heart : LucideIcons.heart,
                  color: TaifaColors.gold400,
                ),
              ),
            ],
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                TaifaSpacing.screenH,
                0,
                TaifaSpacing.screenH,
                TaifaSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (listing.primaryPhotoUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        listing.primaryPhotoUrl,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 12),
                  if (visitScore != null) _VisitScoreBanner(score: visitScore!),
                  Text(
                    listing.price.format(),
                    style: const TextStyle(
                      color: TaifaColors.gold400,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    listing.locationLabel,
                    style: TextStyle(color: palette.textMuted),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${listing.beds} beds · ${listing.baths} baths · ${listing.areaSqm} sqm',
                    style: TextStyle(color: palette.textPrimary),
                  ),
                  if (commute != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(LucideIcons.bus, size: 18, color: TaifaColors.gold400),
                        const SizedBox(width: 6),
                        Text(
                          '${commute!.durationLabel} to CBD · ${(commute!.distanceMeters / 1000).toStringAsFixed(1)} km',
                          style: TextStyle(color: palette.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (onVirtualTour != null)
                        ActionChip(
                          avatar: const Icon(LucideIcons.box, size: 18),
                          label: const Text('Virtual tour'),
                          onPressed: onVirtualTour,
                        ),
                      if (onViewingPass != null)
                        ActionChip(
                          avatar: Icon(
                            listing.isUnlocked ? LucideIcons.lockOpen : LucideIcons.lock,
                            size: 18,
                          ),
                          label: Text(listing.isUnlocked ? 'Unlocked' : 'Viewing Pass'),
                          onPressed: onViewingPass,
                        ),
                      if (onLiveTour != null)
                        ActionChip(
                          avatar: const Icon(LucideIcons.video, size: 18),
                          label: const Text('Live tour'),
                          onPressed: onLiveTour,
                        ),
                      if (onCopilot != null)
                        ActionChip(
                          avatar: const Icon(LucideIcons.brain, size: 18),
                          label: const Text('Ask AI'),
                          onPressed: onCopilot,
                        ),
                      if (onHumanWinga != null)
                        ActionChip(
                          avatar: const Icon(LucideIcons.headset, size: 18),
                          label: const Text('Human Winga'),
                          onPressed: onHumanWinga,
                        ),
                      if (onApply != null && listing.transactionType == 'rent')
                        ActionChip(
                          avatar: const Icon(LucideIcons.clipboardList, size: 18),
                          label: const Text('Apply & lease'),
                          onPressed: onApply,
                        ),
                      if (onReport != null)
                        ActionChip(
                          avatar: const Icon(LucideIcons.flag, size: 18),
                          label: const Text('Report'),
                          onPressed: onReport,
                        ),
                    ],
                  ),
                  if (!listing.isUnlocked)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Exact address and owner contact require a Viewing Pass.',
                        style: TextStyle(color: palette.textMuted, fontSize: 12),
                      ),
                    )
                  else if (listing.addressLine.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(listing.addressLine, style: TextStyle(color: palette.textPrimary)),
                    if (listing.ownerPhone.isNotEmpty)
                      Text('Owner: ${listing.ownerPhone}', style: TextStyle(color: palette.textMuted, fontSize: 12)),
                  ],
                  if (listing.isVerified)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(LucideIcons.badgeCheck, color: TaifaColors.emerald700, size: 18),
                          SizedBox(width: 4),
                          Text(
                            'Taifa verified listing',
                            style: TextStyle(
                              color: TaifaColors.emerald700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (intelligence != null) ...[
                    const SizedBox(height: 16),
                    _NeighborhoodPanel(intel: intelligence!),
                  ],
                  const SizedBox(height: 12),
                  Text(listing.description, style: TextStyle(color: palette.textPrimary)),
                  if (photos.length > 1) ...[
                    const SizedBox(height: 16),
                    Text('Photos', style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: photos.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (_, i) => ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(photos[i].url, width: 100, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                  ],
                  if (videos.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text('Video tour', style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    ListTile(
                      leading: const Icon(LucideIcons.circlePlay, color: TaifaColors.gold400),
                      title: Text(videos.first.caption.isEmpty ? 'Property walkthrough' : videos.first.caption),
                      subtitle: const Text('Tap to play in browser'),
                      onTap: () {},
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitScoreBanner extends StatelessWidget {
  const _VisitScoreBanner({required this.score});

  final PropertyVisitScore score;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TaifaColors.gold500.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TaifaColors.gold500.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Visit decision', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < score.stars ? LucideIcons.star : LucideIcons.star,
                    color: TaifaColors.gold400,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(score.label, style: TextStyle(color: palette.textPrimary, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _NeighborhoodPanel extends StatelessWidget {
  const _NeighborhoodPanel({required this.intel});

  final PropertyNeighborhoodIntel intel;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Neighborhood intelligence',
            style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w700),
          ),
          Text(
            intel.lifestyle.replaceAll('_', ' '),
            style: TextStyle(color: palette.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _scoreChip('Safety', intel.safetyScoreE4),
              _scoreChip('Walk', intel.walkabilityE4),
              _scoreChip('Water', intel.waterReliabilityE4),
              _scoreChip('Power', intel.powerReliabilityE4),
            ],
          ),
          const SizedBox(height: 10),
          Text('Nearby', style: TextStyle(color: palette.textMuted, fontSize: 12)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: intel.nearby.entries
                .map((e) => Chip(
                      label: Text('${e.key.replaceAll('_', ' ')}: ${e.value}', style: const TextStyle(fontSize: 10)),
                      visualDensity: VisualDensity.compact,
                    ))
                .toList(),
          ),
          if (intel.nearestStation.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Mobility: ${intel.nearestStation}'
                '${intel.stationDistanceMeters != null ? ' (${intel.stationDistanceMeters}m)' : ''}',
                style: TextStyle(color: palette.textMuted, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }

  Widget _scoreChip(String label, int e4) {
    return Chip(
      label: Text('$label ${e4 ~/ 100}%', style: const TextStyle(fontSize: 11)),
      visualDensity: VisualDensity.compact,
    );
  }
}

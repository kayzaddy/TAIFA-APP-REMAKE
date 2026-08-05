import 'package:flutter/material.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../../../app/theme/taifa_theme.dart';
import '../../wallet/domain/currency.dart';
import '../../wallet/domain/money.dart';
import '../domain/property_models.dart';

class PropertyExperienceSheet extends StatelessWidget {
  const PropertyExperienceSheet({
    super.key,
    required this.experience,
    required this.onClose,
  });

  final PropertyExperience experience;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(onPressed: onClose, icon: const Icon(Icons.close_rounded)),
              Expanded(
                child: Text(
                  'Virtual property tour',
                  style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w700),
                ),
              ),
              if (experience.vrReady)
                const Chip(
                  label: Text('360° ready', style: TextStyle(fontSize: 10)),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(TaifaSpacing.screenH),
              children: [
                if (experience.videoTours.isNotEmpty) ...[
                  Text('Video tour', style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  ...experience.videoTours.map(
                    (v) => ListTile(
                      leading: const Icon(Icons.play_circle_fill_rounded, color: TaifaColors.gold400),
                      title: Text(v.caption.isEmpty ? 'Property video tour' : v.caption),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text('Room-by-room walkthrough', style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                ...experience.walkthrough.map((room) => _RoomCard(room: room)),
                if (experience.floorPlans.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Floor plan', style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  ...experience.floorPlans.map(
                    (fp) => ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(fp.url, height: 180, width: double.infinity, fit: BoxFit.cover),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({required this.room});

  final PropertyWalkthroughRoom room;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final photo = room.media.isNotEmpty ? room.media.first : null;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: palette.surfaceAlt,
      child: ListTile(
        leading: photo == null
            ? const Icon(Icons.meeting_room_outlined)
            : ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(photo.url, width: 56, height: 56, fit: BoxFit.cover),
              ),
        title: Text(room.label, style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w600)),
        subtitle: Text('${room.media.length} photos', style: TextStyle(color: palette.textMuted, fontSize: 12)),
      ),
    );
  }
}

class PropertyViewingPassSheet extends StatelessWidget {
  const PropertyViewingPassSheet({
    super.key,
    required this.plans,
    required this.isUnlocked,
    required this.onClose,
    required this.onPurchase,
  });

  final List<ViewingPassPlan> plans;
  final bool isUnlocked;
  final VoidCallback onClose;
  final void Function(String planCode) onPurchase;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return Container(
      padding: const EdgeInsets.all(TaifaSpacing.screenH),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(onPressed: onClose, icon: const Icon(Icons.close_rounded)),
              Expanded(
                child: Text(
                  'Viewing Pass',
                  style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w700, fontSize: 18),
                ),
              ),
            ],
          ),
          if (isUnlocked)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(Icons.lock_open_rounded, color: TaifaColors.emerald700),
                  SizedBox(width: 8),
                  Text('Address, navigation & contact unlocked', style: TextStyle(color: TaifaColors.emerald700)),
                ],
              ),
            )
          else
            Text(
              'Unlock exact address, navigation, owner contact, and scheduling.',
              style: TextStyle(color: palette.textMuted),
            ),
          const SizedBox(height: 8),
          ...plans.map((plan) {
            final price = Money(plan.amountMinor, Currency.fromCode(plan.currency));
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(plan.name, style: TextStyle(fontWeight: FontWeight.w700, color: palette.textPrimary)),
                subtitle: Text(plan.description),
                trailing: FilledButton(
                  onPressed: isUnlocked ? null : () => onPurchase(plan.code),
                  child: Text(price.format()),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class PropertyLiveSessionSheet extends StatelessWidget {
  const PropertyLiveSessionSheet({
    super.key,
    required this.session,
    required this.onClose,
    required this.onEnd,
  });

  final PropertyLiveSession session;
  final VoidCallback onClose;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final ended = session.status == 'ended';
    return Container(
      padding: const EdgeInsets.all(TaifaSpacing.screenH),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(onPressed: onClose, icon: const Icon(Icons.close_rounded)),
              Expanded(
                child: Text(
                  'Live property mode',
                  style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w700),
                ),
              ),
              if (session.isLive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('LIVE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800)),
                ),
            ],
          ),
          Text(session.listingTitle, style: TextStyle(color: palette.textMuted)),
          const SizedBox(height: 12),
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: palette.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  ended ? Icons.video_library_rounded : Icons.videocam_rounded,
                  size: 48,
                  color: TaifaColors.gold400,
                ),
                const SizedBox(height: 8),
                Text(
                  ended ? 'Recording available' : 'Owner live walkthrough',
                  style: TextStyle(color: palette.textPrimary),
                ),
                Text('Join code: ${session.joinCode}', style: TextStyle(color: palette.textMuted, fontSize: 12)),
              ],
            ),
          ),
          if (ended && session.aiTranscriptSummary.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('AI transcript', style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w700)),
            Text(session.aiTranscriptSummary, style: TextStyle(color: palette.textMuted)),
          ],
          const SizedBox(height: 12),
          if (!ended)
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onEnd,
                child: const Text('End live tour'),
              ),
            ),
        ],
      ),
    );
  }
}

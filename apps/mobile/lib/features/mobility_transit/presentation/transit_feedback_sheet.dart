import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../../../app/theme/taifa_theme.dart';
import '../application/transit_providers.dart';

Future<void> showTransitFeedbackSheet(
  BuildContext context, {
  String? routeId,
  String? ticketId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.taifa.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: _TransitFeedbackSheet(routeId: routeId, ticketId: ticketId),
    ),
  );
}

class _TransitFeedbackSheet extends ConsumerStatefulWidget {
  const _TransitFeedbackSheet({this.routeId, this.ticketId});

  final String? routeId;
  final String? ticketId;

  @override
  ConsumerState<_TransitFeedbackSheet> createState() => _TransitFeedbackSheetState();
}

class _TransitFeedbackSheetState extends ConsumerState<_TransitFeedbackSheet> {
  var _rating = 4;
  final _commentCtrl = TextEditingController();
  final _selectedTags = <String>{};

  static const _tags = ['on_time', 'clean', 'safe', 'crowded', 'helpful_staff'];

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final engagement = ref.watch(transitEngagementControllerProvider);
    final ctrl = ref.read(transitEngagementControllerProvider.notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TaifaSpacing.screenH,
        TaifaSpacing.md,
        TaifaSpacing.screenH,
        TaifaSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rate your ride',
            style: TextStyle(
              color: palette.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final star = i + 1;
              return IconButton(
                onPressed: () => setState(() => _rating = star),
                icon: Icon(
                  star <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: TaifaColors.gold400,
                  size: 32,
                ),
              );
            }),
          ),
          TextField(
            controller: _commentCtrl,
            maxLines: 3,
            style: TextStyle(color: palette.textPrimary),
            decoration: InputDecoration(
              hintText: 'Tell us about your trip (optional)',
              hintStyle: TextStyle(color: palette.textMuted),
              filled: true,
              fillColor: palette.surfaceAlt,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _tags.map((tag) {
              final selected = _selectedTags.contains(tag);
              return FilterChip(
                label: Text(tag.replaceAll('_', ' ')),
                selected: selected,
                onSelected: (v) => setState(() {
                  if (v) {
                    _selectedTags.add(tag);
                  } else {
                    _selectedTags.remove(tag);
                  }
                }),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: engagement.isBusy
                  ? null
                  : () async {
                      final ok = await ctrl.submitFeedback(
                        rating: _rating,
                        comment: _commentCtrl.text.trim(),
                        tags: _selectedTags.toList(),
                        routeId: widget.routeId,
                        ticketId: widget.ticketId,
                      );
                      if (ok && context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Thanks for your feedback!')),
                        );
                      }
                    },
              child: engagement.isBusy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit feedback'),
            ),
          ),
        ],
      ),
    );
  }
}

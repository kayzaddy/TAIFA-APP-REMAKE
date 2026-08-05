import 'package:flutter/material.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../../../app/theme/taifa_theme.dart';
import '../domain/property_models.dart';

class PropertyCompareSheet extends StatelessWidget {
  const PropertyCompareSheet({
    super.key,
    required this.rows,
    required this.onClose,
    required this.onClear,
  });

  final List<PropertyCompareRow> rows;
  final VoidCallback onClose;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
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
              IconButton(onPressed: onClose, icon: const Icon(Icons.close_rounded)),
              Expanded(
                child: Text(
                  'Compare properties',
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(onPressed: onClear, child: const Text('Clear')),
            ],
          ),
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(TaifaSpacing.screenH),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: rows
                    .map((r) => _CompareCard(row: r))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompareCard extends StatelessWidget {
  const _CompareCard({required this.row});

  final PropertyCompareRow row;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
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
            row.title,
            style: TextStyle(
              color: palette.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(row.price.format(), style: const TextStyle(color: TaifaColors.gold400)),
          Text(row.location, style: TextStyle(color: palette.textMuted, fontSize: 11)),
          const SizedBox(height: 8),
          _row('Beds', '${row.beds}'),
          _row('Baths', '${row.baths}'),
          _row('Area', '${row.areaSqm} sqm'),
          _row('Safety', '${row.safetyE4 ~/ 100}%'),
          _row('Walkability', '${row.walkabilityE4 ~/ 100}%'),
          const SizedBox(height: 8),
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                i < row.visitStars ? Icons.star_rounded : Icons.star_border_rounded,
                color: TaifaColors.gold400,
                size: 16,
              ),
            ),
          ),
          Text(row.visitLabel, style: TextStyle(color: palette.textMuted, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11)),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

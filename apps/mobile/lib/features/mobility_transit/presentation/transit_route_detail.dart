import 'package:flutter/material.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../../../app/theme/taifa_theme.dart';
import '../domain/transit_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class TransitRouteDetailSheet extends StatelessWidget {
  const TransitRouteDetailSheet({
    super.key,
    required this.route,
    required this.products,
    required this.selectedProductCode,
    required this.onSelectProduct,
    required this.isBusy,
    required this.onClose,
    required this.onPurchase,
  });

  final TransitRoute route;
  final List<TransitProduct> products;
  final String selectedProductCode;
  final ValueChanged<String> onSelectProduct;
  final bool isBusy;
  final VoidCallback onClose;
  final VoidCallback onPurchase;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final stops = route.stops;
    final selected = products.where((p) => p.code == selectedProductCode).firstOrNull;
    final buyLabel = selected != null
        ? 'Buy ${selected.name} · ${selected.fare.format()}'
        : 'Buy single ride · ${route.fare.format()}';
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.72,
      ),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      decoration: BoxDecoration(
        color: palette.isDark ? const Color(0xF0121412) : palette.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: palette.borderStrong)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: palette.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      route.brand,
                      style: TextStyle(
                        color: TaifaColors.emerald500,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      route.name,
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: Icon(LucideIcons.x, color: palette.textMuted),
              ),
            ],
          ),
          Text(
            '${route.metadata['operator'] ?? 'DART'} · ${stops.length} stops',
            style: TextStyle(color: palette.textMuted, fontSize: 12),
          ),
          const SizedBox(height: TaifaSpacing.md),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: stops.length,
              itemBuilder: (_, i) {
                final stop = stops[i];
                final name = stop['name']?.toString() ?? 'Stop';
                final isFirst = i == 0;
                final isLast = i == stops.length - 1;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isFirst || isLast
                                ? TaifaColors.gold500
                                : TaifaColors.emerald500,
                            border: Border.all(color: palette.background, width: 2),
                          ),
                        ),
                        if (!isLast)
                          Container(
                            width: 2,
                            height: 28,
                            color: palette.border,
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          name,
                          style: TextStyle(
                            color: palette.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          if (route.departures.isNotEmpty) ...[
            Text(
              'Next departures (scheduled)',
              style: TextStyle(
                color: palette.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: route.departures
                  .take(4)
                  .map((d) {
                    final time = d['departure_time']?.toString() ?? '';
                    final label = time.length >= 5 ? time.substring(0, 5) : time;
                    return Chip(
                      label: Text(label),
                      backgroundColor: palette.surfaceAlt,
                    );
                  })
                  .toList(),
            ),
            const SizedBox(height: 12),
          ],
          if (products.isNotEmpty) ...[
            Text(
              'Ticket type',
              style: TextStyle(color: palette.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: products.map((p) {
                final selected = p.code == selectedProductCode;
                return ChoiceChip(
                  selected: selected,
                  label: Text('${p.name} · ${p.fare.format()}'),
                  onSelected: (_) => onSelectProduct(p.code),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: isBusy ? null : onPurchase,
              style: FilledButton.styleFrom(
                backgroundColor: TaifaColors.emerald700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: isBusy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      buyLabel,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../../../app/theme/taifa_theme.dart';
import '../domain/property_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PropertyOpsSheet extends StatelessWidget {
  const PropertyOpsSheet({
    super.key,
    required this.dashboard,
    required this.moderationReports,
    required this.disputes,
    required this.onClose,
    required this.onRefresh,
  });

  final PropertyOpsDashboard? dashboard;
  final List<PropertyModerationReport> moderationReports;
  final List<PropertyDispute> disputes;
  final VoidCallback onClose;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final dash = dashboard;
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
              IconButton(onPressed: onClose, icon: const Icon(LucideIcons.x)),
              Expanded(
                child: Text(
                  'Property Ops',
                  style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(onPressed: onRefresh, icon: const Icon(LucideIcons.refreshCw)),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(TaifaSpacing.screenH),
              children: [
                if (dash != null) ...[
                  Text('Executive dashboard', style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _KpiChip(label: 'Listings', value: '${dash.listingsVerified}/${dash.listingsTotal}'),
                      _KpiChip(label: 'Applications', value: '${dash.applicationsTotal}'),
                      _KpiChip(label: 'Active leases', value: '${dash.leasesActive}'),
                      _KpiChip(label: 'GMV', value: '${dash.gmvMinor ~/ 100} TZS'),
                      _KpiChip(label: 'Disputes', value: '${dash.disputesOpen}'),
                      _KpiChip(label: 'Moderation', value: '${dash.moderationPending}'),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
                Text('Moderation queue', style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                if (moderationReports.isEmpty)
                  Text('No pending reports', style: TextStyle(color: palette.textMuted, fontSize: 12))
                else
                  ...moderationReports.map(
                    (r) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(LucideIcons.flag, color: TaifaColors.gold400, size: 20),
                      title: Text(r.listingTitle, style: const TextStyle(fontSize: 13)),
                      subtitle: Text('${r.reason} · ${r.status}', style: const TextStyle(fontSize: 11)),
                    ),
                  ),
                const SizedBox(height: 16),
                Text('Disputes', style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                if (disputes.isEmpty)
                  Text('No open disputes', style: TextStyle(color: palette.textMuted, fontSize: 12))
                else
                  ...disputes.map(
                    (d) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(LucideIcons.gavel, color: TaifaColors.gold400, size: 20),
                      title: Text(d.reason, style: const TextStyle(fontSize: 13)),
                      subtitle: Text('${d.subjectType} · ${d.status}', style: const TextStyle(fontSize: 11)),
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

class _KpiChip extends StatelessWidget {
  const _KpiChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: palette.textMuted, fontSize: 10)),
          Text(value, style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
        ],
      ),
    );
  }
}

class PropertyReportSheet extends StatelessWidget {
  const PropertyReportSheet({
    super.key,
    required this.onClose,
    required this.onSubmit,
  });

  final VoidCallback onClose;
  final void Function(String reason, String notes) onSubmit;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final notesCtrl = TextEditingController();
    var reason = 'misleading';

    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          padding: const EdgeInsets.all(TaifaSpacing.screenH),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Report listing', style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w700)),
                  ),
                  IconButton(onPressed: onClose, icon: const Icon(LucideIcons.x)),
                ],
              ),
              DropdownButtonFormField<String>(
                initialValue: reason,
                decoration: const InputDecoration(labelText: 'Reason'),
                items: const [
                  DropdownMenuItem(value: 'fraud', child: Text('Fraud')),
                  DropdownMenuItem(value: 'misleading', child: Text('Misleading')),
                  DropdownMenuItem(value: 'duplicate', child: Text('Duplicate')),
                  DropdownMenuItem(value: 'inappropriate', child: Text('Inappropriate')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => reason = v ?? 'misleading'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(labelText: 'Notes (optional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => onSubmit(reason, notesCtrl.text.trim()),
                child: const Text('Submit report'),
              ),
            ],
          ),
        );
      },
    );
  }
}

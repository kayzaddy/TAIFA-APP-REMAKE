import 'package:flutter/material.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../../../app/theme/taifa_theme.dart';
import '../domain/property_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PropertyApplySheet extends StatelessWidget {
  const PropertyApplySheet({
    super.key,
    required this.listing,
    required this.application,
    required this.lease,
    required this.isBusy,
    required this.onClose,
    required this.onStartApplication,
    required this.onSubmit,
    required this.onVerifyIdentity,
    required this.onVerifyIncome,
    required this.onApprove,
    required this.onGenerateLease,
    required this.onSignLease,
    required this.onPayDeposit,
    required this.onCompleteMoveIn,
    required this.onRenewLease,
  });

  final PropertyListing listing;
  final PropertyApplication? application;
  final PropertyLease? lease;
  final bool isBusy;
  final VoidCallback onClose;
  final Future<void> Function({
    required String employmentStatus,
    required int monthlyIncomeMinor,
    required String nationalId,
  }) onStartApplication;
  final VoidCallback onSubmit;
  final VoidCallback onVerifyIdentity;
  final VoidCallback onVerifyIncome;
  final VoidCallback onApprove;
  final VoidCallback onGenerateLease;
  final VoidCallback onSignLease;
  final VoidCallback onPayDeposit;
  final VoidCallback onCompleteMoveIn;
  final VoidCallback onRenewLease;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final employmentCtrl = TextEditingController(text: 'employed');
    final incomeCtrl = TextEditingController(text: (listing.price.minorUnits * 4).toString());
    final nationalIdCtrl = TextEditingController();

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
                  'Apply & lease',
                  style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(TaifaSpacing.screenH),
              children: [
                Text(
                  listing.title,
                  style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w600),
                ),
                Text(
                  'Rent ${listing.price.format()} · Deposit ${listing.deposit.format()}',
                  style: TextStyle(color: palette.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 16),
                if (application == null) ...[
                  TextField(
                    controller: employmentCtrl,
                    decoration: const InputDecoration(labelText: 'Employment status'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: incomeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Monthly income (TZS)'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nationalIdCtrl,
                    decoration: const InputDecoration(labelText: 'National ID (NIDA)'),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: isBusy
                        ? null
                        : () => onStartApplication(
                              employmentStatus: employmentCtrl.text.trim(),
                              monthlyIncomeMinor: int.tryParse(incomeCtrl.text.trim()) ?? 0,
                              nationalId: nationalIdCtrl.text.trim(),
                            ),
                    child: const Text('Start application'),
                  ),
                ] else ...[
                  _StatusRow(label: 'Application', value: application!.status),
                  _VerificationRow(
                    label: 'Identity',
                    verified: application!.identityVerified,
                  ),
                  _VerificationRow(
                    label: 'Income',
                    verified: application!.incomeVerified,
                  ),
                  if (application!.status == 'draft')
                    FilledButton(
                      onPressed: isBusy ? null : onSubmit,
                      child: const Text('Submit application'),
                    ),
                  if (application!.status == 'under_review' && !application!.identityVerified)
                    FilledButton(
                      onPressed: isBusy ? null : onVerifyIdentity,
                      child: const Text('Verify identity'),
                    ),
                  if (application!.status == 'under_review' &&
                      application!.identityVerified &&
                      !application!.incomeVerified)
                    FilledButton(
                      onPressed: isBusy ? null : onVerifyIncome,
                      child: const Text('Verify income'),
                    ),
                  if (application!.readyForApproval && application!.status == 'under_review')
                    FilledButton(
                      onPressed: isBusy ? null : onApprove,
                      child: const Text('Approve application'),
                    ),
                  if (application!.status == 'approved' && lease == null)
                    FilledButton(
                      onPressed: isBusy ? null : onGenerateLease,
                      child: const Text('Generate lease'),
                    ),
                ],
                if (lease != null) ...[
                  const SizedBox(height: 16),
                  Text('Lease', style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w700)),
                  _StatusRow(label: 'Status', value: lease!.status),
                  if (lease!.pendingSignatures)
                    FilledButton(
                      onPressed: isBusy ? null : onSignLease,
                      child: const Text('Sign lease (tenant)'),
                    ),
                  if (lease!.isActive) ...[
                    ...lease!.payments.where((p) => p.isPending).map(
                          (p) => ListTile(
                            title: Text('Pay ${p.kind.replaceAll('_', ' ')}'),
                            subtitle: Text(p.amount.format()),
                            trailing: FilledButton(
                              onPressed: isBusy || p.kind != 'deposit' ? null : onPayDeposit,
                              child: const Text('Pay'),
                            ),
                          ),
                        ),
                    if (lease!.moveWorkflows.any((w) => w.status != 'completed'))
                      FilledButton(
                        onPressed: isBusy ? null : onCompleteMoveIn,
                        child: const Text('Complete move-in checklist'),
                      ),
                    OutlinedButton(
                      onPressed: isBusy ? null : onRenewLease,
                      child: const Text('Renew lease'),
                    ),
                  ],
                  if (lease!.contractText.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      lease!.contractText,
                      style: TextStyle(color: palette.textMuted, fontSize: 11),
                      maxLines: 8,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text('$label: ', style: TextStyle(color: palette.textMuted)),
          Text(value.replaceAll('_', ' '), style: TextStyle(color: palette.textPrimary)),
        ],
      ),
    );
  }
}

class _VerificationRow extends StatelessWidget {
  const _VerificationRow({required this.label, required this.verified});

  final String label;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        verified ? LucideIcons.badgeCheck : LucideIcons.hourglass,
        color: verified ? TaifaColors.emerald700 : TaifaColors.gold400,
        size: 20,
      ),
      title: Text(label),
      trailing: Text(verified ? 'Verified' : 'Pending'),
    );
  }
}

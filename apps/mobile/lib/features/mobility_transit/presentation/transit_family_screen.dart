import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../../../app/theme/taifa_theme.dart';
import '../application/transit_providers.dart';
import '../domain/transit_models.dart';

class TransitFamilyScreen extends ConsumerStatefulWidget {
  const TransitFamilyScreen({super.key});

  @override
  ConsumerState<TransitFamilyScreen> createState() => _TransitFamilyScreenState();
}

class _TransitFamilyScreenState extends ConsumerState<TransitFamilyScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transitFamilyControllerProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transitFamilyControllerProvider);
    final ctrl = ref.read(transitFamilyControllerProvider.notifier);
    final palette = context.taifa;
    final bundle = state.bundle;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family tickets'),
        actions: [
          IconButton(
            tooltip: 'Add member',
            onPressed: state.isBusy ? null : () => _showAddMemberDialog(context, ctrl),
            icon: const Icon(Icons.person_add_alt_1_rounded),
          ),
        ],
      ),
      body: state.isBusy && bundle == null
          ? const Center(child: CircularProgressIndicator(color: TaifaColors.gold400))
          : RefreshIndicator(
              color: TaifaColors.gold400,
              onRefresh: ctrl.load,
              child: ListView(
                padding: const EdgeInsets.all(TaifaSpacing.screenH),
                children: [
                  Text(
                    'Buy Mwendokasi tickets for children and dependents. Charges go to your Taifa Wallet.',
                    style: TextStyle(color: palette.textMuted, fontSize: 13),
                  ),
                  if (state.message != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      state.message!,
                      style: TextStyle(color: TaifaColors.emerald500, fontSize: 12),
                    ),
                  ],
                  if (state.error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      state.error!,
                      style: TextStyle(color: palette.accent, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: TaifaSpacing.md),
                  Text(
                    'Linked members',
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (bundle == null || bundle.members.isEmpty)
                    _EmptyMembersCard(
                      onAdd: () => _showAddMemberDialog(context, ctrl),
                    )
                  else
                    ...bundle.members.map(
                      (m) => _MemberCard(
                        member: m,
                        isBusy: state.isBusy,
                        onBuy: () => _showPurchaseDialog(
                          context,
                          ref,
                          ctrl,
                          member: m,
                          products: state.products,
                          routeId: state.defaultRouteId,
                        ),
                        onRemove: () => _confirmRemove(context, ctrl, m),
                      ),
                    ),
                  if (bundle != null && bundle.tickets.isNotEmpty) ...[
                    const SizedBox(height: TaifaSpacing.lg),
                    Text(
                      'Recent family tickets',
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...bundle.tickets.map((t) => _FamilyTicketTile(ticket: t)),
                  ],
                ],
              ),
            ),
    );
  }

  Future<void> _showAddMemberDialog(
    BuildContext context,
    TransitFamilyController ctrl,
  ) async {
    final ownerCtrl = TextEditingController(text: 'device:child-demo');
    final nameCtrl = TextEditingController(text: 'Amina');
    final limitCtrl = TextEditingController(text: '50000');
    var relationship = 'child';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final palette = ctx.taifa;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Link family member'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: ownerCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Member device ID',
                      hintText: 'device:…',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Display name'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: relationship,
                    decoration: const InputDecoration(labelText: 'Relationship'),
                    items: const [
                      DropdownMenuItem(value: 'child', child: Text('Child')),
                      DropdownMenuItem(value: 'spouse', child: Text('Spouse')),
                      DropdownMenuItem(value: 'parent', child: Text('Parent')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (v) => setState(() => relationship = v ?? 'child'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: limitCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Monthly limit (TZS, 0 = none)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use the dependent\'s Taifa device owner ID from their profile.',
                    style: TextStyle(color: palette.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Link'),
              ),
            ],
          ),
        );
      },
    );
    if (ok != true || !context.mounted) return;
    final limitTzs = int.tryParse(limitCtrl.text.trim()) ?? 0;
    await ctrl.addMember(
      memberOwner: ownerCtrl.text.trim(),
      displayName: nameCtrl.text.trim(),
      relationship: relationship,
      monthlyLimitMinor: limitTzs * 100,
    );
  }

  Future<void> _showPurchaseDialog(
    BuildContext context,
    WidgetRef ref,
    TransitFamilyController ctrl, {
    required TransitFamilyMember member,
    required List<TransitProduct> products,
    required String routeId,
  }) async {
    if (routeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No BRT route available')),
      );
      return;
    }
    final productCode = products.isNotEmpty
        ? products.first.code
        : 'brt-single';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Buy ticket for ${member.displayName}'),
        content: Text(
          products.isNotEmpty
              ? 'Purchase ${products.first.name} (${products.first.fare.format()}) from your wallet?'
              : 'Purchase a single BRT ride (TZS 650) from your wallet?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Buy ticket'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final ticket = await ctrl.purchaseForMember(
      member: member,
      routeId: routeId,
      productCode: productCode,
      originStop: 'kimara',
      destinationStop: 'kivukoni',
    );
    if (ticket != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ticket ${ticket.mediaCode} ready for ${member.displayName}')),
      );
    }
  }

  Future<void> _confirmRemove(
    BuildContext context,
    TransitFamilyController ctrl,
    TransitFamilyMember member,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove member?'),
        content: Text('${member.displayName} will no longer appear in your family list.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok == true) await ctrl.removeMember(member.id);
  }
}

class _EmptyMembersCard extends StatelessWidget {
  const _EmptyMembersCard({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          Icon(Icons.family_restroom_rounded, size: 40, color: palette.textMuted),
          const SizedBox(height: 8),
          Text(
            'No linked members yet',
            style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Link a child or dependent to buy tickets on their behalf.',
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
            label: const Text('Add member'),
          ),
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.isBusy,
    required this.onBuy,
    required this.onRemove,
  });

  final TransitFamilyMember member;
  final bool isBusy;
  final VoidCallback onBuy;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final limitLabel = member.hasLimit
        ? '${member.spentThisMonth.format()} / ${member.monthlyLimit.format()} this month'
        : '${member.spentThisMonth.format()} spent this month';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: TaifaColors.emerald900,
                child: Text(
                  member.displayName.isNotEmpty
                      ? member.displayName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(color: TaifaColors.gold400),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.displayName,
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${member.relationship} · ${member.activeTickets} active',
                      style: TextStyle(color: palette.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Remove',
                onPressed: isBusy ? null : onRemove,
                icon: Icon(Icons.close_rounded, color: palette.textMuted, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(limitLabel, style: TextStyle(color: palette.textMuted, fontSize: 12)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isBusy || !member.canPurchase ? null : onBuy,
              icon: const Icon(Icons.confirmation_number_outlined, size: 18),
              label: const Text('Buy ticket'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FamilyTicketTile extends StatelessWidget {
  const _FamilyTicketTile({required this.ticket});
  final TransitTicket ticket;

  @override
  Widget build(BuildContext context) {
    final label = ticket.beneficiaryDisplayName.isNotEmpty
        ? ticket.beneficiaryDisplayName
        : 'Family member';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TaifaColors.emerald900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.qr_code_2_rounded, color: TaifaColors.gold400),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  ticket.routeName.isNotEmpty ? ticket.routeName : ticket.mediaCode,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            ticket.status.toUpperCase(),
            style: const TextStyle(
              color: TaifaColors.gold400,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

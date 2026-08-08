import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/taifa_colors.dart';
import '../../../../app/theme/taifa_dimens.dart';
import '../../../../app/theme/taifa_icons.dart';
import '../../../../app/theme/taifa_theme.dart';
import '../../../../data/dto/social_dto.dart';
import '../../application/social_providers.dart';
import '../../application/wallet_providers.dart';
import '../../domain/currency.dart';
import '../../domain/money.dart';
import '../../../../shared/widgets/taifa_skeleton.dart';
import '../../../../shared/widgets/taifa_stagger.dart';
import 'social_widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MoneyRequestsScreen extends ConsumerStatefulWidget {
  const MoneyRequestsScreen({super.key});

  @override
  ConsumerState<MoneyRequestsScreen> createState() => _MoneyRequestsScreenState();
}

class _MoneyRequestsScreenState extends ConsumerState<MoneyRequestsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final requestsAsync = ref.watch(moneyRequestsProvider);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: TaifaSpacing.screenH),
          child: Column(
            children: [
              const SizedBox(height: TaifaSpacing.sm),
              SocialScreenHeader(
                title: 'Money Requests',
                trailing: IconButton(
                  icon: const Icon(LucideIcons.circlePlus),
                  onPressed: () => _createRequest(context),
                ),
              ),
              const SizedBox(height: TaifaSpacing.md),
              TabBar(
                controller: _tabs,
                labelColor: palette.accent,
                unselectedLabelColor: palette.textMuted,
                indicatorColor: palette.accent,
                tabs: const [Tab(text: 'Received'), Tab(text: 'Sent')],
              ),
              const SizedBox(height: TaifaSpacing.sm),
              Expanded(
                child: requestsAsync.when(
                  loading: () => const TaifaSkeletonList(),
                  error: (e, _) => Center(child: Text('Could not load requests.\n$e', textAlign: TextAlign.center)),
                  data: (data) => TabBarView(
                    controller: _tabs,
                    children: [
                      _RequestList(requests: data.received, isReceived: true),
                      _RequestList(requests: data.sent, isReceived: false),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createRequest(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.taifa.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(TaifaRadii.nav))),
      builder: (_) => const _CreateRequestSheet(),
    );
    if (result == true) ref.invalidate(moneyRequestsProvider);
  }
}

class _RequestList extends ConsumerWidget {
  const _RequestList({required this.requests, required this.isReceived});
  final List<MoneyRequest> requests;
  final bool isReceived;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (requests.isEmpty) {
      return SocialEmptyState(
        icon: TaifaIcons.moneyRequest,
        title: isReceived ? 'Nothing to pay' : 'No requests sent',
        message: isReceived
            ? 'When someone asks you for money, it lands here.'
            : 'Ask a friend to settle up — they get a notification and can '
                  'pay in one tap.',
      );
    }
    return ListView.separated(
      itemCount: requests.length,
      separatorBuilder: (_, _) => const SizedBox(height: TaifaSpacing.sm),
      itemBuilder: (_, i) => TaifaStaggerIn(
        index: i,
        child: _RequestTile(request: requests[i], isReceived: isReceived),
      ),
    );
  }
}

class _RequestTile extends ConsumerStatefulWidget {
  const _RequestTile({required this.request, required this.isReceived});
  final MoneyRequest request;
  final bool isReceived;

  @override
  ConsumerState<_RequestTile> createState() => _RequestTileState();
}

class _RequestTileState extends ConsumerState<_RequestTile> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final r = widget.request;
    final who = widget.isReceived ? r.requesterName : r.payerName;
    return SocialCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(r.emoji.isEmpty ? '💰' : r.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: TaifaSpacing.sm),
              Expanded(
                child: Text(
                  who.isEmpty ? (widget.isReceived ? r.requester : r.payer) : who,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.textPrimary),
                ),
              ),
              Text(r.amount.format(), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.textPrimary)),
            ],
          ),
          if (r.note.isNotEmpty) ...[
            const SizedBox(height: TaifaSpacing.xxs),
            Text(r.note, style: TextStyle(fontSize: 11, color: palette.textMuted)),
          ],
          const SizedBox(height: TaifaSpacing.sm),
          Row(
            children: [
              _StatusLabel(status: r.status),
              const Spacer(),
              if (r.status == MoneyRequestStatus.pending) ...[
                if (widget.isReceived) ...[
                  TextButton(
                    onPressed: _busy ? null : _decline,
                    child: Text('Decline', style: TextStyle(fontSize: 11, color: palette.textMuted)),
                  ),
                  TextButton(
                    onPressed: _busy ? null : _pay,
                    child: _busy
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text('Pay', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: palette.accent)),
                  ),
                ] else
                  TextButton(
                    onPressed: _busy ? null : _cancel,
                    child: Text('Cancel', style: TextStyle(fontSize: 11, color: palette.textMuted)),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pay() async {
    setState(() => _busy = true);
    try {
      await ref.read(socialRepositoryProvider).payRequest(widget.request.id);
      ref.invalidate(moneyRequestsProvider);
      ref.invalidate(walletControllerProvider);
      if (mounted) showSocialSuccess(context, 'Paid ${widget.request.amount.format()}.');
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showSocialError(context, e);
      }
    }
  }

  Future<void> _decline() async {
    setState(() => _busy = true);
    try {
      await ref.read(socialRepositoryProvider).declineRequest(widget.request.id);
      ref.invalidate(moneyRequestsProvider);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showSocialError(context, e);
      }
    }
  }

  Future<void> _cancel() async {
    setState(() => _busy = true);
    try {
      await ref.read(socialRepositoryProvider).cancelRequest(widget.request.id);
      ref.invalidate(moneyRequestsProvider);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showSocialError(context, e);
      }
    }
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.status});
  final MoneyRequestStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      MoneyRequestStatus.pending => ('Pending', TaifaColors.gold500),
      MoneyRequestStatus.paid => ('Paid', TaifaColors.emerald500),
      MoneyRequestStatus.declined => ('Declined', TaifaColors.danger),
      MoneyRequestStatus.cancelled => ('Cancelled', context.taifa.textMuted),
      MoneyRequestStatus.expired => ('Expired', context.taifa.textMuted),
    };
    return Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color));
  }
}

class _CreateRequestSheet extends ConsumerStatefulWidget {
  const _CreateRequestSheet();

  @override
  ConsumerState<_CreateRequestSheet> createState() => _CreateRequestSheetState();
}

class _CreateRequestSheetState extends ConsumerState<_CreateRequestSheet> {
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return Padding(
      padding: EdgeInsets.only(
        left: TaifaSpacing.screenH,
        right: TaifaSpacing.screenH,
        top: TaifaSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + TaifaSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Request money', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: palette.textPrimary)),
          const SizedBox(height: TaifaSpacing.lg),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: TextStyle(color: palette.textPrimary),
            decoration: const InputDecoration(labelText: 'Their phone number', hintText: '+255...'),
          ),
          const SizedBox(height: TaifaSpacing.sm),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(color: palette.textPrimary),
            decoration: const InputDecoration(labelText: 'Amount (TSh)'),
          ),
          const SizedBox(height: TaifaSpacing.sm),
          TextField(
            controller: _noteController,
            style: TextStyle(color: palette.textPrimary),
            decoration: const InputDecoration(labelText: 'Note (optional)'),
          ),
          const SizedBox(height: TaifaSpacing.md),
          SocialPrimaryButton(label: 'Send request', loading: _saving, onTap: _submit),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final phone = _phoneController.text.trim();
    final major = int.tryParse(_amountController.text);
    if (phone.isEmpty || major == null || major <= 0) {
      showSocialError(context, Exception('Enter a phone number and a valid amount.'));
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(socialRepositoryProvider).createRequest(
        payerPhone: phone,
        amount: Money.major(major, Currency.tzs),
        note: _noteController.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showSocialError(context, e);
      }
    }
  }
}

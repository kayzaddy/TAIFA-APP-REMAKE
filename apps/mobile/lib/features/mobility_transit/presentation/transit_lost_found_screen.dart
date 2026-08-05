import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../../../app/theme/taifa_theme.dart';
import '../application/transit_providers.dart';
import '../domain/transit_models.dart';

class TransitLostFoundScreen extends ConsumerStatefulWidget {
  const TransitLostFoundScreen({super.key});

  @override
  ConsumerState<TransitLostFoundScreen> createState() => _TransitLostFoundScreenState();
}

class _TransitLostFoundScreenState extends ConsumerState<TransitLostFoundScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transitLostFoundControllerProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transitLostFoundControllerProvider);
    final ctrl = ref.read(transitLostFoundControllerProvider.notifier);
    final palette = context.taifa;
    final bundle = state.bundle;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lost & found'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Browse'),
            Tab(text: 'My reports'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Filter',
            onSelected: (value) {
              if (value == 'all') {
                ctrl.load(kind: '', stopCode: '');
              } else if (value == 'found') {
                ctrl.load(kind: 'found');
              } else if (value == 'lost') {
                ctrl.load(kind: 'lost');
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'all', child: Text('All items')),
              PopupMenuItem(value: 'found', child: Text('Found only')),
              PopupMenuItem(value: 'lost', child: Text('Lost only')),
            ],
            icon: const Icon(Icons.filter_list_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: state.isBusy ? null : () => _showReportSheet(context, ctrl),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Report'),
      ),
      body: state.isBusy && bundle == null
          ? const Center(child: CircularProgressIndicator(color: TaifaColors.gold400))
          : Column(
              children: [
                if (state.message != null)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      state.message!,
                      style: TextStyle(color: TaifaColors.emerald500, fontSize: 12),
                    ),
                  ),
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      state.error!,
                      style: TextStyle(color: palette.accent, fontSize: 12),
                    ),
                  ),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      RefreshIndicator(
                        color: TaifaColors.gold400,
                        onRefresh: () => ctrl.load(),
                        child: _ItemList(
                          items: bundle?.openItems ?? const [],
                          emptyLabel: 'No open lost or found reports.',
                          onClaim: (item) => _claimItem(context, ctrl, item),
                        ),
                      ),
                      RefreshIndicator(
                        color: TaifaColors.gold400,
                        onRefresh: () => ctrl.load(),
                        child: ListView(
                          padding: const EdgeInsets.all(TaifaSpacing.screenH),
                          children: [
                            Text(
                              'Your reports',
                              style: TextStyle(
                                color: palette.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if ((bundle?.myReports ?? []).isEmpty)
                              Text(
                                'You have not submitted any reports yet.',
                                style: TextStyle(color: palette.textMuted, fontSize: 12),
                              )
                            else
                              ...bundle!.myReports.map(
                                (item) => _LostFoundCard(
                                  item: item,
                                  onResolve: item.status == 'claimed'
                                      ? () => ctrl.resolve(item.id)
                                      : null,
                                ),
                              ),
                            const SizedBox(height: TaifaSpacing.lg),
                            Text(
                              'Your claims',
                              style: TextStyle(
                                color: palette.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if ((bundle?.myClaims ?? []).isEmpty)
                              Text(
                                'No claims yet.',
                                style: TextStyle(color: palette.textMuted, fontSize: 12),
                              )
                            else
                              ...bundle!.myClaims.map(
                                (item) => _LostFoundCard(item: item),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _showReportSheet(
    BuildContext context,
    TransitLostFoundController ctrl,
  ) async {
    var kind = 'lost';
    var category = 'other';
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final stopCtrl = TextEditingController(text: 'ubungo');
    List<int>? photoBytes;
    var photoName = '';

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final palette = ctx.taifa;
        return Padding(
          padding: EdgeInsets.only(
            left: TaifaSpacing.screenH,
            right: TaifaSpacing.screenH,
            top: TaifaSpacing.md,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + TaifaSpacing.md,
          ),
          child: StatefulBuilder(
            builder: (context, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Report item',
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'lost', label: Text('I lost')),
                    ButtonSegment(value: 'found', label: Text('I found')),
                  ],
                  selected: {kind},
                  onSelectionChanged: (v) => setState(() => kind = v.first),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: const [
                    DropdownMenuItem(value: 'phone', child: Text('Phone')),
                    DropdownMenuItem(value: 'wallet', child: Text('Wallet')),
                    DropdownMenuItem(value: 'bag', child: Text('Bag')),
                    DropdownMenuItem(value: 'id_card', child: Text('ID card')),
                    DropdownMenuItem(value: 'keys', child: Text('Keys')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (v) => setState(() => category = v ?? 'other'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: stopCtrl,
                  decoration: const InputDecoration(labelText: 'Station code'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await FilePicker.pickFiles(
                      type: FileType.image,
                      withData: true,
                    );
                    if (picked != null && picked.files.single.bytes != null) {
                      setState(() {
                        photoBytes = picked.files.single.bytes!;
                        photoName = picked.files.single.name;
                      });
                    }
                  },
                  icon: const Icon(Icons.photo_camera_outlined, size: 18),
                  label: Text(photoName.isEmpty ? 'Add photo' : photoName),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Submit report'),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (ok != true || !context.mounted) return;
    var photoUrl = '';
    if (photoBytes != null) {
      photoUrl = await ref.read(transitLostFoundControllerProvider.notifier).uploadPhoto(photoBytes!);
    }
    await ctrl.report(
      kind: kind,
      title: titleCtrl.text.trim(),
      description: descCtrl.text.trim(),
      category: category,
      stopCode: stopCtrl.text.trim(),
      photoUrl: photoUrl,
    );
  }

  Future<void> _claimItem(
    BuildContext context,
    TransitLostFoundController ctrl,
    TransitLostFoundItem item,
  ) async {
    final messageCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Claim ${item.title}?'),
        content: TextField(
          controller: messageCtrl,
          decoration: const InputDecoration(
            labelText: 'Message to finder (optional)',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Submit claim'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ctrl.claim(item.id, message: messageCtrl.text.trim());
    }
  }
}

class _ItemList extends StatelessWidget {
  const _ItemList({
    required this.items,
    required this.emptyLabel,
    this.onClaim,
  });

  final List<TransitLostFoundItem> items;
  final String emptyLabel;
  final void Function(TransitLostFoundItem item)? onClaim;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Center(child: Text(emptyLabel)),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(TaifaSpacing.screenH),
      itemCount: items.length,
      itemBuilder: (_, i) => _LostFoundCard(
        item: items[i],
        onClaim: items[i].isFound && items[i].isOpen ? () => onClaim?.call(items[i]) : null,
      ),
    );
  }
}

class _LostFoundCard extends StatelessWidget {
  const _LostFoundCard({
    required this.item,
    this.onClaim,
    this.onResolve,
  });

  final TransitLostFoundItem item;
  final VoidCallback? onClaim;
  final VoidCallback? onResolve;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final kindColor = item.isFound ? TaifaColors.ocean400 : Colors.orange;

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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: kindColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.kind.toUpperCase(),
                  style: TextStyle(
                    color: kindColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                item.category.replaceAll('_', ' '),
                style: TextStyle(color: palette.textMuted, fontSize: 11),
              ),
              const Spacer(),
              Text(
                item.status.toUpperCase(),
                style: TextStyle(
                  color: palette.textMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.title,
            style: TextStyle(
              color: palette.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (item.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              item.description,
              style: TextStyle(color: palette.textMuted, fontSize: 12),
            ),
          ],
          if (item.stopCode.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.place_rounded, size: 14, color: palette.textMuted),
                const SizedBox(width: 4),
                Text(
                  item.stopCode,
                  style: TextStyle(color: palette.textMuted, fontSize: 11),
                ),
              ],
            ),
          ],
          if (onClaim != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onClaim,
                child: const Text('This might be mine'),
              ),
            ),
          ],
          if (onResolve != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onResolve,
                child: const Text('Confirm handoff'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

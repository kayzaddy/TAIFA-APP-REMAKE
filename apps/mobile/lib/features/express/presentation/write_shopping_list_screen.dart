import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/taifa_dimens.dart';
import '../application/express_providers.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Dedicated Smart Shopping List editor — not the AI assistant.
class WriteShoppingListScreen extends ConsumerStatefulWidget {
  const WriteShoppingListScreen({super.key});

  @override
  ConsumerState<WriteShoppingListScreen> createState() =>
      _WriteShoppingListScreenState();
}

class _WriteShoppingListScreenState extends ConsumerState<WriteShoppingListScreen> {
  late final TextEditingController _list;

  @override
  void initState() {
    super.initState();
    _list = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _list.text = ref.read(expressControllerProvider).listText;
    });
  }

  @override
  void dispose() {
    _list.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) return;
    final current = _list.text.trim();
    final next = current.isEmpty ? text : '$current\n$text';
    _list.text = next;
    ref.read(expressControllerProvider.notifier).setListText(next);
  }

  Future<void> _addToBasket() async {
    final ctrl = ref.read(expressControllerProvider.notifier);
    ctrl.setListText(_list.text);
    final ok = await ctrl.parseListToBasket();
    if (!mounted) return;
    if (ok) {
      context.push('/express/basket');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expressControllerProvider);
    final ctrl = ref.read(expressControllerProvider.notifier);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Write Shopping List'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/express');
            }
          },
        ),
        actions: [
          TextButton(onPressed: _paste, child: const Text('Paste')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(TaifaSpacing.screenH),
        children: [
          Text(
            'One product per line',
            style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Type or paste your list. Express matches nearby inventory — no one-by-one search.',
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: TaifaSpacing.lg),
          Text('Templates', style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final name in ExpressController.templates.keys)
                ActionChip(
                  label: Text(name),
                  onPressed: () {
                    ctrl.applyTemplate(name);
                    _list.text = ref.read(expressControllerProvider).listText;
                  },
                ),
            ],
          ),
          const SizedBox(height: TaifaSpacing.md),
          Text('Quick add', style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final chip in ExpressController.quickChips)
                ActionChip(
                  label: Text(chip),
                  onPressed: () {
                    ctrl.appendChip(chip);
                    _list.text = ref.read(expressControllerProvider).listText;
                    _list.selection = TextSelection.collapsed(offset: _list.text.length);
                  },
                ),
            ],
          ),
          const SizedBox(height: TaifaSpacing.lg),
          TextField(
            controller: _list,
            minLines: 12,
            maxLines: 24,
            textInputAction: TextInputAction.newline,
            keyboardType: TextInputType.multiline,
            decoration: const InputDecoration(
              alignLabelWithHint: true,
              labelText: 'What do you need today?',
              hintText: 'Milk\nBread\nEggs\nRice\nCooking Oil',
              border: OutlineInputBorder(),
            ),
            onChanged: ctrl.setListText,
          ),
          const SizedBox(height: TaifaSpacing.sm),
          Text(
            'Tip: “2 Milk”, “Milk x2”, “Two Milk”, “Milk 2L” all work.',
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          if (state.error != null) ...[
            const SizedBox(height: TaifaSpacing.sm),
            Text(state.error!, style: text.bodyMedium?.copyWith(color: scheme.error)),
          ],
          if (state.message != null) ...[
            const SizedBox(height: TaifaSpacing.sm),
            Text(state.message!, style: text.bodyMedium),
          ],
          const SizedBox(height: TaifaSpacing.lg),
          FilledButton.icon(
            onPressed: state.isBusy ? null : _addToBasket,
            icon: state.isBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.listChecks),
            label: Text(state.isBusy ? 'Matching…' : 'Add To Basket'),
          ),
        ],
      ),
    );
  }
}

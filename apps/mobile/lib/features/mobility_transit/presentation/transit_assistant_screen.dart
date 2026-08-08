import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../../../app/theme/taifa_theme.dart';
import '../application/transit_providers.dart';
import '../domain/transit_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class TransitAssistantScreen extends ConsumerStatefulWidget {
  const TransitAssistantScreen({super.key});

  @override
  ConsumerState<TransitAssistantScreen> createState() => _TransitAssistantScreenState();
}

class _TransitAssistantScreenState extends ConsumerState<TransitAssistantScreen> {
  final _inputCtrl = TextEditingController();

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  void _handleAction(TransitAssistantAction action) {
    switch (action.action) {
      case 'open_planner':
        ref.read(transitControllerProvider.notifier)
          ..setPlanStops(
            origin: action.originStop,
            destination: action.destinationStop,
          )
          ..runPlanner();
        context.push('/mobility/transit/plan');
      case 'buy_ticket':
        if (action.routeId.isNotEmpty) {
          ref.read(transitControllerProvider.notifier).openRoute(action.routeId);
        }
        context.push('/mobility/transit');
      case 'open_station':
        if (action.stopCode.isNotEmpty) {
          context.push('/mobility/transit/station/${action.stopCode}');
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transitAssistantControllerProvider);
    final ctrl = ref.read(transitAssistantControllerProvider.notifier);
    final palette = context.taifa;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mwendokasi AI'),
        actions: [
          PopupMenuButton<String>(
            initialValue: state.locale,
            onSelected: ctrl.setLocale,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'sw', child: Text('Kiswahili')),
              PopupMenuItem(value: 'en', child: Text('English')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(child: Text(state.locale.toUpperCase())),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TaifaSpacing.screenH,
              TaifaSpacing.sm,
              TaifaSpacing.screenH,
              0,
            ),
            child: Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('Kimara → Kivukoni'),
                  onPressed: state.isBusy ? null : () => ctrl.ask('kutoka kimara hadi kivukoni'),
                ),
                ActionChip(
                  label: const Text('Ubungo station'),
                  onPressed: state.isBusy ? null : () => ctrl.ask('search station ubungo'),
                ),
                ActionChip(
                  label: const Text('Nenda kazini'),
                  onPressed: state.isBusy ? null : () => ctrl.ask('nataka kwenda kazini'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(TaifaSpacing.screenH),
              itemCount: state.messages.length,
              itemBuilder: (_, i) {
                final msg = state.messages[i];
                return _MessageBubble(message: msg, palette: palette, onAction: _handleAction);
              },
            ),
          ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: TaifaSpacing.screenH),
              child: Text(state.error!, style: TextStyle(color: palette.accent, fontSize: 12)),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                TaifaSpacing.screenH,
                8,
                TaifaSpacing.screenH,
                TaifaSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      enabled: !state.isBusy,
                      decoration: InputDecoration(
                        hintText: state.locale == 'sw'
                            ? 'Andika swali lako...'
                            : 'Ask your travel question...',
                      ),
                      onSubmitted: (v) {
                        ctrl.ask(v);
                        _inputCtrl.clear();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: state.isBusy
                        ? null
                        : () {
                            ctrl.ask(_inputCtrl.text);
                            _inputCtrl.clear();
                          },
                    icon: state.isBusy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(LucideIcons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.palette,
    required this.onAction,
  });

  final TransitAssistantMessage message;
  final TaifaPalette palette;
  final void Function(TransitAssistantAction action) onAction;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final reply = message.reply;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
        decoration: BoxDecoration(
          color: isUser ? TaifaColors.emerald900 : palette.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isUser ? Colors.transparent : palette.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isUser ? Colors.white : palette.textPrimary,
                fontSize: 14,
              ),
            ),
            if (reply != null && reply.plans.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final plan in reply.plans.take(2))
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• ${plan.routeName} — ${plan.durationMinutes} min · ${plan.fare.format()}',
                    style: TextStyle(color: palette.textMuted, fontSize: 12),
                  ),
                ),
            ],
            if (reply != null && reply.suggestedActions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: reply.suggestedActions
                    .map(
                      (action) => ActionChip(
                        label: Text(action.label),
                        onPressed: () => onAction(action),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

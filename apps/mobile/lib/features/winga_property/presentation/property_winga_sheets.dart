import 'package:flutter/material.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../../../app/theme/taifa_theme.dart';
import '../domain/property_models.dart';

class PropertyCopilotSheet extends StatefulWidget {
  const PropertyCopilotSheet({
    super.key,
    required this.messages,
    required this.onClose,
    required this.onAsk,
  });

  final List<String> messages;
  final VoidCallback onClose;
  final Future<void> Function(String query) onAsk;

  @override
  State<PropertyCopilotSheet> createState() => _PropertyCopilotSheetState();
}

class _PropertyCopilotSheetState extends State<PropertyCopilotSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.6,
      padding: const EdgeInsets.all(TaifaSpacing.screenH),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(onPressed: widget.onClose, icon: const Icon(Icons.close_rounded)),
              const Icon(Icons.psychology_rounded, color: TaifaColors.gold400),
              const SizedBox(width: 8),
              Text('Property Copilot', style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w700)),
            ],
          ),
          Text('AI handles discovery — never authorizes payments.', style: TextStyle(color: palette.textMuted, fontSize: 12)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: widget.messages.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(widget.messages[i], style: TextStyle(color: palette.textPrimary)),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  decoration: const InputDecoration(hintText: 'Ask about this property…'),
                  onSubmitted: (v) async {
                    await widget.onAsk(v);
                    _ctrl.clear();
                  },
                ),
              ),
              IconButton(
                onPressed: () async {
                  await widget.onAsk(_ctrl.text);
                  _ctrl.clear();
                },
                icon: const Icon(Icons.send_rounded, color: TaifaColors.gold400),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PropertyHumanWingaSheet extends StatefulWidget {
  const PropertyHumanWingaSheet({
    super.key,
    required this.assignment,
    required this.messages,
    required this.onClose,
    required this.onSend,
  });

  final PropertyWingaAssignment assignment;
  final List<PropertySecureChatMessage> messages;
  final VoidCallback onClose;
  final Future<void> Function(String text) onSend;

  @override
  State<PropertyHumanWingaSheet> createState() => _PropertyHumanWingaSheetState();
}

class _PropertyHumanWingaSheetState extends State<PropertyHumanWingaSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final w = widget.assignment.winga;
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.65,
      padding: const EdgeInsets.all(TaifaSpacing.screenH),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(onPressed: widget.onClose, icon: const Icon(Icons.close_rounded)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(w.displayName, style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w700)),
                    Text(w.certification, style: TextStyle(color: palette.textMuted, fontSize: 11)),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < w.trustStars ? Icons.star_rounded : Icons.star_border_rounded,
                    color: TaifaColors.gold400,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.messages.length,
              itemBuilder: (_, i) {
                final m = widget.messages[i];
                return Align(
                  alignment: m.isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: m.isMe
                          ? TaifaColors.gold500.withValues(alpha: 0.15)
                          : palette.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(m.text, style: TextStyle(color: palette.textPrimary)),
                  ),
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  decoration: const InputDecoration(hintText: 'Message your Winga…'),
                  onSubmitted: (v) async {
                    await widget.onSend(v);
                    _ctrl.clear();
                  },
                ),
              ),
              IconButton(
                onPressed: () async {
                  await widget.onSend(_ctrl.text);
                  _ctrl.clear();
                },
                icon: const Icon(Icons.send_rounded, color: TaifaColors.gold400),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

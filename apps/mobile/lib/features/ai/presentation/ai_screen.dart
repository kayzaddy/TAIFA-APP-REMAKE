import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../../../app/theme/taifa_theme.dart';
import '../../../app/theme/taifa_typography.dart';
import '../../../shared/widgets/taifa_logo.dart';
import '../application/ai_providers.dart';
import '../domain/ai_models.dart';

/// TAIFA AI — Demo Complete chat on a mock LLM gateway.
class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: TaifaMotion.base,
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiControllerProvider);
    final ctrl = ref.read(aiControllerProvider.notifier);
    final palette = context.taifa;
    ref.listen(aiControllerProvider, (_, next) => _scrollToEnd());

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 4),
              child: Row(
                children: [
                  const TaifaLogo(variant: TaifaLogoVariant.mark, size: 34),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'TAIFA AI',
                      style: TaifaTypography.sectionTitle(
                        palette.textPrimary,
                      ).copyWith(fontSize: 20),
                    ),
                  ),
                  IconButton(
                    tooltip: 'New chat',
                    onPressed: ctrl.clearChat,
                    icon: Icon(Icons.refresh_rounded, color: palette.textMuted),
                  ),
                ],
              ),
            ),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  state.error!,
                  style: const TextStyle(
                    color: Color(0xFFFF8A80),
                    fontSize: 12,
                  ),
                ),
              ),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                itemCount: state.messages.length + (state.isTyping ? 1 : 0),
                itemBuilder: (_, i) {
                  if (i == state.messages.length) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          'TAIFA is typing…',
                          style: TextStyle(
                            color: palette.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  }
                  final m = state.messages[i];
                  final isUser = m.role == ChatRole.user;
                  return Align(
                    alignment: isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.sizeOf(context).width * 0.82,
                      ),
                      decoration: BoxDecoration(
                        color: isUser
                            ? TaifaColors.emerald700
                            : palette.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        m.text,
                        style: TextStyle(
                          color: isUser ? Colors.white : palette.textPrimary,
                          height: 1.4,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final s in AiController.suggestions)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(
                          s.label,
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: state.isTyping
                            ? null
                            : () => ctrl.send(s.prompt),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) {
                        final t = _input.text;
                        _input.clear();
                        ctrl.send(t);
                      },
                      decoration: InputDecoration(
                        hintText: 'Ask in Kiswahili or English…',
                        filled: true,
                        fillColor: palette.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: state.isTyping
                        ? null
                        : () {
                            final t = _input.text;
                            _input.clear();
                            ctrl.send(t);
                          },
                    style: IconButton.styleFrom(
                      backgroundColor: TaifaColors.emerald700,
                    ),
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

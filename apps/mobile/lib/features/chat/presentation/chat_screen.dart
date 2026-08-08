import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../../../app/theme/taifa_theme.dart';
import '../../../app/theme/taifa_typography.dart';
import '../../../shared/widgets/taifa_logo.dart';
import '../application/chat_providers.dart';
import '../domain/chat_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatControllerProvider.notifier).bootstrap();
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatControllerProvider);
    final ctrl = ref.read(chatControllerProvider.notifier);
    final palette = context.taifa;
    ref.listen(chatControllerProvider, (_, next) {
      if (next.phase == ChatPhase.thread) _scrollEnd();
    });

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (state.phase == ChatPhase.thread) {
                        ctrl.backInbox();
                      } else if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/menu');
                      }
                    },
                    icon: Icon(
                      LucideIcons.arrowLeft,
                      color: palette.textPrimary,
                    ),
                  ),
                  const TaifaLogo(variant: TaifaLogoVariant.mark, size: 32),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.phase == ChatPhase.thread
                          ? (state.activeThread?.title ?? 'Chat')
                          : 'Chat',
                      style: TaifaTypography.sectionTitle(
                        palette.textPrimary,
                      ).copyWith(fontSize: 18),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: TaifaMotion.base,
                child: state.phase == ChatPhase.thread
                    ? _Thread(
                        key: const ValueKey('t'),
                        state: state,
                        scroll: _scroll,
                      )
                    : _Inbox(
                        key: const ValueKey('i'),
                        state: state,
                        ctrl: ctrl,
                      ),
              ),
            ),
            if (state.phase == ChatPhase.thread)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        decoration: InputDecoration(
                          hintText: 'Message…',
                          filled: true,
                          fillColor: palette.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (v) {
                          _input.clear();
                          ctrl.send(v);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: () {
                        final v = _input.text;
                        _input.clear();
                        ctrl.send(v);
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: TaifaColors.emerald700,
                      ),
                      icon: const Icon(LucideIcons.send),
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

class _Inbox extends StatelessWidget {
  const _Inbox({super.key, required this.state, required this.ctrl});
  final ChatUiState state;
  final ChatController ctrl;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    if (state.isBusy && state.threads.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: state.threads.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final t = state.threads[i];
        return Material(
          color: palette.surface,
          borderRadius: BorderRadius.circular(14),
          child: ListTile(
            onTap: () => ctrl.open(t),
            leading: CircleAvatar(
              backgroundColor: TaifaColors.emerald700.withValues(alpha: 0.2),
              child: Icon(
                LucideIcons.messageCircle,
                color: TaifaColors.emerald700,
              ),
            ),
            title: Text(
              t.title,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: palette.textPrimary,
              ),
            ),
            subtitle: Text(
              t.subtitle,
              style: TextStyle(color: palette.textMuted, fontSize: 12),
              maxLines: 1,
            ),
            trailing: t.unread > 0
                ? CircleAvatar(
                    radius: 11,
                    backgroundColor: TaifaColors.emerald700,
                    child: Text(
                      '${t.unread}',
                      style: const TextStyle(fontSize: 11, color: Colors.white),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}

class _Thread extends StatelessWidget {
  const _Thread({super.key, required this.state, required this.scroll});
  final ChatUiState state;
  final ScrollController scroll;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return ListView.builder(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      itemCount: state.messages.length,
      itemBuilder: (_, i) {
        final m = state.messages[i];
        final mine = m.sender == ChatSender.me;
        return Align(
          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.78,
            ),
            decoration: BoxDecoration(
              color: mine ? TaifaColors.emerald700 : palette.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              m.text,
              style: TextStyle(
                color: mine ? Colors.white : palette.textPrimary,
                height: 1.35,
              ),
            ),
          ),
        );
      },
    );
  }
}

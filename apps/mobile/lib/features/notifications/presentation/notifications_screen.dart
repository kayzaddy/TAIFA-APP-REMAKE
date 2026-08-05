import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_theme.dart';
import '../../../app/theme/taifa_typography.dart';
import '../../../shared/widgets/taifa_logo.dart';
import '../application/notification_providers.dart';
import '../domain/notification_models.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsControllerProvider.notifier).bootstrap();
    });
  }

  IconData _icon(NotifKind k) => switch (k) {
    NotifKind.ride => Icons.local_taxi_rounded,
    NotifKind.food => Icons.restaurant_rounded,
    NotifKind.payment => Icons.payments_rounded,
    NotifKind.system => Icons.info_outline_rounded,
    NotifKind.promo => Icons.local_offer_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsControllerProvider);
    final ctrl = ref.read(notificationsControllerProvider.notifier);
    final palette = context.taifa;

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
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/home');
                      }
                    },
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: palette.textPrimary,
                    ),
                  ),
                  const TaifaLogo(variant: TaifaLogoVariant.mark, size: 32),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Notifications',
                      style: TaifaTypography.sectionTitle(
                        palette.textPrimary,
                      ).copyWith(fontSize: 18),
                    ),
                  ),
                  TextButton(
                    onPressed: state.unreadCount == 0 ? null : ctrl.markAll,
                    child: const Text('Mark all read'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: state.isBusy && state.items.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: state.items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final n = state.items[i];
                        return Material(
                          color: n.read
                              ? palette.surface
                              : TaifaColors.emerald500.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          child: ListTile(
                            onTap: () => ctrl.open(n.id),
                            leading: Icon(
                              _icon(n.kind),
                              color: TaifaColors.emerald700,
                            ),
                            title: Text(
                              n.title,
                              style: TextStyle(
                                fontWeight: n.read
                                    ? FontWeight.w600
                                    : FontWeight.w800,
                                color: palette.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              n.body,
                              style: TextStyle(
                                color: palette.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

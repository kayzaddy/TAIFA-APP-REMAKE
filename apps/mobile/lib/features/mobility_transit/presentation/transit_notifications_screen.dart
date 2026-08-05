import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../../../app/theme/taifa_theme.dart';
import '../application/transit_providers.dart';
import '../domain/transit_models.dart';

class TransitNotificationsScreen extends ConsumerStatefulWidget {
  const TransitNotificationsScreen({super.key});

  @override
  ConsumerState<TransitNotificationsScreen> createState() =>
      _TransitNotificationsScreenState();
}

class _TransitNotificationsScreenState extends ConsumerState<TransitNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transitEngagementControllerProvider.notifier).loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transitEngagementControllerProvider);
    final ctrl = ref.read(transitEngagementControllerProvider.notifier);
    final palette = context.taifa;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: ctrl.markAllRead,
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: state.isBusy && state.notifications.isEmpty
          ? const Center(child: CircularProgressIndicator(color: TaifaColors.gold400))
          : state.notifications.isEmpty
              ? Center(
                  child: Text(
                    'No transit notifications yet.',
                    style: TextStyle(color: palette.textMuted),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(TaifaSpacing.screenH),
                  itemCount: state.notifications.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _NotificationTile(
                    notification: state.notifications[i],
                    palette: palette,
                  ),
                ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.palette});

  final TransitNotification notification;
  final TaifaPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: notification.read ? palette.surfaceAlt : TaifaColors.emerald900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.read
              ? palette.border
              : TaifaColors.gold500.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  notification.title,
                  style: TextStyle(
                    color: notification.read ? palette.textPrimary : Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              if (!notification.read)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: TaifaColors.gold400,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            notification.body,
            style: TextStyle(
              color: notification.read
                  ? palette.textMuted
                  : Colors.white.withValues(alpha: 0.85),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

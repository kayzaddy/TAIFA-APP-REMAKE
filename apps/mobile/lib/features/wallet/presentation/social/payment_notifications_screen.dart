import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/taifa_colors.dart';
import '../../../../app/theme/taifa_dimens.dart';
import '../../../../app/theme/taifa_icons.dart';
import '../../../../app/theme/taifa_theme.dart';
import '../../../../data/dto/social_dto.dart';
import '../../application/social_providers.dart';
import '../../../../shared/widgets/taifa_skeleton.dart';
import '../../../../shared/widgets/taifa_stagger.dart';
import 'social_widgets.dart';

/// The wallet/payments notification inbox — deliberately named
/// `PaymentNotificationsScreen` (not `NotificationsScreen`) since a generic
/// `features/notifications/` screen already exists for other domains.
class PaymentNotificationsScreen extends ConsumerWidget {
  const PaymentNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(notificationsProvider);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: TaifaSpacing.screenH),
          child: Column(
            children: [
              const SizedBox(height: TaifaSpacing.sm),
              const SocialScreenHeader(title: 'Notifications'),
              const SizedBox(height: TaifaSpacing.lg),
              Expanded(
                child: asyncData.when(
                  loading: () => const TaifaSkeletonList(),
                  error: (e, _) => Center(child: Text('Could not load notifications.\n$e', textAlign: TextAlign.center)),
                  data: (data) => data.notifications.isEmpty
                      ? const SocialEmptyState(
                          icon: TaifaIcons.notifications,
                          title: 'All caught up',
                          message:
                              'Money requests, bill shares and link payments '
                              'will show up here.',
                        )
                      : RefreshIndicator(
                          onRefresh: () async => ref.invalidate(notificationsProvider),
                          child: ListView.separated(
                            itemCount: data.notifications.length,
                            separatorBuilder: (_, _) => const SizedBox(height: TaifaSpacing.sm),
                            itemBuilder: (_, i) => TaifaStaggerIn(
                              index: i,
                              child: _NotificationTile(notification: data.notifications[i]),
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification});
  final TaifaNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.taifa;
    return SocialCard(
      onTap: notification.read
          ? null
          : () async {
              try {
                await ref.read(socialRepositoryProvider).markNotificationRead(notification.id);
                ref.invalidate(notificationsProvider);
              } catch (e) {
                if (context.mounted) showSocialError(context, e);
              }
            },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!notification.read)
            Container(
              margin: const EdgeInsets.only(top: 4, right: TaifaSpacing.sm),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: TaifaColors.gold500),
            )
          else
            const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: notification.read ? FontWeight.w500 : FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(notification.body, style: TextStyle(fontSize: 11, color: palette.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

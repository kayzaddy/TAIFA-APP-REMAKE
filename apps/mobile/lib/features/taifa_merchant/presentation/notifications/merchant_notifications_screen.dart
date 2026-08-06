import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/merchant_api_client.dart';
import '../../data/models/merchant_workspace_models.dart';

class MerchantNotificationsScreen extends ConsumerStatefulWidget {
  const MerchantNotificationsScreen({super.key});

  @override
  ConsumerState<MerchantNotificationsScreen> createState() => _MerchantNotificationsScreenState();
}

class _MerchantNotificationsScreenState extends ConsumerState<MerchantNotificationsScreen> {
  late Future<List<MerchantNotificationItem>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = ref.read(merchantApiClientProvider).listNotifications().then(
          (list) => list
              .map((e) => MerchantNotificationItem.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: FutureBuilder<List<MerchantNotificationItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return const Center(child: Text('No notifications'));
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) {
              final n = items[i];
              return ListTile(
                title: Text(n.title),
                subtitle: Text(n.body),
                trailing: n.isRead ? null : const Icon(Icons.fiber_new, color: Colors.orange),
                onTap: () async {
                  await ref.read(merchantApiClientProvider).markNotificationRead(n.id);
                  _reload();
                  setState(() {});
                },
              );
            },
          );
        },
      ),
    );
  }
}

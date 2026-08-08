import 'package:flutter/material.dart';

class MerchantPlaceholderCard extends StatelessWidget {
  const MerchantPlaceholderCard({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: ListTile(
        enabled: false,
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.lock_clock),
      ),
    );
  }
}

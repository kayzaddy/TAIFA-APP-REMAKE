import 'package:flutter/widgets.dart';

/// A single service entry in the Home services grid.
@immutable
class ServiceItem {
  const ServiceItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.tint,
    required this.route,
  });

  final String id;
  final String label;
  final IconData icon;
  final Color tint;
  final String route;
}

/// A wallet action shown in the quick-actions row.
@immutable
class QuickAction {
  const QuickAction({
    required this.id,
    required this.label,
    required this.icon,
  });
  final String id;
  final String label;
  final IconData icon;
}

/// Snapshot of the user's primary wallet, formatted for display.
@immutable
class WalletSummary {
  const WalletSummary({
    required this.greetingName,
    required this.balanceLabel,
    required this.secondaryLabel,
    required this.maskedNumber,
  });

  final String greetingName;
  final String balanceLabel;
  final String secondaryLabel;
  final String maskedNumber;
}

/// A merchandising offer surfaced on Home.
@immutable
class PromoOffer {
  const PromoOffer({
    required this.title,
    required this.subtitle,
    required this.badge,
  });
  final String title;
  final String subtitle;
  final String badge;
}

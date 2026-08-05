/// Resolves Taifa QR / deep-link payloads to existing app routes.
/// No payment processing — routing only.
class QrResolveResult {
  const QrResolveResult({
    required this.route,
    required this.label,
    this.detail = '',
    this.kind = QrKind.unknown,
  });

  final String route;
  final String label;
  final String detail;
  final QrKind kind;
}

enum QrKind {
  payment,
  mobility,
  booking,
  identity,
  government,
  delivery,
  invoice,
  unknown,
}

class QrResolver {
  const QrResolver();

  QrResolveResult resolve(String raw) {
    final input = raw.trim();
    if (input.isEmpty) {
      return const QrResolveResult(
        route: '/scan',
        label: 'Empty code',
        detail: 'Paste or scan a Taifa QR payload',
      );
    }

    final lower = input.toLowerCase();

    // MAP payment QR: taifa://pay/{merchant}?q=...&i=pi_...
    if (lower.startsWith('taifa://pay/') || lower.contains('taifa://pay/')) {
      final uri = Uri.tryParse(input.contains('://') ? input : 'taifa://pay/$input');
      final intent = uri?.queryParameters['i'] ?? uri?.queryParameters['q'] ?? '';
      if (intent.startsWith('pi_')) {
        return QrResolveResult(
          route: '/map/pay',
          label: 'Pay merchant',
          detail: 'Intent $intent',
          kind: QrKind.payment,
        );
      }
      if (intent.isNotEmpty) {
        // Static merchant QR / link token — open pay with token prefilled via query
        return QrResolveResult(
          route: '/map/pay/$intent',
          label: 'Merchant acceptance',
          detail: intent,
          kind: QrKind.payment,
        );
      }
      return const QrResolveResult(
        route: '/map/pay',
        label: 'Merchant pay',
        detail: 'Open MAP customer pay',
        kind: QrKind.payment,
      );
    }

    // Receipt verification
    if (lower.startsWith('taifa://receipt/')) {
      return const QrResolveResult(
        route: '/wallet',
        label: 'Receipt',
        detail: 'Open wallet history',
        kind: QrKind.payment,
      );
    }

    // Intent / link tokens pasted bare
    if (input.startsWith('pi_') || input.startsWith('pl_') || input.length >= 12) {
      if (input.startsWith('pi_') || !input.contains('://')) {
        return QrResolveResult(
          route: '/map/pay/$input',
          label: 'Pay code',
          detail: input,
          kind: QrKind.payment,
        );
      }
    }

    if (lower.contains('ride') || lower.contains('trip') || lower.startsWith('taifa://ride')) {
      return const QrResolveResult(
        route: '/mobility',
        label: 'Ride',
        detail: 'Open mobility',
        kind: QrKind.mobility,
      );
    }

    if (lower.contains('delivery') || lower.startsWith('taifa://delivery')) {
      return const QrResolveResult(
        route: '/mobility',
        label: 'Delivery',
        detail: 'Open mobility delivery',
        kind: QrKind.delivery,
      );
    }

    if (lower.contains('hotel') || lower.contains('booking') || lower.startsWith('taifa://book')) {
      return const QrResolveResult(
        route: '/stays',
        label: 'Booking',
        detail: 'Open hotels / stays',
        kind: QrKind.booking,
      );
    }

    if (lower.contains('gov') || lower.startsWith('taifa://gov')) {
      return const QrResolveResult(
        route: '/gov',
        label: 'Government',
        detail: 'Open government services',
        kind: QrKind.government,
      );
    }

    if (lower.contains('id') || lower.startsWith('taifa://id')) {
      return const QrResolveResult(
        route: '/profile',
        label: 'Identity',
        detail: 'Open profile',
        kind: QrKind.identity,
      );
    }

    if (lower.contains('invoice') || lower.startsWith('inv_')) {
      return QrResolveResult(
        route: '/map/pay/$input',
        label: 'Invoice',
        detail: input,
        kind: QrKind.invoice,
      );
    }

    // Fallback: universal search with the raw text
    return QrResolveResult(
      route: '/search?q=${Uri.encodeComponent(input)}',
      label: 'Search',
      detail: 'No QR match — search ecosystem',
      kind: QrKind.unknown,
    );
  }
}

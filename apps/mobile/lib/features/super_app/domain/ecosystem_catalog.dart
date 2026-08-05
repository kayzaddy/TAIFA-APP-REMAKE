/// Ecosystem feature catalog — orchestration only; routes to existing modules.
class EcosystemEntry {
  const EcosystemEntry({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.category,
    required this.keywords,
    this.iconName = 'apps',
  });

  final String id;
  final String title;
  final String subtitle;
  final String route;
  final String category;
  final List<String> keywords;
  final String iconName;
}

/// Static discovery index for universal search. No new backend.
class EcosystemCatalog {
  const EcosystemCatalog._();

  static const entries = <EcosystemEntry>[
    EcosystemEntry(
      id: 'wallet',
      title: 'Wallet',
      subtitle: 'Balances · send · top up · history',
      route: '/wallet',
      category: 'Pay',
      keywords: ['wallet', 'pesa', 'balance', 'money', 'malipo'],
    ),
    EcosystemEntry(
      id: 'pay',
      title: 'Universal Pay',
      subtitle: 'QR · links · invoices · transfers',
      route: '/pay',
      category: 'Pay',
      keywords: ['pay', 'payment', 'lipa', 'qr', 'invoice', 'bill'],
    ),
    EcosystemEntry(
      id: 'tap',
      title: 'Tap & Pay',
      subtitle: 'NFC contactless wallet pay',
      route: '/tap',
      category: 'Pay',
      keywords: ['tap', 'nfc', 'contactless', 'softpos', 'pos', 'biometric'],
    ),
    EcosystemEntry(
      id: 'express',
      title: 'Taifa Express',
      subtitle: 'Write a list · delivered in minutes',
      route: '/express/list',
      category: 'Shop',
      keywords: [
        'express',
        'grocery',
        'shopping list',
        'delivery',
        'milk',
        'bread',
        'pharmacy',
        'hyperlocal',
        'instant',
      ],
      iconName: 'bolt',
    ),
    EcosystemEntry(
      id: 'map',
      title: 'Accept / MAP',
      subtitle: 'Merchant QR · payment links',
      route: '/map',
      category: 'Pay',
      keywords: ['merchant', 'accept', 'map', 'qr', 'invoice', 'checkout'],
    ),
    EcosystemEntry(
      id: 'send',
      title: 'Send money',
      subtitle: 'Peer-to-peer transfer',
      route: '/wallet/send',
      category: 'Pay',
      keywords: ['send', 'transfer', 'p2p', 'tuma'],
    ),
    EcosystemEntry(
      id: 'topup',
      title: 'Top up',
      subtitle: 'Mobile money STK',
      route: '/wallet/topup',
      category: 'Pay',
      keywords: ['topup', 'top up', 'mpesa', 'stk', 'ongeza'],
    ),
    EcosystemEntry(
      id: 'scan',
      title: 'Scan QR',
      subtitle: 'Universal scanner',
      route: '/scan',
      category: 'Pay',
      keywords: ['scan', 'scanner', 'code'],
    ),
    EcosystemEntry(
      id: 'ride',
      title: 'Ride',
      subtitle: 'Book a trip',
      route: '/mobility',
      category: 'Mobility',
      keywords: ['ride', 'taxi', 'boda', 'trip', 'mobility', 'safari'],
    ),
    EcosystemEntry(
      id: 'driver',
      title: 'Driver',
      subtitle: 'Driver mode',
      route: '/driver',
      category: 'Mobility',
      keywords: ['driver', 'dereva'],
    ),
    EcosystemEntry(
      id: 'food',
      title: 'Food',
      subtitle: 'Restaurants · delivery',
      route: '/food',
      category: 'Commerce',
      keywords: ['food', 'restaurant', 'chakula', 'delivery', 'meal'],
    ),
    EcosystemEntry(
      id: 'commerce',
      title: 'Commerce MOS',
      subtitle: 'Merchant operating system',
      route: '/commerce',
      category: 'Commerce',
      keywords: ['commerce', 'shop', 'pos', 'store', 'duka'],
    ),
    EcosystemEntry(
      id: 'winga',
      title: 'Winga',
      subtitle: 'Marketplace · brokers',
      route: '/winga',
      category: 'Winga',
      keywords: ['winga', 'broker', 'marketplace', 'hotel deal', 'opportunity'],
    ),
    EcosystemEntry(
      id: 'hotels',
      title: 'Hotels',
      subtitle: 'Stays · bookings',
      route: '/stays',
      category: 'Bookings',
      keywords: ['hotel', 'stay', 'hoteli', 'booking', 'room'],
    ),
    EcosystemEntry(
      id: 'flights',
      title: 'Flights',
      subtitle: 'Tickets · PNR',
      route: '/flights',
      category: 'Bookings',
      keywords: ['flight', 'ndege', 'ticket', 'airport'],
    ),
    EcosystemEntry(
      id: 'tourism',
      title: 'Tourism',
      subtitle: 'Experiences · safari',
      route: '/tourism',
      category: 'Bookings',
      keywords: ['tour', 'tourism', 'safari', 'serengeti', 'reef'],
    ),
    EcosystemEntry(
      id: 'gov',
      title: 'Government',
      subtitle: 'Huduma · requests',
      route: '/gov',
      category: 'Services',
      keywords: ['gov', 'government', 'huduma', 'license', 'permit'],
    ),
    EcosystemEntry(
      id: 'health',
      title: 'Health',
      subtitle: 'Appointments',
      route: '/health',
      category: 'Services',
      keywords: ['health', 'hospital', 'clinic', 'afya', 'doctor'],
    ),
    EcosystemEntry(
      id: 'education',
      title: 'Education',
      subtitle: 'School payments',
      route: '/education',
      category: 'Services',
      keywords: ['education', 'school', 'elimu', 'fees'],
    ),
    EcosystemEntry(
      id: 'jobs',
      title: 'Jobs',
      subtitle: 'Gigs · assignments',
      route: '/jobs',
      category: 'Services',
      keywords: ['job', 'kazi', 'gig', 'work'],
    ),
    EcosystemEntry(
      id: 'housing',
      title: 'Housing',
      subtitle: 'Listings · deposits',
      route: '/housing',
      category: 'Services',
      keywords: ['housing', 'rent', 'nyumba', 'home'],
    ),
    EcosystemEntry(
      id: 'insurance',
      title: 'Insurance',
      subtitle: 'Policies',
      route: '/insurance',
      category: 'Services',
      keywords: ['insurance', 'bima', 'policy'],
    ),
    EcosystemEntry(
      id: 'huduma',
      title: 'Huduma home',
      subtitle: 'Home services',
      route: '/huduma',
      category: 'Services',
      keywords: ['huduma', 'plumber', 'cleaner', 'home service'],
    ),
    EcosystemEntry(
      id: 'ai',
      title: 'AI Assistant',
      subtitle: 'Ask anything — never authorizes payments',
      route: '/ai',
      category: 'Assist',
      keywords: ['ai', 'assistant', 'help', 'msaada', 'chat'],
    ),
    EcosystemEntry(
      id: 'notifications',
      title: 'Notifications',
      subtitle: 'Unified inbox',
      route: '/notifications',
      category: 'Assist',
      keywords: ['notification', 'inbox', 'alert', 'message'],
    ),
    EcosystemEntry(
      id: 'profile',
      title: 'Profile',
      subtitle: 'Identity · preferences',
      route: '/profile',
      category: 'Account',
      keywords: ['profile', 'identity', 'account', 'akaunti'],
    ),
    EcosystemEntry(
      id: 'settings',
      title: 'Settings',
      subtitle: 'Security · language · theme',
      route: '/settings',
      category: 'Account',
      keywords: ['settings', 'security', 'privacy', 'language'],
    ),
    EcosystemEntry(
      id: 'search',
      title: 'Search',
      subtitle: 'Universal discovery',
      route: '/search',
      category: 'Assist',
      keywords: ['search', 'find', 'tafuta'],
    ),
  ];

  static List<EcosystemEntry> search(
    String query, {
    Set<String>? allowedRoutes,
  }) {
    var pool = entries;
    if (allowedRoutes != null && allowedRoutes.isNotEmpty) {
      pool = entries
          .where(
            (e) =>
                allowedRoutes.contains(e.route) ||
                e.route == '/my-services' ||
                e.route == '/menu',
          )
          .toList();
    }
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return pool.take(12).toList();
    final scored = <(int, EcosystemEntry)>[];
    for (final e in pool) {
      var score = 0;
      final title = e.title.toLowerCase();
      final subtitle = e.subtitle.toLowerCase();
      if (title == q) {
        score += 100;
      } else if (title.startsWith(q)) {
        score += 80;
      } else if (title.contains(q)) {
        score += 50;
      }
      if (subtitle.contains(q)) score += 20;
      if (e.category.toLowerCase().contains(q)) score += 15;
      for (final k in e.keywords) {
        if (k == q) {
          score += 90;
        } else if (k.startsWith(q)) {
          score += 60;
        } else if (k.contains(q) || q.contains(k)) {
          score += 30;
        }
      }
      // Natural-language phrases
      if (q.contains('book') && e.category == 'Bookings') score += 40;
      if ((q.contains('pay') || q.contains('lipa')) && e.category == 'Pay') {
        score += 40;
      }
      if (q.contains('ride') && e.id == 'ride') score += 50;
      if (score > 0) scored.add((score, e));
    }
    scored.sort((a, b) => b.$1.compareTo(a.$1));
    return scored.map((e) => e.$2).take(20).toList();
  }
}

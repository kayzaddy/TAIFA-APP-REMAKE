import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/taifa_colors.dart';
import '../../../../app/theme/taifa_dimens.dart';
import '../../application/mos_providers.dart';
import '../widgets/commerce_kit.dart';

/// Role onboarding — first success in minutes.
class CommerceOnboardingScreen extends ConsumerStatefulWidget {
  const CommerceOnboardingScreen({super.key});

  @override
  ConsumerState<CommerceOnboardingScreen> createState() => _CommerceOnboardingScreenState();
}

class _CommerceOnboardingScreenState extends ConsumerState<CommerceOnboardingScreen> {
  int _step = 0;
  String? _role;

  static const _roles = [
    ('Owner', 'merchant', Icons.storefront, '/commerce/desk'),
    ('Cashier', 'pos', Icons.point_of_sale, '/commerce/pos'),
    ('Warehouse', 'warehouse', Icons.warehouse_outlined, '/commerce/warehouse'),
    ('Procurement', 'procurement', Icons.local_shipping_outlined, '/commerce/procurement'),
    ('Manager', 'management', Icons.insights_outlined, '/commerce/management'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Get started'),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(TaifaSpacing.screenH),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MosOrderTimeline(currentIndex: _step),
            const SizedBox(height: TaifaSpacing.xxl),
            Expanded(child: _body()),
            MosNextAction(
              title: _step == 0
                  ? 'Welcome to Taifa Commerce'
                  : _step == 1
                      ? 'Choose your role'
                      : 'You are ready',
              subtitle: _step == 2
                  ? 'Complete your first task in under two minutes'
                  : 'Merchant Operating System for Africa',
              actionLabel: _step < 2 ? 'Continue' : 'Go to workspace',
              onAction: () {
                if (_step < 1) {
                  setState(() => _step = 1);
                } else if (_step == 1) {
                  if (_role == null) return;
                  setState(() => _step = 2);
                } else {
                  ref.read(mosControllerProvider.notifier).completeOnboarding();
                  final route = _roles.firstWhere((r) => r.$2 == _role).$4;
                  context.go(route);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_step == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Run your business', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: TaifaSpacing.md),
          const Text('Sales, stock, suppliers, and settlements — money stays on Taifa Payments.'),
          const SizedBox(height: TaifaSpacing.lg),
          const MosStatusChip('Ledger-backed', tone: MosTone.success),
          const SizedBox(height: 8),
          const MosStatusChip('Winga-ready', tone: MosTone.info),
          const SizedBox(height: 8),
          const MosStatusChip('AI never pays', tone: MosTone.warning),
        ],
      );
    }
    if (_step == 1) {
      return ListView(
        children: [
          for (final (title, id, icon, _) in _roles)
            ListTile(
              leading: Icon(icon, color: _role == id ? TaifaColors.emerald600 : null),
              title: Text(title),
              selected: _role == id,
              onTap: () => setState(() => _role = id),
              trailing: _role == id ? const Icon(Icons.check_circle, color: TaifaColors.emerald600) : null,
            ),
        ],
      );
    }
    final label = _roles.firstWhere((r) => r.$2 == _role, orElse: () => _roles.first).$1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('First success · $label', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: TaifaSpacing.md),
        Text(_firstTask(label)),
      ],
    );
  }

  String _firstTask(String role) => switch (role) {
        'Cashier' => 'Open POS, add a favorite SKU, tap Charge.',
        'Warehouse' => 'Receive stock on a low SKU, then fulfill a paid order.',
        'Procurement' => 'Review suppliers and open purchase orders.',
        'Manager' => 'Open Management and review GMV + AI tips.',
        _ => 'Open Merchant Desk and complete today’s next action.',
      };
}

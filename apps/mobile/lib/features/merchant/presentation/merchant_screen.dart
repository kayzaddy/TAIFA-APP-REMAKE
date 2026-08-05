import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../../../app/theme/taifa_theme.dart';
import '../../../app/theme/taifa_typography.dart';
import '../../../shared/widgets/taifa_logo.dart';
import '../application/merchant_providers.dart';
import '../domain/merchant_models.dart';

class MerchantScreen extends ConsumerStatefulWidget {
  const MerchantScreen({super.key});

  @override
  ConsumerState<MerchantScreen> createState() => _MerchantScreenState();
}

class _MerchantScreenState extends ConsumerState<MerchantScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(merchantControllerProvider.notifier).bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(merchantControllerProvider);
    final ctrl = ref.read(merchantControllerProvider.notifier);
    final palette = context.taifa;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (state.phase == MerchantPhase.detail) {
                        ctrl.back();
                      } else if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/menu');
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
                      state.phase == MerchantPhase.detail
                          ? 'Order'
                          : 'Merchant',
                      style: TaifaTypography.sectionTitle(
                        palette.textPrimary,
                      ).copyWith(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: TaifaMotion.base,
                child: state.phase == MerchantPhase.detail
                    ? _Detail(
                        key: const ValueKey('d'),
                        state: state,
                        ctrl: ctrl,
                      )
                    : _Dash(key: const ValueKey('h'), state: state, ctrl: ctrl),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dash extends StatelessWidget {
  const _Dash({super.key, required this.state, required this.ctrl});
  final MerchantUiState state;
  final MerchantController ctrl;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final stats = state.stats;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          'Spice Bazaar · Kitchen',
          style: TextStyle(color: palette.textMuted),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _Stat(
                label: 'Today',
                value: stats?.todaySales.format() ?? '—',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Stat(label: 'Open', value: '${stats?.openOrders ?? 0}'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Stat(
                label: 'Done',
                value: '${stats?.completedToday ?? 0}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Orders',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        if (state.isBusy && state.orders.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          ...state.orders.map(
            (o) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: palette.surface,
                borderRadius: BorderRadius.circular(14),
                child: ListTile(
                  onTap: () => ctrl.open(o),
                  title: Text(
                    o.customerName,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: palette.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    '${o.itemsLabel} · ${o.status.label}',
                    style: TextStyle(color: palette.textMuted, fontSize: 12),
                  ),
                  trailing: Text(
                    o.total.format(),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: palette.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: palette.textMuted, fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({super.key, required this.state, required this.ctrl});
  final MerchantUiState state;
  final MerchantController ctrl;

  @override
  Widget build(BuildContext context) {
    final o = state.selected;
    if (o == null) return const SizedBox.shrink();
    final palette = context.taifa;
    final canAdvance =
        o.status != MerchantOrderStatus.completed &&
        o.status != MerchantOrderStatus.cancelled;
    final cta = switch (o.status) {
      MerchantOrderStatus.newOrder => 'Accept & prepare',
      MerchantOrderStatus.preparing => 'Mark ready',
      MerchantOrderStatus.ready => 'Complete order',
      _ => 'Done',
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            o.customerName,
            style: TaifaTypography.sectionTitle(
              palette.textPrimary,
            ).copyWith(fontSize: 22),
          ),
          Text(
            o.itemsLabel,
            style: TextStyle(color: palette.textMuted, height: 1.4),
          ),
          const SizedBox(height: 12),
          Text(
            o.status.label,
            style: const TextStyle(
              color: TaifaColors.emerald700,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            o.total.format(),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
              fontSize: 20,
            ),
          ),
          const Spacer(),
          if (canAdvance)
            FilledButton(
              onPressed: state.isBusy ? null : ctrl.advanceSelected,
              style: FilledButton.styleFrom(
                backgroundColor: TaifaColors.emerald700,
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(state.isBusy ? 'Updating…' : cta),
            ),
        ],
      ),
    );
  }
}

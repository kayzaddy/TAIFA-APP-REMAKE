import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../../../app/theme/taifa_theme.dart';
import '../../../app/theme/taifa_typography.dart';
import '../../../shared/widgets/taifa_logo.dart';
import '../../wallet/application/wallet_providers.dart';
import '../application/transit_providers.dart';
import '../domain/transit_models.dart';
import 'transit_feedback_sheet.dart';
import 'transit_route_detail.dart';

class TransitHomeScreen extends ConsumerStatefulWidget {
  const TransitHomeScreen({super.key});

  @override
  ConsumerState<TransitHomeScreen> createState() => _TransitHomeScreenState();
}

class _TransitHomeScreenState extends ConsumerState<TransitHomeScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transitControllerProvider.notifier).bootstrap();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transitControllerProvider);
    final ctrl = ref.read(transitControllerProvider.notifier);
    final walletAsync = ref.watch(walletControllerProvider);
    final palette = context.taifa;
    final home = state.home;
    final balance = walletAsync.value?.snapshot?.balance;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: state.isBusy && home == null
            ? const Center(
                child: CircularProgressIndicator(color: TaifaColors.gold400),
              )
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        TaifaSpacing.screenH,
                        TaifaSpacing.sm,
                        TaifaSpacing.screenH,
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  if (context.canPop()) {
                                    context.pop();
                                  } else {
                                    context.go('/mobility');
                                  }
                                },
                                icon: Icon(
                                  Icons.arrow_back_rounded,
                                  color: palette.textPrimary,
                                ),
                              ),
                              const TaifaLogo(
                                variant: TaifaLogoVariant.mark,
                                size: 32,
                              ),
                              const SizedBox(width: TaifaSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Mwendokasi',
                                      style: TaifaTypography.wordmark(
                                        palette.textPrimary,
                                      ).copyWith(fontSize: 18),
                                    ),
                                    Text(
                                      home?.region ?? 'Dar es Salaam · DART BRT',
                                      style: TextStyle(
                                        color: palette.textMuted,
                                        fontSize: 11,
                                      ),
                                    ),
                                    if (state.selectedMode.isNotEmpty)
                                      Text(
                                        _modeLabel(state),
                                        style: TextStyle(
                                          color: _modeColor(state),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Notifications',
                                onPressed: () => context.push('/mobility/transit/notifications'),
                                icon: Badge(
                                  isLabelVisible: (home?.unreadNotifications ?? 0) > 0,
                                  label: Text('${home?.unreadNotifications ?? 0}'),
                                  child: Icon(
                                    Icons.notifications_rounded,
                                    color: palette.textPrimary,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Profile',
                                onPressed: () => context.push('/mobility/transit/profile'),
                                icon: Icon(Icons.person_rounded, color: palette.textPrimary),
                              ),
                              if (balance != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: TaifaColors.emerald900,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: TaifaColors.gold500
                                          .withValues(alpha: 0.35),
                                    ),
                                  ),
                                  child: Text(
                                    balance.format(),
                                    style: const TextStyle(
                                      color: TaifaColors.gold400,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: TaifaSpacing.md),
                          _ModeSelector(
                            selectedMode: state.selectedMode,
                            modes: state.modes,
                            onSelect: ctrl.switchMode,
                          ),
                          const SizedBox(height: TaifaSpacing.sm),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => context.push('/mobility/transit/plan'),
                                  icon: const Icon(Icons.route_rounded, size: 18),
                                  label: const Text('Plan journey'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => context.push('/mobility/transit/live'),
                                  icon: const Icon(Icons.map_rounded, size: 18),
                                  label: const Text('Live map'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: TaifaSpacing.sm),
                          OutlinedButton.icon(
                            onPressed: () => context.push('/mobility/transit/assistant'),
                            icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                            label: const Text('Ask Mwendokasi AI'),
                          ),
                          const SizedBox(height: TaifaSpacing.sm),
                          OutlinedButton.icon(
                            onPressed: () => context.push('/mobility/transit/family'),
                            icon: const Icon(Icons.family_restroom_rounded, size: 18),
                            label: const Text('Family tickets'),
                          ),
                          const SizedBox(height: TaifaSpacing.sm),
                          OutlinedButton.icon(
                            onPressed: () => context.push('/mobility/transit/lost-found'),
                            icon: const Icon(Icons.search_rounded, size: 18),
                            label: const Text('Lost & found'),
                          ),
                          const SizedBox(height: TaifaSpacing.sm),
                          OutlinedButton.icon(
                            onPressed: () => showTransitFeedbackSheet(
                              context,
                              routeId: state.selectedRoute?.id ??
                                  home?.featuredRoutes.firstOrNull?.id,
                            ),
                            icon: const Icon(Icons.rate_review_outlined, size: 18),
                            label: const Text('Rate your last trip'),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => context.push('/mobility/transit/admin'),
                              child: const Text('BRT admin'),
                            ),
                          ),
                          const SizedBox(height: TaifaSpacing.sm),
                          TextField(
                            controller: _searchCtrl,
                            onChanged: ctrl.search,
                            style: TextStyle(color: palette.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Search station or destination…',
                              hintStyle: TextStyle(color: palette.textMuted),
                              filled: true,
                              fillColor: palette.surfaceAlt,
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: palette.textMuted,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          if (state.error != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              state.error!,
                              style: TextStyle(
                                color: palette.accent,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (state.query.isNotEmpty && state.searchResults.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _Section(
                        title: 'Search results',
                        child: Column(
                          children: state.searchResults
                              .map((r) => _RouteTile(route: r))
                              .toList(),
                        ),
                      ),
                    ),
                  if (home != null && home.alerts.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _Section(
                        title: 'Service alerts',
                        child: Column(
                          children: home.alerts
                              .map((a) => _AlertCard(alert: a))
                              .toList(),
                        ),
                      ),
                    ),
                  if (home != null && home.nearbyStations.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _Section(
                        title: 'Nearby stations',
                        child: SizedBox(
                          height: 120,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: home.nearbyStations.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 10),
                            itemBuilder: (_, i) => _StationChip(
                              station: home.nearbyStations[i],
                              onTap: () => context.push(
                                '/mobility/transit/station/${home.nearbyStations[i].stopCode}',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: _Section(
                      title: _routesSectionTitle(state.selectedMode),
                      child: Column(
                        children: (state.query.isEmpty
                                ? (home?.featuredRoutes ?? state.routes)
                                : state.searchResults)
                            .map((r) => _RouteTile(route: r))
                            .toList(),
                      ),
                    ),
                  ),
                  if (state.myTickets.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _Section(
                        title: 'My tickets',
                        child: Column(
                          children: state.myTickets
                              .map(
                                (t) => _TicketCard(
                                  ticket: t,
                                  onTap: () {
                                    ctrl.setActiveTicket(t);
                                    context.push('/mobility/transit/ticket');
                                  },
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'transit-sos',
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        onPressed: state.isBusy
            ? null
            : () => _confirmSos(context, ref),
        icon: const Icon(Icons.sos_rounded),
        label: const Text('SOS'),
      ),
      bottomSheet: state.selectedRoute != null
          ? TransitRouteDetailSheet(
              route: state.selectedRoute!,
              products: state.products.isNotEmpty
                  ? state.products
                  : (state.home?.products ?? const []),
              selectedProductCode: state.selectedProductCode,
              onSelectProduct: ctrl.selectProduct,
              isBusy: state.isBusy,
              onClose: ctrl.closeRoute,
              onPurchase: () async {
                final ticket = await ctrl.purchaseTicket();
                if (ticket != null && context.mounted) {
                  context.push('/mobility/transit/ticket');
                }
              },
            )
          : null,
    );
  }

  Future<void> _confirmSos(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send SOS?'),
        content: const Text(
          'Your location will be shared with DART transit safety operators.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Send SOS'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final ok = await ref.read(transitEngagementControllerProvider.notifier).sendSos(
          notes: 'Passenger SOS from Mwendokasi app',
        );
    if (context.mounted && ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SOS sent — help is on the way')),
      );
    }
  }
}

String _routesSectionTitle(String mode) {
  return switch (mode) {
    'brt' => 'Mwendokasi BRT routes',
    'daladala' => 'Daladala routes',
    _ => 'All routes',
  };
}

String _modeLabel(TransitUiState state) {
  if (state.selectedMode.isEmpty) return '';
  final match = state.modes.where((m) => m.id == state.selectedMode);
  return match.isNotEmpty ? match.first.label : state.selectedMode.toUpperCase();
}

Color _modeColor(TransitUiState state) {
  if (state.selectedMode.isEmpty) return TaifaColors.emerald500;
  final match = state.modes.where((m) => m.id == state.selectedMode);
  if (match.isEmpty) return TaifaColors.emerald500;
  final hex = match.first.color;
  if (!hex.startsWith('#') || hex.length < 7) return TaifaColors.emerald500;
  final value = int.tryParse(hex.substring(1, 7), radix: 16);
  if (value == null) return TaifaColors.emerald500;
  return Color(0xFF000000 | value);
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({
    required this.selectedMode,
    required this.modes,
    required this.onSelect,
  });

  final String selectedMode;
  final List<TransitMode> modes;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final chips = <({String id, String label, Color color})>[
      (id: '', label: 'All', color: TaifaColors.emerald500),
      ...modes.map((m) {
        final hex = m.color;
        Color color = TaifaColors.emerald500;
        if (hex.startsWith('#') && hex.length >= 7) {
          final value = int.tryParse(hex.substring(1, 7), radix: 16);
          if (value != null) color = Color(0xFF000000 | value);
        }
        return (id: m.id, label: m.label, color: color);
      }),
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final chip = chips[i];
          final selected = selectedMode == chip.id;
          return ChoiceChip(
            label: Text(chip.label),
            selected: selected,
            onSelected: (_) => onSelect(chip.id),
            selectedColor: chip.color.withValues(alpha: 0.2),
            labelStyle: TextStyle(
              color: selected ? chip.color : palette.textMuted,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 12,
            ),
            side: BorderSide(
              color: selected ? chip.color : palette.border,
            ),
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TaifaSpacing.screenH,
        TaifaSpacing.md,
        TaifaSpacing.screenH,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: palette.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _StationChip extends StatelessWidget {
  const _StationChip({required this.station, required this.onTap});
  final TransitStation station;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.train_rounded, color: TaifaColors.emerald500, size: 22),
          const Spacer(),
          Text(
            station.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: palette.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          Text(
            station.distanceMeters > 0
                ? '${(station.distanceMeters / 1000).toStringAsFixed(1)} km'
                : station.platform,
            style: TextStyle(color: palette.textMuted, fontSize: 11),
          ),
        ],
      ),
      ),
    );
  }
}

class _RouteTile extends ConsumerWidget {
  const _RouteTile({required this.route});
  final TransitRoute route;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.taifa;
    final brandColor = _parseColor(route.metadata['color']?.toString());
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: palette.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => ref.read(transitControllerProvider.notifier).openRoute(route.id),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: brandColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.directions_bus_filled_rounded,
                    color: brandColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route.brand,
                        style: TextStyle(
                          color: palette.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        route.name,
                        style: TextStyle(
                          color: palette.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${route.stops.length} stops · ${route.metadata['operator'] ?? 'DART'}',
                        style: TextStyle(color: palette.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Text(
                  route.fare.format(),
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _parseColor(String? hex) {
    if (hex == null || !hex.startsWith('#') || hex.length < 7) {
      return TaifaColors.emerald500;
    }
    final value = int.tryParse(hex.substring(1, 7), radix: 16);
    if (value == null) return TaifaColors.emerald500;
    return Color(0xFF000000 | value);
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert});
  final TransitAlert alert;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final color = switch (alert.severity) {
      'warning' => Colors.orange,
      'critical' => Colors.red,
      _ => TaifaColors.ocean400,
    };
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        color: color.withValues(alpha: 0.08),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            alert.title,
            style: TextStyle(
              color: palette.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            alert.body,
            style: TextStyle(color: palette.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket, required this.onTap});
  final TransitTicket ticket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: TaifaColors.emerald900,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.qr_code_2_rounded, color: TaifaColors.gold400),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.routeName.isNotEmpty
                            ? ticket.routeName
                            : 'BRT Ticket',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        ticket.mediaCode,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  ticket.status.toUpperCase(),
                  style: const TextStyle(
                    color: TaifaColors.gold400,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../../../app/theme/taifa_theme.dart';
import '../../../app/theme/taifa_typography.dart';
import '../../../shared/widgets/taifa_logo.dart';
import '../../wallet/application/wallet_providers.dart' show apiConfigProvider;
import '../application/map_scene_builder.dart';
import '../application/ride_providers.dart';
import '../data/dar_places.dart';
import '../domain/place.dart';
import '../domain/ride_product.dart';
import '../domain/trip.dart';

/// Mobility — Demo Complete passenger ride experience (mock gateways).
/// Map rendering goes through [MapsProvider] so Google/Mapbox can swap in later.
class MobilityScreen extends ConsumerStatefulWidget {
  const MobilityScreen({super.key});

  @override
  ConsumerState<MobilityScreen> createState() => _MobilityScreenState();
}

class _MobilityScreenState extends ConsumerState<MobilityScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(rideControllerProvider.notifier).bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rideControllerProvider);
    final ctrl = ref.read(rideControllerProvider.notifier);
    final maps = ref.watch(mapsProviderProvider);
    final palette = context.taifa;
    final scene = mapSceneForRide(state);

    return Scaffold(
      backgroundColor: palette.background,
      body: Stack(
        children: [
          Positioned.fill(child: maps.buildMap(scene: scene)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                TaifaSpacing.screenH,
                TaifaSpacing.sm,
                TaifaSpacing.screenH,
                0,
              ),
              child: Row(
                children: [
                  const TaifaLogo(variant: TaifaLogoVariant.mark, size: 36),
                  const SizedBox(width: TaifaSpacing.sm),
                  Expanded(
                    child: Text(
                      'TAIFA Ride',
                      style: TaifaTypography.wordmark(
                        palette.textPrimary,
                      ).copyWith(fontSize: 18),
                    ),
                  ),
                  _ChipButton(
                    icon: Icons.sos_rounded,
                    onTap: ctrl.triggerSos,
                  ),
                  const SizedBox(width: TaifaSpacing.sm),
                  _ChipButton(
                    icon: Icons.history_rounded,
                    onTap: ctrl.openHistory,
                  ),
                ],
              ),
            ),
          ),
          if (state.error != null)
            Positioned(
              top: 100,
              left: TaifaSpacing.screenH,
              right: TaifaSpacing.screenH,
              child: _ErrorBanner(message: state.error!, onDismiss: () {}),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedSwitcher(
              duration: TaifaMotion.base,
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeIn,
              child: _BottomForPhase(
                key: ValueKey(state.phase),
                state: state,
                ctrl: ctrl,
              ),
            ),
          ),
          if (state.isBusy && state.phase != RidePhase.searching)
            const Positioned.fill(
              child: AbsorbPointer(
                child: ColoredBox(
                  color: Color(0x33000000),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: TaifaColors.gold400,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BottomForPhase extends StatelessWidget {
  const _BottomForPhase({super.key, required this.state, required this.ctrl});
  final RideUiState state;
  final RideController ctrl;

  @override
  Widget build(BuildContext context) {
    return switch (state.phase) {
      RidePhase.home => _HomeSheet(state: state, ctrl: ctrl),
      RidePhase.pickingPlaces => _PlaceSheet(state: state, ctrl: ctrl),
      RidePhase.quoting => _QuoteSheet(state: state, ctrl: ctrl),
      RidePhase.requesting ||
      RidePhase.searching => _SearchingSheet(state: state, ctrl: ctrl),
      RidePhase.assigned ||
      RidePhase.enRoute ||
      RidePhase.arrived ||
      RidePhase.inTrip => _ActiveTripSheet(state: state, ctrl: ctrl),
      RidePhase.completed => _CompletedSheet(state: state, ctrl: ctrl),
      RidePhase.receipt => _ReceiptSheet(state: state, ctrl: ctrl),
      RidePhase.history => _HistorySheet(state: state, ctrl: ctrl),
    };
  }
}

class _SheetScaffold extends StatelessWidget {
  const _SheetScaffold({required this.child, this.height});
  final Widget child;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    // Use Material (not a colored DecoratedBox) so descendant ListTiles can
    // paint ink splashes correctly.
    return Container(
      width: double.infinity,
      height: height,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 88),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TaifaRadii.xxl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: palette.isDark ? const Color(0xF0121412) : palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TaifaRadii.xxl),
          side: BorderSide(color: palette.borderStrong),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          child: child,
        ),
      ),
    );
  }
}

class _HomeSheet extends StatelessWidget {
  const _HomeSheet({required this.state, required this.ctrl});
  final RideUiState state;
  final RideController ctrl;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return _SheetScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Where to?',
            style: TaifaTypography.sectionTitle(
              palette.textPrimary,
            ).copyWith(fontSize: 24),
          ),
          const SizedBox(height: 6),
          Text(
            'Premium rides across Dar es Salaam',
            style: TextStyle(color: palette.textMuted, fontSize: 13),
          ),
          const SizedBox(height: TaifaSpacing.md),
          _FieldTap(
            icon: Icons.my_location_rounded,
            label: state.pickup?.name ?? 'Current location',
            subtitle: state.pickup?.subtitle ?? 'Detecting…',
            onTap: ctrl.openPlacePicker,
          ),
          const SizedBox(height: TaifaSpacing.sm),
          _FieldTap(
            icon: Icons.search_rounded,
            label: state.dropoff?.name ?? 'Destination',
            subtitle: state.dropoff?.subtitle ?? 'Airport, mall, home…',
            accent: true,
            onTap: ctrl.openPlacePicker,
          ),
          const SizedBox(height: TaifaSpacing.md),
          _TransitPromoCard(onTap: () => context.push('/mobility/transit')),
          const SizedBox(height: TaifaSpacing.md),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: ctrl.openPlacePicker,
              style: FilledButton.styleFrom(
                backgroundColor: TaifaColors.emerald700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Plan a ride',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceSheet extends ConsumerStatefulWidget {
  const _PlaceSheet({required this.state, required this.ctrl});
  final RideUiState state;
  final RideController ctrl;

  @override
  ConsumerState<_PlaceSheet> createState() => _PlaceSheetState();
}

class _PlaceSheetState extends ConsumerState<_PlaceSheet> {
  final _query = TextEditingController();
  List<Place> _results = DarPlaces.all;
  bool _editingPickup = false;

  @override
  void initState() {
    super.initState();
    _editingPickup =
        widget.state.dropoff == null && widget.state.pickup != null;
    // Default: edit destination if pickup exists
    _editingPickup = false;
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    final svc = ref.read(rideServiceProvider);
    final list = await svc.location.search(q);
    if (mounted) setState(() => _results = list);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final state = widget.state;
    final ctrl = widget.ctrl;
    return _SheetScaffold(
      height: MediaQuery.sizeOf(context).height * 0.58,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: ctrl.backToHome,
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: palette.textPrimary,
                ),
              ),
              Text(
                'Set route',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          _miniStop(
            selected: _editingPickup,
            label: 'Pickup',
            value: state.pickup?.name ?? 'Choose pickup',
            onTap: () => setState(() => _editingPickup = true),
          ),
          _miniStop(
            selected: !_editingPickup,
            label: 'Drop-off',
            value: state.dropoff?.name ?? 'Choose destination',
            onTap: () => setState(() => _editingPickup = false),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _query,
            onChanged: _search,
            style: TextStyle(color: palette.textPrimary),
            decoration: InputDecoration(
              hintText: _editingPickup ? 'Search pickup' : 'Search destination',
              hintStyle: TextStyle(color: palette.textMuted),
              filled: true,
              fillColor: palette.surfaceAlt,
              prefixIcon: Icon(Icons.search, color: palette.textMuted),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (_, i) {
                final p = _results[i];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    p.kind == PlaceKind.airport
                        ? Icons.flight_takeoff_rounded
                        : p.kind == PlaceKind.home
                        ? Icons.home_rounded
                        : Icons.place_rounded,
                    color: TaifaColors.gold400,
                  ),
                  title: Text(
                    p.name,
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    p.subtitle,
                    style: TextStyle(color: palette.textMuted, fontSize: 12),
                  ),
                  onTap: () {
                    if (_editingPickup) {
                      ctrl.setPickup(p);
                      setState(() => _editingPickup = false);
                    } else {
                      ctrl.setDropoff(p);
                    }
                  },
                );
              },
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: state.pickup != null && state.dropoff != null
                  ? ctrl.confirmPlaces
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: TaifaColors.gold500,
                foregroundColor: TaifaColors.black900,
                disabledBackgroundColor: palette.surfaceAlt,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'See routes & fares',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStop({
    required bool selected,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final palette = context.taifa;
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? TaifaColors.gold500 : palette.border,
            width: selected ? 1.4 : 1,
          ),
          color: selected ? TaifaColors.gold500.withValues(alpha: 0.08) : null,
        ),
        child: Row(
          children: [
            Text(
              '$label · ',
              style: TextStyle(color: palette.textMuted, fontSize: 12),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuoteSheet extends ConsumerWidget {
  const _QuoteSheet({required this.state, required this.ctrl});
  final RideUiState state;
  final RideController ctrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.taifa;
    final route = state.route;
    final showSmsDemo = ref.watch(apiConfigProvider).useRemoteBackend;
    return _SheetScaffold(
      height: MediaQuery.sizeOf(context).height * 0.52,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: ctrl.openPlacePicker,
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: palette.textPrimary,
                ),
              ),
              Expanded(
                child: Text(
                  route == null
                      ? 'Choose a ride'
                      : '${route.durationLabel} · ${route.distanceLabel}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          Text(
            '${state.pickup?.name ?? ''} → ${state.dropoff?.name ?? ''}',
            style: TextStyle(color: palette.textMuted, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: state.quotes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final q = state.quotes[i];
                final selected =
                    state.selectedQuote?.product.id == q.product.id;
                return _ProductTile(
                  estimate: q,
                  selected: selected,
                  onTap: () => ctrl.selectProduct(q.product.id),
                );
              },
            ),
          ),
          if (showSmsDemo) ...[
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: state.featurePhoneDemo,
              onChanged: ctrl.setFeaturePhoneDemo,
              title: Text(
                'Feature phone SMS dispatch',
                style: TextStyle(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              subtitle: Text(
                'Shows outbound SMS to boda riders without smartphones. Pick Boda for best demo.',
                style: TextStyle(color: palette.textMuted, fontSize: 11),
              ),
              activeThumbColor: TaifaColors.gold500,
            ),
          ],
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: state.selectedQuote == null ? null : ctrl.requestRide,
              style: FilledButton.styleFrom(
                backgroundColor: TaifaColors.emerald700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                state.selectedQuote == null
                    ? 'Select a ride'
                    : 'Request ${state.selectedQuote!.product.name} · ${state.selectedQuote!.total.format()}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.estimate,
    required this.selected,
    required this.onTap,
  });
  final FareEstimate estimate;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final p = estimate.product;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? TaifaColors.gold500 : palette.border,
            width: selected ? 1.5 : 1,
          ),
          color: selected
              ? TaifaColors.gold500.withValues(alpha: 0.08)
              : palette.surfaceAlt,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: TaifaColors.emerald900,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _iconFor(p.iconName),
                color: TaifaColors.gold400,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${p.subtitle} · ${p.etaMinutes} min away',
                    style: TextStyle(color: palette.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            Text(
              estimate.total.format(),
              style: TextStyle(
                color: palette.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String key) => switch (key) {
    'boda' => Icons.two_wheeler_rounded,
    'xl' => Icons.airport_shuttle_rounded,
    'comfort' => Icons.airline_seat_recline_extra_rounded,
    _ => Icons.directions_car_filled_rounded,
  };
}

class _SearchingSheet extends StatelessWidget {
  const _SearchingSheet({required this.state, required this.ctrl});
  final RideUiState state;
  final RideController ctrl;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return _SheetScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: TaifaColors.gold400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Finding your driver',
            style: TaifaTypography.sectionTitle(
              palette.textPrimary,
            ).copyWith(fontSize: 22),
          ),
          const SizedBox(height: 6),
          Text(
            state.dispatchMessage,
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.textMuted),
          ),
          if (state.smsPreview.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: palette.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: palette.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.sms_rounded, color: TaifaColors.gold400, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'SMS sent to ${state.smsDriverName.isEmpty ? 'rider' : state.smsDriverName}',
                        style: TextStyle(
                          color: palette.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (state.smsDriverPhone.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      state.smsDriverPhone,
                      style: TextStyle(color: palette.textMuted, fontSize: 11),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    state.smsPreview,
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontSize: 11,
                      height: 1.35,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton.icon(
                onPressed: ctrl.simulateFeaturePhoneAccept,
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: const Text('Simulate driver replies YES'),
                style: FilledButton.styleFrom(
                  backgroundColor: TaifaColors.emerald700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          TextButton(
            onPressed: ctrl.cancelSearch,
            child: Text(
              'Cancel request',
              style: TextStyle(color: palette.accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveTripSheet extends StatelessWidget {
  const _ActiveTripSheet({required this.state, required this.ctrl});
  final RideUiState state;
  final RideController ctrl;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final trip = state.trip;
    final driver = state.driver ?? trip?.driver;
    final status = trip?.status ?? TripStatus.driverEnRoute;
    return _SheetScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            status.label,
            style: TextStyle(
              color: TaifaColors.gold400,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          if (driver != null) ...[
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: TaifaColors.emerald800,
                  child: Text(
                    driver.photoInitial,
                    style: const TextStyle(
                      color: TaifaColors.gold400,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver.fullName,
                        style: TextStyle(
                          color: palette.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${driver.vehicle.displayName} · ${driver.vehicle.plate}',
                        style: TextStyle(
                          color: palette.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '★ ${driver.rating.toStringAsFixed(2)} · ${driver.tripsCompleted} trips',
                        style: TextStyle(
                          color: palette.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trip?.etaMinutes != null &&
                    status == TripStatus.driverEnRoute)
                  _EtaBadge('${trip!.etaMinutes} min'),
              ],
            ),
            const SizedBox(height: 12),
          ],
          _Timeline(status: status, progress: state.tripProgress),
          if (status == TripStatus.inProgress) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: state.tripProgress,
                minHeight: 6,
                backgroundColor: palette.surfaceAlt,
                color: TaifaColors.ocean400,
              ),
            ),
          ],
          if (status == TripStatus.driverArrived) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton(
                onPressed: ctrl.startTrip,
                style: FilledButton.styleFrom(
                  backgroundColor: TaifaColors.emerald700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'I’m in the car — Start trip',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.status, required this.progress});
  final TripStatus status;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final steps = [
      (TripStatus.driverAssigned, 'Assigned'),
      (TripStatus.driverEnRoute, 'En route'),
      (TripStatus.driverArrived, 'Arrived'),
      (TripStatus.inProgress, 'Riding'),
      (TripStatus.completed, 'Done'),
    ];
    final idx = steps.indexWhere((s) => s.$1 == status);
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                color: i <= idx ? TaifaColors.gold500 : context.taifa.border,
              ),
            ),
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i <= idx ? TaifaColors.gold500 : context.taifa.border,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                steps[i].$2,
                style: TextStyle(fontSize: 9, color: context.taifa.textMuted),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _CompletedSheet extends StatelessWidget {
  const _CompletedSheet({required this.state, required this.ctrl});
  final RideUiState state;
  final RideController ctrl;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final trip = state.trip!;
    return _SheetScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: TaifaColors.emerald500,
            size: 52,
          ),
          const SizedBox(height: 10),
          Text(
            'You\'ve arrived',
            style: TaifaTypography.sectionTitle(
              palette.textPrimary,
            ).copyWith(fontSize: 22),
          ),
          const SizedBox(height: 6),
          Text(trip.dropoff.name, style: TextStyle(color: palette.textMuted)),
          const SizedBox(height: 8),
          Text(
            trip.fare.format(),
            style: TaifaTypography.balance(
              palette.textPrimary,
            ).copyWith(fontSize: 28),
          ),
          const SizedBox(height: 4),
          Text(
            'Pay with TAIFA Wallet',
            style: TextStyle(color: palette.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: ctrl.confirmPayment,
              style: FilledButton.styleFrom(
                backgroundColor: TaifaColors.gold500,
                foregroundColor: TaifaColors.black900,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Confirm payment',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptSheet extends StatelessWidget {
  const _ReceiptSheet({required this.state, required this.ctrl});
  final RideUiState state;
  final RideController ctrl;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final trip = state.trip!;
    return _SheetScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trip receipt',
            style: TaifaTypography.sectionTitle(
              palette.textPrimary,
            ).copyWith(fontSize: 22),
          ),
          const SizedBox(height: 12),
          _kv('From', trip.pickup.name, palette),
          _kv('To', trip.dropoff.name, palette),
          _kv('Product', trip.product.name, palette),
          _kv('Driver', trip.driver?.fullName ?? '—', palette),
          _kv('Fare', trip.fare.format(), palette),
          _kv('Payment', trip.paymentRef ?? '—', palette),
          _kv('Status', trip.status.label, palette),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: ctrl.backToHome,
              style: FilledButton.styleFrom(
                backgroundColor: TaifaColors.emerald700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Done',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v, TaifaPalette palette) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(
              k,
              style: TextStyle(color: palette.textMuted, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: TextStyle(
                color: palette.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistorySheet extends StatelessWidget {
  const _HistorySheet({required this.state, required this.ctrl});
  final RideUiState state;
  final RideController ctrl;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final items = state.history;
    return _SheetScaffold(
      height: MediaQuery.sizeOf(context).height * 0.5,
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: ctrl.backToHome,
                icon: Icon(Icons.close_rounded, color: palette.textPrimary),
              ),
              Text(
                'Ride history',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: palette.textPrimary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      'No trips yet — request your first ride.',
                      style: TextStyle(color: palette.textMuted),
                    ),
                  )
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) => Divider(color: palette.border),
                    itemBuilder: (_, i) {
                      final t = items[i];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '${t.pickup.name} → ${t.dropoff.name}',
                          style: TextStyle(
                            color: palette.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          '${t.product.name} · ${t.status.label}',
                          style: TextStyle(
                            color: palette.textMuted,
                            fontSize: 11,
                          ),
                        ),
                        trailing: Text(
                          t.fare.format(),
                          style: TextStyle(
                            color: palette.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FieldTap extends StatelessWidget {
  const _FieldTap({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.accent = false,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: palette.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: accent
                ? TaifaColors.gold500.withValues(alpha: 0.45)
                : palette.border,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: accent ? TaifaColors.gold400 : palette.textMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: palette.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: palette.textMuted),
          ],
        ),
      ),
    );
  }
}

class _TransitPromoCard extends StatelessWidget {
  const _TransitPromoCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TaifaColors.emerald900,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: TaifaColors.gold500.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.directions_bus_filled_rounded,
                  color: TaifaColors.gold400,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mwendokasi BRT',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'DART digital tickets · Kimara — Kivukoni',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: TaifaColors.gold400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChipButton extends StatelessWidget {
  const _ChipButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return Material(
      color: palette.isDark ? const Color(0xCC121412) : palette.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: palette.textPrimary),
        ),
      ),
    );
  }
}

class _EtaBadge extends StatelessWidget {
  const _EtaBadge(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: TaifaColors.emerald800,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TaifaColors.gold500.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: TaifaColors.gold400,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});
  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xCC3B1212),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          message,
          style: const TextStyle(color: Color(0xFFFFB4B4), fontSize: 12),
        ),
      ),
    );
  }
}

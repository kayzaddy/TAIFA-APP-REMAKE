import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../../../app/theme/taifa_theme.dart';
import '../../../app/theme/taifa_typography.dart';
import '../../../shared/widgets/taifa_logo.dart';
import '../application/flight_providers.dart';
import '../domain/flight_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Flights — Demo Complete search → select → ticket → wallet pay.
class FlightsScreen extends ConsumerStatefulWidget {
  const FlightsScreen({super.key});

  @override
  ConsumerState<FlightsScreen> createState() => _FlightsScreenState();
}

class _FlightsScreenState extends ConsumerState<FlightsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(flightControllerProvider.notifier).bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(flightControllerProvider);
    final ctrl = ref.read(flightControllerProvider.notifier);
    final palette = context.taifa;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              title: switch (state.phase) {
                FlightPhase.search => 'TAIFA Flights',
                FlightPhase.results => 'Choose flight',
                FlightPhase.checkout => 'Confirm',
                FlightPhase.ticketed => 'Ticketed',
                FlightPhase.receipt => 'Receipt',
                FlightPhase.history => 'Trips',
              },
              onBack: () {
                switch (state.phase) {
                  case FlightPhase.search:
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  case FlightPhase.results:
                    ctrl.backToSearch();
                  case FlightPhase.checkout:
                    ctrl.backToResults();
                  case FlightPhase.history:
                    ctrl.backToSearch();
                  default:
                    ctrl.backToSearch();
                }
              },
              onHistory: ctrl.openHistory,
            ),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Text(
                  state.error!,
                  style: const TextStyle(
                    color: Color(0xFFFF8A80),
                    fontSize: 12,
                  ),
                ),
              ),
            Expanded(
              child: AnimatedSwitcher(
                duration: TaifaMotion.base,
                child: _Body(
                  key: ValueKey(state.phase),
                  state: state,
                  ctrl: ctrl,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.onBack,
    required this.onHistory,
  });
  final String title;
  final VoidCallback onBack;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(LucideIcons.arrowLeft, color: palette.textPrimary),
          ),
          const TaifaLogo(variant: TaifaLogoVariant.mark, size: 32),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TaifaTypography.sectionTitle(
                palette.textPrimary,
              ).copyWith(fontSize: 18),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: onHistory,
            icon: Icon(
              LucideIcons.plane,
              color: palette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({super.key, required this.state, required this.ctrl});
  final FlightUiState state;
  final FlightController ctrl;

  @override
  Widget build(BuildContext context) {
    return switch (state.phase) {
      FlightPhase.search => _Search(state: state, ctrl: ctrl),
      FlightPhase.results => _Results(state: state, ctrl: ctrl),
      FlightPhase.checkout => _Checkout(state: state, ctrl: ctrl),
      FlightPhase.ticketed => _Ticketed(state: state, ctrl: ctrl),
      FlightPhase.receipt => _Receipt(state: state),
      FlightPhase.history => _History(state: state),
    };
  }
}

String _fmtDate(DateTime? d) {
  if (d == null) return '—';
  const m = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${d.day} ${m[d.month - 1]}';
}

String _fmtTime(DateTime d) {
  final h = d.hour.toString().padLeft(2, '0');
  final min = d.minute.toString().padLeft(2, '0');
  return '$h:$min';
}

class _Search extends StatelessWidget {
  const _Search({required this.state, required this.ctrl});
  final FlightUiState state;
  final FlightController ctrl;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final airports = state.airports.isEmpty
        ? FlightCatalogAirports.fallback
        : state.airports;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          'Where are you flying?',
          style: TaifaTypography.sectionTitle(
            palette.textPrimary,
          ).copyWith(fontSize: 24),
        ),
        const SizedBox(height: 16),
        _AirportField(
          label: 'From',
          value: state.originCode,
          airports: airports,
          onChanged: ctrl.setOrigin,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            onPressed: ctrl.swapAirports,
            icon: Icon(LucideIcons.arrowUpDown, color: palette.textMuted),
          ),
        ),
        _AirportField(
          label: 'To',
          value: state.destinationCode,
          airports: airports,
          onChanged: ctrl.setDestination,
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: state.departDate ?? now.add(const Duration(days: 2)),
              firstDate: now,
              lastDate: now.add(const Duration(days: 365)),
            );
            if (picked != null) ctrl.setDate(picked);
          },
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.calendar, color: palette.textMuted),
                const SizedBox(width: 10),
                Text(
                  'Depart ${_fmtDate(state.departDate)}',
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              'Passengers',
              style: TextStyle(
                color: palette.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => ctrl.setPassengers(state.passengers - 1),
              icon: Icon(LucideIcons.circleMinus, color: palette.textMuted),
            ),
            Text(
              '${state.passengers}',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: palette.textPrimary,
              ),
            ),
            IconButton(
              onPressed: () => ctrl.setPassengers(state.passengers + 1),
              icon: Icon(LucideIcons.circlePlus, color: palette.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: state.isBusy ? null : ctrl.search,
          style: FilledButton.styleFrom(
            backgroundColor: TaifaColors.emerald700,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(state.isBusy ? 'Searching…' : 'Search flights'),
        ),
      ],
    );
  }
}

/// Fallback when airports not yet loaded.
class FlightCatalogAirports {
  static List<Airport> get fallback => const [
    Airport(code: 'DAR', city: 'Dar es Salaam', name: 'Julius Nyerere Intl'),
    Airport(code: 'ZNZ', city: 'Zanzibar', name: 'Abeid Amani Karume'),
    Airport(code: 'JRO', city: 'Kilimanjaro', name: 'Kilimanjaro Intl'),
    Airport(code: 'NBO', city: 'Nairobi', name: 'Jomo Kenyatta'),
    Airport(code: 'EBB', city: 'Entebbe', name: 'Entebbe Intl'),
  ];
}

class _AirportField extends StatelessWidget {
  const _AirportField({
    required this.label,
    required this.value,
    required this.airports,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<Airport> airports;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: airports.any((a) => a.code == value)
              ? value
              : airports.first.code,
          hint: Text(label),
          items: [
            for (final a in airports)
              DropdownMenuItem(
                value: a.code,
                child: Text(
                  '$label · ${a.code} — ${a.city}',
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.state, required this.ctrl});
  final FlightUiState state;
  final FlightController ctrl;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          '${state.originCode} → ${state.destinationCode} · ${_fmtDate(state.departDate)}',
          style: TextStyle(color: palette.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 12),
        if (state.results.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(
                'No flights found.',
                style: TextStyle(color: palette.textMuted),
              ),
            ),
          )
        else
          ...state.results.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: palette.surface,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () => ctrl.selectOffer(f),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${f.airline} · ${f.flightNumber}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: palette.textPrimary,
                                ),
                              ),
                            ),
                            if (f.popular)
                              const Text(
                                'Popular',
                                style: TextStyle(
                                  color: TaifaColors.emerald700,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text(
                              _fmtTime(f.departAt),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: palette.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${f.durationMinutes} min · ${f.stops == 0 ? 'Direct' : '${f.stops} stop'}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: palette.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _fmtTime(f.arriveAt),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: palette.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${f.cabin} · ${f.price.format()}',
                          style: TextStyle(
                            color: palette.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
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

class _Checkout extends StatelessWidget {
  const _Checkout({required this.state, required this.ctrl});
  final FlightUiState state;
  final FlightController ctrl;

  @override
  Widget build(BuildContext context) {
    final f = state.selected;
    if (f == null) return const SizedBox.shrink();
    final palette = context.taifa;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          '${f.origin.code} → ${f.destination.code}',
          style: TaifaTypography.sectionTitle(
            palette.textPrimary,
          ).copyWith(fontSize: 22),
        ),
        Text(
          '${f.airline} ${f.flightNumber}',
          style: TextStyle(color: palette.textMuted),
        ),
        const SizedBox(height: 16),
        _kv(
          'Depart',
          '${_fmtDate(f.departAt)} ${_fmtTime(f.departAt)}',
          palette,
        ),
        _kv(
          'Arrive',
          '${_fmtDate(f.arriveAt)} ${_fmtTime(f.arriveAt)}',
          palette,
        ),
        _kv('Passengers', '${state.passengers}', palette),
        _kv('Total', state.total.format(), palette, bold: true),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: state.isBusy ? null : ctrl.confirmBooking,
          style: FilledButton.styleFrom(
            backgroundColor: TaifaColors.emerald700,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            state.isBusy
                ? 'Holding seats…'
                : 'Hold seats · ${state.total.format()}',
          ),
        ),
      ],
    );
  }
}

class _Ticketed extends StatelessWidget {
  const _Ticketed({required this.state, required this.ctrl});
  final FlightUiState state;
  final FlightController ctrl;

  @override
  Widget build(BuildContext context) {
    final b = state.booking;
    if (b == null) return const SizedBox.shrink();
    final palette = context.taifa;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            LucideIcons.plane,
            color: TaifaColors.emerald500,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'Seats held',
            style: TaifaTypography.sectionTitle(
              palette.textPrimary,
            ).copyWith(fontSize: 22),
          ),
          const SizedBox(height: 6),
          Text(
            'PNR ${b.pnr} · ${b.offer.flightNumber}',
            style: TextStyle(color: palette.textMuted),
          ),
          const Spacer(),
          FilledButton(
            onPressed: state.isBusy ? null : ctrl.confirmPayment,
            style: FilledButton.styleFrom(
              backgroundColor: TaifaColors.emerald700,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              state.isBusy
                  ? 'Paying…'
                  : 'Pay with wallet · ${b.total.format()}',
            ),
          ),
        ],
      ),
    );
  }
}

class _Receipt extends StatelessWidget {
  const _Receipt({required this.state});
  final FlightUiState state;

  @override
  Widget build(BuildContext context) {
    final b = state.booking;
    if (b == null) return const SizedBox.shrink();
    final palette = context.taifa;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text(
          'Ticket confirmed',
          style: TaifaTypography.sectionTitle(
            palette.textPrimary,
          ).copyWith(fontSize: 22),
        ),
        const SizedBox(height: 12),
        _kv(
          'Route',
          '${b.offer.origin.code} → ${b.offer.destination.code}',
          palette,
        ),
        _kv('Flight', b.offer.flightNumber, palette),
        _kv('PNR', b.pnr ?? '—', palette),
        _kv('Ref', b.paymentRef ?? '—', palette),
        _kv('Total', b.total.format(), palette, bold: true),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: () => context.go('/home'),
          child: const Text('Back to Home'),
        ),
      ],
    );
  }
}

class _History extends StatelessWidget {
  const _History({required this.state});
  final FlightUiState state;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    if (state.history.isEmpty) {
      return Center(
        child: Text(
          'No trips yet.',
          style: TextStyle(color: palette.textMuted),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: state.history.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final b = state.history[i];
        return Material(
          color: palette.surface,
          borderRadius: BorderRadius.circular(14),
          child: ListTile(
            title: Text(
              '${b.offer.origin.code} → ${b.offer.destination.code}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
            ),
            subtitle: Text(
              '${b.status.label} · ${b.pnr ?? b.id}',
              style: TextStyle(color: palette.textMuted, fontSize: 12),
            ),
            trailing: Text(
              b.total.format(),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: palette.textPrimary,
              ),
            ),
          ),
        );
      },
    );
  }
}

Widget _kv(String k, String v, TaifaPalette palette, {bool bold = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
          child: Text(k, style: TextStyle(color: palette.textMuted)),
        ),
        Text(
          v,
          style: TextStyle(
            color: palette.textPrimary,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

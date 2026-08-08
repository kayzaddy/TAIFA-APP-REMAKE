import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../../../app/theme/taifa_theme.dart';
import '../../../app/theme/taifa_typography.dart';
import '../../../shared/widgets/taifa_logo.dart';
import '../../wallet/domain/currency.dart';
import '../../wallet/domain/money.dart';
import '../application/tourism_providers.dart';
import '../domain/tourism_models.dart';
import '../domain/tourism_trip_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Tourism — Demo Complete experiences (Zanzibar, safari, reefs).
class TourismScreen extends ConsumerStatefulWidget {
  const TourismScreen({super.key});

  @override
  ConsumerState<TourismScreen> createState() => _TourismScreenState();
}

class _TourismScreenState extends ConsumerState<TourismScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tourismControllerProvider.notifier).bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tourismControllerProvider);
    final ctrl = ref.read(tourismControllerProvider.notifier);
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
                      switch (state.phase) {
                        case TourismPhase.home:
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/home');
                          }
                        case TourismPhase.planInterview:
                          ctrl.backFromPlanInterview();
                        case TourismPhase.planOptions:
                          ctrl.backFromPlanOptions();
                        case TourismPhase.itineraryDetail:
                          ctrl.backFromItineraryDetail();
                        case TourismPhase.tripHub:
                          ctrl.backFromTripHub();
                        case TourismPhase.unifiedCheckout:
                          ctrl.backFromUnifiedCheckout();
                        case TourismPhase.tripCheckoutReceipt:
                          ctrl.backFromTripCheckoutReceipt();
                        case TourismPhase.tourismHelp:
                          ctrl.backFromTourismHelp();
                        case TourismPhase.detail:
                          ctrl.backToHome();
                        case TourismPhase.checkout:
                          ctrl.backToDetail();
                        case TourismPhase.history:
                          ctrl.backToHome();
                        default:
                          ctrl.backToHome();
                      }
                    },
                    icon: Icon(
                      LucideIcons.arrowLeft,
                      color: palette.textPrimary,
                    ),
                  ),
                  const TaifaLogo(variant: TaifaLogoVariant.mark, size: 32),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      switch (state.phase) {
                        TourismPhase.home => 'TAIFA Tourism',
                        TourismPhase.planInterview => 'Plan your trip',
                        TourismPhase.planOptions => 'Pick an itinerary',
                        TourismPhase.itineraryDetail =>
                          state.focusItinerary?.label ?? 'Itinerary',
                        TourismPhase.tripHub =>
                          state.activeTrip?.title ?? 'Your trip',
                        TourismPhase.unifiedCheckout => 'Trip checkout',
                        TourismPhase.tripCheckoutReceipt => 'Trip confirmed',
                        TourismPhase.tourismHelp => 'Help & SOS',
                        TourismPhase.detail =>
                          state.selected?.title ?? 'Experience',
                        TourismPhase.checkout => 'Book experience',
                        TourismPhase.confirmed => 'Reserved',
                        TourismPhase.receipt => 'Receipt',
                        TourismPhase.history => 'Bookings',
                      },
                      style: TaifaTypography.sectionTitle(
                        palette.textPrimary,
                      ).copyWith(fontSize: 18),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: ctrl.openHistory,
                    icon: Icon(
                      LucideIcons.receipt,
                      color: palette.textMuted,
                    ),
                  ),
                ],
              ),
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
                child: switch (state.phase) {
                  TourismPhase.home => _Home(
                    key: const ValueKey('home'),
                    state: state,
                    ctrl: ctrl,
                  ),
                  TourismPhase.planInterview => _PlanInterview(
                    key: const ValueKey('plan'),
                    state: state,
                    ctrl: ctrl,
                  ),
                  TourismPhase.planOptions => _PlanOptions(
                    key: const ValueKey('opts'),
                    state: state,
                    ctrl: ctrl,
                  ),
                  TourismPhase.itineraryDetail => _ItineraryDetail(
                    key: const ValueKey('itin'),
                    state: state,
                    ctrl: ctrl,
                  ),
                  TourismPhase.tripHub => _TripHub(
                    key: const ValueKey('hub'),
                    state: state,
                    ctrl: ctrl,
                  ),
                  TourismPhase.unifiedCheckout => _UnifiedCheckout(
                    key: const ValueKey('uc'),
                    state: state,
                    ctrl: ctrl,
                  ),
                  TourismPhase.tripCheckoutReceipt => _TripCheckoutReceipt(
                    key: const ValueKey('tcr'),
                    state: state,
                    ctrl: ctrl,
                  ),
                  TourismPhase.tourismHelp => _TourismHelp(
                    key: const ValueKey('help'),
                    state: state,
                    ctrl: ctrl,
                  ),
                  TourismPhase.detail => _Detail(
                    key: const ValueKey('detail'),
                    state: state,
                    ctrl: ctrl,
                  ),
                  TourismPhase.checkout => _Checkout(
                    key: const ValueKey('checkout'),
                    state: state,
                    ctrl: ctrl,
                  ),
                  TourismPhase.confirmed => _Confirmed(
                    key: const ValueKey('ok'),
                    state: state,
                    ctrl: ctrl,
                  ),
                  TourismPhase.receipt => _Receipt(
                    key: const ValueKey('rx'),
                    state: state,
                  ),
                  TourismPhase.history => _History(
                    key: const ValueKey('hist'),
                    state: state,
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _fmt(DateTime? d) {
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
  return '${d.day} ${m[d.month - 1]} ${d.year}';
}

class _Home extends StatelessWidget {
  const _Home({super.key, required this.state, required this.ctrl});
  final TourismUiState state;
  final TourismController ctrl;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final tones = [
      TaifaColors.ocean400,
      TaifaColors.emerald500,
      const Color(0xFFB08968),
      TaifaColors.gold400,
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (state.activeTrip != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Material(
              color: palette.surface,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                onTap: () => ctrl.openTripHub(),
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            LucideIcons.map,
                            color: TaifaColors.ocean400,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.activeTrip!.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: palette.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            state.activeTrip!.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: palette.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${state.activeTrip!.partySize} travelers · '
                        '${state.activeTrip!.tourBookingIds.length} tours · '
                        '${state.activeTrip!.stayBookingIds.length} stays',
                        style: TextStyle(
                          color: palette.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: FilledButton.tonal(
              onPressed: ctrl.startPlanFlow,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Plan a Tanzania trip'),
            ),
          ),
        TextField(
          onChanged: ctrl.search,
          decoration: InputDecoration(
            hintText: 'Search Zanzibar, safari, reefs…',
            prefixIcon: Icon(LucideIcons.search, color: palette.textMuted),
            filled: true,
            fillColor: palette.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Experiences',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 10),
        ...state.tours.map((t) {
          final tone = tones[t.imageTone % tones.length];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: palette.surface,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                onTap: () => ctrl.openTour(t),
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 72,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(
                            colors: [
                              tone.withValues(alpha: 0.9),
                              tone.withValues(alpha: 0.4),
                            ],
                          ),
                        ),
                        child: const Icon(
                          LucideIcons.mountain,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: palette.textPrimary,
                              ),
                            ),
                            Text(
                              t.region,
                              style: TextStyle(
                                color: palette.textMuted,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '★ ${t.rating.toStringAsFixed(1)} · ${t.durationLabel} · from ${t.price.format()}',
                              style: TextStyle(
                                color: palette.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

String _estimateLabel(int minor) =>
    Money(minor, Currency.tzs).format();

class _PlanInterview extends StatelessWidget {
  const _PlanInterview({super.key, required this.state, required this.ctrl});
  final TourismUiState state;
  final TourismController ctrl;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    const budgets = ['budget', 'mid', 'luxury'];
    const styles = ['leisure', 'adventure', 'family'];
    const interests = ['safari', 'beach', 'culture', 'wildlife'];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          'Tell us about your trip',
          style: TaifaTypography.sectionTitle(palette.textPrimary),
        ),
        const SizedBox(height: 16),
        Text('Travelers', style: TextStyle(color: palette.textMuted)),
        Row(
          children: [
            IconButton(
              onPressed: () => ctrl.setGuests(state.guests - 1),
              icon: Icon(LucideIcons.circleMinus, color: palette.textMuted),
            ),
            Text(
              '${state.guests}',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: palette.textPrimary,
              ),
            ),
            IconButton(
              onPressed: () => ctrl.setGuests(state.guests + 1),
              icon: Icon(LucideIcons.circlePlus, color: palette.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: state.date ?? now.add(const Duration(days: 14)),
              firstDate: now,
              lastDate: now.add(const Duration(days: 365)),
            );
            if (picked != null) ctrl.setDate(picked);
          },
          child: Text(
            'Start date · ${_fmt(state.date)}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Budget', style: TextStyle(color: palette.textMuted)),
        Wrap(
          spacing: 8,
          children: budgets.map((b) {
            final selected = state.planBudgetTier == b;
            return ChoiceChip(
              label: Text(b),
              selected: selected,
              onSelected: (_) => ctrl.setPlanBudget(b),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Text('Style', style: TextStyle(color: palette.textMuted)),
        Wrap(
          spacing: 8,
          children: styles.map((s) {
            return ChoiceChip(
              label: Text(s),
              selected: state.planTravelStyle == s,
              onSelected: (_) => ctrl.setPlanStyle(s),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Text('Interests', style: TextStyle(color: palette.textMuted)),
        Wrap(
          spacing: 8,
          children: interests.map((i) {
            return FilterChip(
              label: Text(i),
              selected: state.planInterests.contains(i),
              onSelected: (_) => ctrl.togglePlanInterest(i),
            );
          }).toList(),
        ),
        const SizedBox(height: 28),
        FilledButton(
          onPressed: state.isBusy ? null : ctrl.submitPlan,
          style: FilledButton.styleFrom(
            backgroundColor: TaifaColors.emerald700,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(state.isBusy ? 'Building options…' : 'See itineraries'),
        ),
      ],
    );
  }
}

class _PlanOptions extends StatelessWidget {
  const _PlanOptions({super.key, required this.state, required this.ctrl});
  final TourismUiState state;
  final TourismController ctrl;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    if (state.tripItineraries.isEmpty) {
      return Center(
        child: Text(
          'No itineraries yet. Go back and try again.',
          style: TextStyle(color: palette.textMuted),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: state.tripItineraries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final it = state.tripItineraries[i];
        return Material(
          color: palette.surface,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => ctrl.openItineraryDetail(it),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    it.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: palette.textPrimary,
                    ),
                  ),
                  Text(
                    it.summary,
                    style: TextStyle(color: palette.textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${it.days.length} days · from ${_estimateLabel(it.estimateMinor)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ItineraryDetail extends StatelessWidget {
  const _ItineraryDetail({super.key, required this.state, required this.ctrl});
  final TourismUiState state;
  final TourismController ctrl;

  @override
  Widget build(BuildContext context) {
    final it = state.focusItinerary;
    if (it == null) return const SizedBox.shrink();
    final palette = context.taifa;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          it.summary,
          style: TextStyle(color: palette.textMuted),
        ),
        const SizedBox(height: 8),
        Text(
          'Est. ${_estimateLabel(it.estimateMinor)}',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        ...it.days.map((d) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Day ${d.day} · ${d.title}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                ),
                ...d.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(top: 4, left: 8),
                    child: Text(
                      '${item.time} · ${item.title}',
                      style: TextStyle(
                        color: palette.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: state.isBusy
              ? null
              : () => ctrl.confirmItinerary(it.id),
          style: FilledButton.styleFrom(
            backgroundColor: TaifaColors.emerald700,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(state.isBusy ? 'Saving…' : 'Use this itinerary'),
        ),
      ],
    );
  }
}

class _TripHub extends StatelessWidget {
  const _TripHub({super.key, required this.state, required this.ctrl});
  final TourismUiState state;
  final TourismController ctrl;

  @override
  Widget build(BuildContext context) {
    final trip = state.activeTrip;
    if (trip == null) return const SizedBox.shrink();
    final palette = context.taifa;
    TourismItinerary? selected;
    if (trip.selectedItineraryId != null) {
      for (final it in state.tripItineraries) {
        if (it.id == trip.selectedItineraryId) {
          selected = it;
          break;
        }
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          trip.isReady ? 'Trip ready' : 'Still planning',
          style: TextStyle(color: palette.textMuted, fontSize: 13),
        ),
        if (selected != null) ...[
          const SizedBox(height: 8),
          Text(
            selected.label,
            style: TaifaTypography.sectionTitle(palette.textPrimary),
          ),
          Text(selected.summary, style: TextStyle(color: palette.textMuted)),
        ],
        const SizedBox(height: 16),
        Text(
          'Linked bookings',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${trip.tourBookingIds.length} experience bookings · '
          '${trip.stayBookingIds.length} stay bookings',
          style: TextStyle(color: palette.textMuted),
        ),
        const SizedBox(height: 24),
        Text(
          'Add experiences',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        ...state.tours.take(4).map((t) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              tileColor: palette.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Text(
                t.title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
              ),
              subtitle: Text(
                'from ${t.price.format()}',
                style: TextStyle(color: palette.textMuted, fontSize: 12),
              ),
              trailing: const Icon(LucideIcons.chevronRight),
              onTap: () => ctrl.openTour(t),
            ),
          );
        }),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: ctrl.openTourismHelp,
          icon: const Icon(LucideIcons.siren),
          label: const Text('Help & SOS'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: ctrl.startPlanFlow,
          child: const Text('Re-plan trip'),
        ),
        if (trip.tourBookingIds.isNotEmpty || trip.stayBookingIds.isNotEmpty) ...[
          const SizedBox(height: 16),
          FilledButton(
            onPressed: state.isBusy ? null : ctrl.openUnifiedCheckout,
            style: FilledButton.styleFrom(
              backgroundColor: TaifaColors.emerald700,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Review & pay trip'),
          ),
        ],
      ],
    );
  }
}

class _UnifiedCheckout extends StatelessWidget {
  const _UnifiedCheckout({super.key, required this.state, required this.ctrl});
  final TourismUiState state;
  final TourismController ctrl;

  @override
  Widget build(BuildContext context) {
    final checkout = state.checkout;
    if (checkout == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final palette = context.taifa;
    final quote = state.cart?.insuranceQuote;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          'Travel',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ...checkout.lines.where((l) => l.section == 'travel').map(
              (l) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                ),
                trailing: Text(
                  l.amount.format(),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
              ),
            ),
        const SizedBox(height: 16),
        Text(
          'Protection',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        if (quote != null)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              quote.planName,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: palette.textPrimary,
              ),
            ),
            subtitle: Text(
              '${quote.provider} · ${_estimateLabel(quote.coverageMinor)} cover',
              style: TextStyle(color: palette.textMuted, fontSize: 12),
            ),
            value: state.includeTripInsurance,
            onChanged: state.isBusy ? null : ctrl.setIncludeTripInsurance,
          ),
        const SizedBox(height: 16),
        Text(
          'Connectivity',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
          ),
        ),
        if (state.cart?.esimQuote != null)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              state.cart!.esimQuote!.planName,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: palette.textPrimary,
              ),
            ),
            subtitle: Text(
              '${state.cart!.esimQuote!.dataGb} GB · ${state.cart!.esimQuote!.days} days · '
              '${_estimateLabel(state.cart!.esimQuote!.priceMinor)}',
              style: TextStyle(color: palette.textMuted, fontSize: 12),
            ),
            value: state.includeTripEsim,
            onChanged: state.isBusy ? null : ctrl.setIncludeTripEsim,
          ),
        const Divider(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: palette.textPrimary,
              ),
            ),
            Text(
              checkout.total.format(),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: palette.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: state.isBusy ? null : ctrl.confirmUnifiedPayment,
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
                : 'Pay with wallet · ${checkout.total.format()}',
          ),
        ),
      ],
    );
  }
}

class _TripCheckoutReceipt extends StatelessWidget {
  const _TripCheckoutReceipt({
    super.key,
    required this.state,
    required this.ctrl,
  });
  final TourismUiState state;
  final TourismController ctrl;

  @override
  Widget build(BuildContext context) {
    final checkout = state.checkout;
    if (checkout == null) return const SizedBox.shrink();
    final palette = context.taifa;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            LucideIcons.circleCheckBig,
            color: TaifaColors.emerald500,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'Trip payment complete',
            style: TaifaTypography.sectionTitle(
              palette.textPrimary,
            ).copyWith(fontSize: 22),
          ),
          Text(
            'Total ${checkout.total.format()}',
            style: TextStyle(color: palette.textMuted),
          ),
          if (checkout.includeInsurance && checkout.insurancePolicyId != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Travel insurance issued · ${checkout.insurancePolicyId}',
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 12,
                ),
              ),
            ),
          if (checkout.includeEsim && checkout.esimOrderId != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'eSIM ready · ${checkout.esimActivation?.qrPayload ?? checkout.esimOrderId}',
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 12,
                ),
              ),
            ),
          if (checkout.paymentRef != null)
            Text(
              'Ref ${checkout.paymentRef}',
              style: TextStyle(color: palette.textMuted, fontSize: 12),
            ),
          const Spacer(),
          FilledButton(
            onPressed: ctrl.backFromTripCheckoutReceipt,
            style: FilledButton.styleFrom(
              backgroundColor: TaifaColors.emerald700,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Back to trip hub'),
          ),
        ],
      ),
    );
  }
}

class _TourismHelp extends StatelessWidget {
  const _TourismHelp({super.key, required this.state, required this.ctrl});
  final TourismUiState state;
  final TourismController ctrl;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text(
          'Hold for emergency',
          style: TaifaTypography.sectionTitle(palette.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          'Shares your location with Taifa tourism safety and creates an open incident.',
          style: TextStyle(color: palette.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: state.isBusy
              ? null
              : () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Send SOS?'),
                      content: const Text(
                        'Tourism operators and emergency partners will be notified.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Send SOS'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) await ctrl.sendTourismSos();
                },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFC62828),
            minimumSize: const Size.fromHeight(52),
          ),
          child: Text(state.isBusy ? 'Sending…' : 'SOS — I need help now'),
        ),
        if (state.lastSosCase != null) ...[
          const SizedBox(height: 12),
          Text(
            'SOS sent · ref ${state.lastSosCase!.safetyIncidentId ?? state.lastSosCase!.id}',
            style: TextStyle(
              color: TaifaColors.emerald500,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 28),
        Text(
          'Nearby',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ...state.nearbyPlaces.map(
          (p) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              switch (p.kind) {
                'hospital' => LucideIcons.briefcaseMedical,
                'police' => LucideIcons.siren,
                'embassy' => LucideIcons.flag,
                _ => LucideIcons.mapPin,
              },
              color: palette.textMuted,
            ),
            title: Text(p.name, style: TextStyle(color: palette.textPrimary)),
            subtitle: Text(
              '${p.phone} · ${p.distanceKm.toStringAsFixed(1)} km',
              style: TextStyle(color: palette.textMuted, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({super.key, required this.state, required this.ctrl});
  final TourismUiState state;
  final TourismController ctrl;

  @override
  Widget build(BuildContext context) {
    final t = state.selected;
    if (t == null) return const SizedBox.shrink();
    final palette = context.taifa;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Container(
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                TaifaColors.ocean400.withValues(alpha: 0.9),
                TaifaColors.gold400.withValues(alpha: 0.55),
              ],
            ),
          ),
          padding: const EdgeInsets.all(18),
          alignment: Alignment.bottomLeft,
          child: Text(
            t.tagline.isEmpty ? t.region : t.tagline,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          t.title,
          style: TaifaTypography.sectionTitle(
            palette.textPrimary,
          ).copyWith(fontSize: 22),
        ),
        Text(
          '${t.region} · ${t.durationLabel} · ★ ${t.rating.toStringAsFixed(1)}',
          style: TextStyle(color: palette.textMuted),
        ),
        const SizedBox(height: 14),
        Text(
          t.highlights.join(' · '),
          style: TextStyle(color: palette.textPrimary, height: 1.4),
        ),
        const SizedBox(height: 18),
        Text(
          '${t.price.format()} / guest',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: ctrl.goCheckout,
          style: FilledButton.styleFrom(
            backgroundColor: TaifaColors.emerald700,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text('Continue to book'),
        ),
      ],
    );
  }
}

class _Checkout extends StatelessWidget {
  const _Checkout({super.key, required this.state, required this.ctrl});
  final TourismUiState state;
  final TourismController ctrl;

  @override
  Widget build(BuildContext context) {
    final t = state.selected;
    if (t == null) return const SizedBox.shrink();
    final palette = context.taifa;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          t.title,
          style: TaifaTypography.sectionTitle(
            palette.textPrimary,
          ).copyWith(fontSize: 20),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: state.date ?? now.add(const Duration(days: 3)),
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
            child: Text(
              'Date · ${_fmt(state.date)}',
              style: TextStyle(
                color: palette.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              'Guests',
              style: TextStyle(
                color: palette.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => ctrl.setGuests(state.guests - 1),
              icon: Icon(LucideIcons.circleMinus, color: palette.textMuted),
            ),
            Text(
              '${state.guests}',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: palette.textPrimary,
              ),
            ),
            IconButton(
              onPressed: () => ctrl.setGuests(state.guests + 1),
              icon: Icon(LucideIcons.circlePlus, color: palette.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Total ${state.total.format()}',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
          ),
        ),
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
            state.isBusy ? 'Reserving…' : 'Reserve · ${state.total.format()}',
          ),
        ),
      ],
    );
  }
}

class _Confirmed extends StatelessWidget {
  const _Confirmed({super.key, required this.state, required this.ctrl});
  final TourismUiState state;
  final TourismController ctrl;

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
            LucideIcons.circleCheckBig,
            color: TaifaColors.emerald500,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'Experience reserved',
            style: TaifaTypography.sectionTitle(
              palette.textPrimary,
            ).copyWith(fontSize: 22),
          ),
          Text(
            '${b.tour.title} · ${b.confirmationCode}',
            style: TextStyle(color: palette.textMuted),
          ),
          Text(
            _fmt(b.date),
            style: TextStyle(
              color: palette.textPrimary,
              fontWeight: FontWeight.w600,
            ),
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
  const _Receipt({super.key, required this.state});
  final TourismUiState state;

  @override
  Widget build(BuildContext context) {
    final b = state.booking;
    if (b == null) return const SizedBox.shrink();
    final palette = context.taifa;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text(
          'Payment confirmed',
          style: TaifaTypography.sectionTitle(
            palette.textPrimary,
          ).copyWith(fontSize: 22),
        ),
        const SizedBox(height: 12),
        Text(
          b.tour.title,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
          ),
        ),
        Text(
          'Code ${b.confirmationCode} · Ref ${b.paymentRef}',
          style: TextStyle(color: palette.textMuted),
        ),
        Text(
          'Total ${b.total.format()}',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
          ),
        ),
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
  const _History({super.key, required this.state});
  final TourismUiState state;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    if (state.history.isEmpty) {
      return Center(
        child: Text(
          'No tourism bookings yet.',
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
              b.tour.title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
            ),
            subtitle: Text(
              '${b.status.label} · ${_fmt(b.date)}',
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

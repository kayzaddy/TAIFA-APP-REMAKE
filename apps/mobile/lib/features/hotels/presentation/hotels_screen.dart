import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../../../app/theme/taifa_theme.dart';
import '../../../app/theme/taifa_typography.dart';
import '../../../shared/widgets/taifa_logo.dart';
import '../application/stay_providers.dart';
import '../domain/hotel_models.dart';

/// Hotels — Demo Complete stay booking (mock catalog + wallet pay).
class HotelsScreen extends ConsumerStatefulWidget {
  const HotelsScreen({super.key});

  @override
  ConsumerState<HotelsScreen> createState() => _HotelsScreenState();
}

class _HotelsScreenState extends ConsumerState<HotelsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(stayControllerProvider.notifier).bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(stayControllerProvider);
    final ctrl = ref.read(stayControllerProvider.notifier);
    final palette = context.taifa;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              title: switch (state.phase) {
                StayPhase.home => 'TAIFA Hotels',
                StayPhase.detail => state.selected?.name ?? 'Stay',
                StayPhase.rooms => 'Choose a room',
                StayPhase.checkout => 'Confirm stay',
                StayPhase.confirmed => 'Reserved',
                StayPhase.receipt => 'Receipt',
                StayPhase.history => 'Bookings',
              },
              onBack: () {
                switch (state.phase) {
                  case StayPhase.home:
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  case StayPhase.detail:
                    ctrl.backToHome();
                  case StayPhase.rooms:
                    ctrl.backToDetail();
                  case StayPhase.checkout:
                    ctrl.openRooms();
                  case StayPhase.history:
                    ctrl.backToHome();
                  default:
                    ctrl.backToHome();
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
            icon: Icon(Icons.arrow_back_rounded, color: palette.textPrimary),
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
            icon: Icon(Icons.receipt_long_rounded, color: palette.textMuted),
            tooltip: 'Bookings',
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({super.key, required this.state, required this.ctrl});
  final StayUiState state;
  final StayController ctrl;

  @override
  Widget build(BuildContext context) {
    return switch (state.phase) {
      StayPhase.home => _Home(state: state, ctrl: ctrl),
      StayPhase.detail => _Detail(state: state, ctrl: ctrl),
      StayPhase.rooms => _Rooms(state: state, ctrl: ctrl),
      StayPhase.checkout => _Checkout(state: state, ctrl: ctrl),
      StayPhase.confirmed => _Confirmed(state: state, ctrl: ctrl),
      StayPhase.receipt => _Receipt(state: state),
      StayPhase.history => _History(state: state),
    };
  }
}

class _Home extends StatelessWidget {
  const _Home({required this.state, required this.ctrl});
  final StayUiState state;
  final StayController ctrl;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        TextField(
          onChanged: ctrl.search,
          decoration: InputDecoration(
            hintText: 'Search Dar, Zanzibar, Arusha…',
            prefixIcon: Icon(Icons.search_rounded, color: palette.textMuted),
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
          'Featured stays',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 10),
        if (state.isBusy && state.hotels.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          ...state.hotels.map(
            (h) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _HotelTile(hotel: h, onTap: () => ctrl.openHotel(h)),
            ),
          ),
      ],
    );
  }
}

class _HotelTile extends StatelessWidget {
  const _HotelTile({required this.hotel, required this.onTap});
  final Hotel hotel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final tones = [
      TaifaColors.ocean400,
      TaifaColors.emerald500,
      const Color(0xFFB08968),
      TaifaColors.dangerSoft,
    ];
    final tone = tones[hotel.imageTone % tones.length];
    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
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
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      tone.withValues(alpha: 0.85),
                      tone.withValues(alpha: 0.35),
                    ],
                  ),
                ),
                child: const Icon(Icons.hotel_rounded, color: Colors.white70),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hotel.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hotel.area,
                      style: TextStyle(color: palette.textMuted, fontSize: 12),
                    ),
                    if (hotel.tagline.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        hotel.tagline,
                        style: TextStyle(
                          color: palette.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      '${'★' * hotel.stars} · ${hotel.rating.toStringAsFixed(1)} · from ${hotel.fromNightly.format()}/night',
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
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.state, required this.ctrl});
  final StayUiState state;
  final StayController ctrl;

  @override
  Widget build(BuildContext context) {
    final hotel = state.selected;
    if (hotel == null) return const SizedBox.shrink();
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
                TaifaColors.emerald700.withValues(alpha: 0.55),
              ],
            ),
          ),
          padding: const EdgeInsets.all(18),
          alignment: Alignment.bottomLeft,
          child: Text(
            hotel.tagline.isEmpty ? hotel.area : hotel.tagline,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          hotel.name,
          style: TaifaTypography.sectionTitle(
            palette.textPrimary,
          ).copyWith(fontSize: 18),
        ),
        const SizedBox(height: 4),
        Text(
          '${hotel.area} · ${hotel.stars}★ · ${hotel.rating.toStringAsFixed(1)}',
          style: TextStyle(color: palette.textMuted),
        ),
        const SizedBox(height: 18),
        Text(
          'Your trip',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _DateChip(
                label: 'Check-in',
                value: _fmt(state.checkIn),
                onTap: () => _pickDate(context, state.checkIn, ctrl.setCheckIn),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _DateChip(
                label: 'Check-out',
                value: _fmt(state.checkOut),
                onTap: () =>
                    _pickDate(context, state.checkOut, ctrl.setCheckOut),
              ),
            ),
          ],
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
              icon: Icon(Icons.remove_circle_outline, color: palette.textMuted),
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
              icon: Icon(Icons.add_circle_outline, color: palette.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: ctrl.openRooms,
          style: FilledButton.styleFrom(
            backgroundColor: TaifaColors.emerald700,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            'See rooms · ${state.nights} night${state.nights == 1 ? '' : 's'}',
          ),
        ),
      ],
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.label,
    required this.value,
    required this.onTap,
  });
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: palette.textMuted, fontSize: 11),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: palette.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _pickDate(
  BuildContext context,
  DateTime? current,
  void Function(DateTime) onPicked,
) async {
  final now = DateTime.now();
  final picked = await showDatePicker(
    context: context,
    initialDate: current ?? now.add(const Duration(days: 1)),
    firstDate: now,
    lastDate: now.add(const Duration(days: 365)),
  );
  if (picked != null) onPicked(picked);
}

String _fmt(DateTime? d) {
  if (d == null) return '—';
  const months = [
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
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

class _Rooms extends StatelessWidget {
  const _Rooms({required this.state, required this.ctrl});
  final StayUiState state;
  final StayController ctrl;

  @override
  Widget build(BuildContext context) {
    final hotel = state.selected;
    if (hotel == null) return const SizedBox.shrink();
    final palette = context.taifa;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          '${hotel.name} · ${_fmt(state.checkIn)} → ${_fmt(state.checkOut)}',
          style: TextStyle(color: palette.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 12),
        ...hotel.rooms.map(
          (room) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: palette.surface,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () => ctrl.selectRoom(room),
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
                              room.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: palette.textPrimary,
                              ),
                            ),
                          ),
                          if (room.popular)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: TaifaColors.emerald500.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Popular',
                                style: TextStyle(
                                  color: TaifaColors.emerald700,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        room.description,
                        style: TextStyle(
                          color: palette.textMuted,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        room.amenities.join(' · '),
                        style: TextStyle(
                          color: palette.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${room.nightlyRate.format()}/night · up to ${room.maxGuests} guests',
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
  final StayUiState state;
  final StayController ctrl;

  @override
  Widget build(BuildContext context) {
    final hotel = state.selected;
    final room = state.selectedRoom;
    if (hotel == null || room == null) return const SizedBox.shrink();
    final palette = context.taifa;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          hotel.name,
          style: TaifaTypography.sectionTitle(
            palette.textPrimary,
          ).copyWith(fontSize: 18),
        ),
        Text(room.name, style: TextStyle(color: palette.textMuted)),
        const SizedBox(height: 16),
        _kv('Check-in', _fmt(state.checkIn), palette),
        _kv('Check-out', _fmt(state.checkOut), palette),
        _kv('Nights', '${state.nights}', palette),
        _kv('Guests', '${state.guests}', palette),
        const Divider(height: 28),
        _kv('Room', state.roomSubtotal.format(), palette),
        _kv('Taxes & fees', state.taxes.format(), palette),
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
            state.isBusy ? 'Reserving…' : 'Reserve · ${state.total.format()}',
          ),
        ),
      ],
    );
  }
}

class _Confirmed extends StatelessWidget {
  const _Confirmed({required this.state, required this.ctrl});
  final StayUiState state;
  final StayController ctrl;

  @override
  Widget build(BuildContext context) {
    final booking = state.booking;
    if (booking == null) return const SizedBox.shrink();
    final palette = context.taifa;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: TaifaColors.emerald500,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'You’re reserved',
            style: TaifaTypography.sectionTitle(
              palette.textPrimary,
            ).copyWith(fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(
            '${booking.hotel.name} · ${booking.confirmationCode}',
            style: TextStyle(color: palette.textMuted, height: 1.4),
          ),
          const SizedBox(height: 8),
          Text(
            '${_fmt(booking.checkIn)} → ${_fmt(booking.checkOut)} · ${booking.nights} night${booking.nights == 1 ? '' : 's'}',
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
                  : 'Pay with wallet · ${booking.total.format()}',
            ),
          ),
        ],
      ),
    );
  }
}

class _Receipt extends StatelessWidget {
  const _Receipt({required this.state});
  final StayUiState state;

  @override
  Widget build(BuildContext context) {
    final booking = state.booking;
    if (booking == null) return const SizedBox.shrink();
    final palette = context.taifa;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text(
          'Payment confirmed',
          style: TaifaTypography.sectionTitle(
            palette.textPrimary,
          ).copyWith(fontSize: 18),
        ),
        const SizedBox(height: 12),
        _kv('Hotel', booking.hotel.name, palette),
        _kv('Room', booking.room.name, palette),
        _kv('Confirmation', booking.confirmationCode ?? '—', palette),
        _kv('Ref', booking.paymentRef ?? '—', palette),
        _kv(
          'Dates',
          '${_fmt(booking.checkIn)} → ${_fmt(booking.checkOut)}',
          palette,
        ),
        _kv('Total', booking.total.format(), palette, bold: true),
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
  final StayUiState state;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    if (state.history.isEmpty) {
      return Center(
        child: Text(
          'No bookings yet.',
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
              b.hotel.name,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
            ),
            subtitle: Text(
              '${b.status.label} · ${_fmt(b.checkIn)} · ${b.confirmationCode ?? b.id}',
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

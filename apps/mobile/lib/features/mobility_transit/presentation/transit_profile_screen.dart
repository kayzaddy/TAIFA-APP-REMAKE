import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../../../app/theme/taifa_theme.dart';
import '../application/transit_providers.dart';
import '../domain/transit_models.dart';

class TransitProfileScreen extends ConsumerStatefulWidget {
  const TransitProfileScreen({super.key});

  @override
  ConsumerState<TransitProfileScreen> createState() => _TransitProfileScreenState();
}

class _TransitProfileScreenState extends ConsumerState<TransitProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transitEngagementControllerProvider.notifier).loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transitEngagementControllerProvider);
    final ctrl = ref.read(transitEngagementControllerProvider.notifier);
    final palette = context.taifa;
    final bundle = state.profileBundle;

    return Scaffold(
      appBar: AppBar(title: const Text('My transit profile')),
      body: state.isBusy && bundle == null
          ? const Center(child: CircularProgressIndicator(color: TaifaColors.gold400))
          : ListView(
              padding: const EdgeInsets.all(TaifaSpacing.screenH),
              children: [
                if (bundle != null) ...[
                  _StatsRow(stats: bundle.stats),
                  const SizedBox(height: TaifaSpacing.md),
                  Text(
                    'Commute stops',
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _StopField(
                    label: 'Home stop code',
                    value: bundle.profile.homeStop,
                    onChanged: (v) => ctrl.updateProfile(homeStop: v),
                  ),
                  const SizedBox(height: 8),
                  _StopField(
                    label: 'Work stop code',
                    value: bundle.profile.workStop,
                    onChanged: (v) => ctrl.updateProfile(workStop: v),
                  ),
                  const SizedBox(height: TaifaSpacing.md),
                  Text(
                    'Accessibility',
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Wheelchair access', style: TextStyle(color: palette.textPrimary)),
                    value: bundle.profile.accessibility['wheelchair'] == true,
                    onChanged: (v) => ctrl.updateProfile(
                      accessibility: {...bundle.profile.accessibility, 'wheelchair': v},
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Large text', style: TextStyle(color: palette.textPrimary)),
                    value: bundle.profile.accessibility['large_text'] == true,
                    onChanged: (v) => ctrl.updateProfile(
                      accessibility: {...bundle.profile.accessibility, 'large_text': v},
                    ),
                  ),
                  const SizedBox(height: TaifaSpacing.md),
                  Row(
                    children: [
                      Text(
                        'Favorites',
                        style: TextStyle(
                          color: palette.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => ctrl.addFavorite(
                          subjectType: 'station',
                          subjectCode: 'ubungo',
                          label: 'Ubungo BRT',
                        ),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add Ubungo'),
                      ),
                    ],
                  ),
                  if (bundle.favorites.isEmpty)
                    Text(
                      'Save stations or routes for quick access.',
                      style: TextStyle(color: palette.textMuted, fontSize: 12),
                    )
                  else
                    ...bundle.favorites.map(
                      (f) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          f.subjectType == 'route'
                              ? Icons.directions_bus_filled_rounded
                              : Icons.train_rounded,
                          color: TaifaColors.emerald500,
                        ),
                        title: Text(
                          f.label.isNotEmpty ? f.label : f.subjectCode,
                          style: TextStyle(color: palette.textPrimary),
                        ),
                        subtitle: Text(
                          f.subjectType,
                          style: TextStyle(color: palette.textMuted, fontSize: 11),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.close_rounded, color: palette.textMuted, size: 18),
                          onPressed: () => ctrl.removeFavorite(f.id),
                        ),
                        onTap: () {
                          if (f.subjectType == 'station') {
                            context.push('/mobility/transit/station/${f.subjectCode}');
                          }
                        },
                      ),
                    ),
                ],
                if (state.error != null) ...[
                  const SizedBox(height: 12),
                  Text(state.error!, style: TextStyle(color: palette.accent, fontSize: 12)),
                ],
              ],
            ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});
  final TransitTravelStats stats;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return Row(
      children: [
        Expanded(child: _StatCard(label: 'Tickets', value: '${stats.totalTickets}', palette: palette)),
        const SizedBox(width: 8),
        Expanded(child: _StatCard(label: 'Active', value: '${stats.activeTickets}', palette: palette)),
        const SizedBox(width: 8),
        Expanded(child: _StatCard(label: 'Trips', value: '${stats.completedTrips}', palette: palette)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.palette,
  });

  final String label;
  final String value;
  final TaifaPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: palette.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          Text(label, style: TextStyle(color: palette.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}

class _StopField extends StatefulWidget {
  const _StopField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_StopField> createState() => _StopFieldState();
}

class _StopFieldState extends State<_StopField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _StopField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _ctrl.text != widget.value) {
      _ctrl.text = widget.value;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return TextField(
      controller: _ctrl,
      onSubmitted: widget.onChanged,
      style: TextStyle(color: palette.textPrimary),
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: TextStyle(color: palette.textMuted),
        filled: true,
        fillColor: palette.surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        suffixIcon: IconButton(
          icon: const Icon(Icons.check_rounded),
          onPressed: () => widget.onChanged(_ctrl.text.trim()),
        ),
      ),
    );
  }
}

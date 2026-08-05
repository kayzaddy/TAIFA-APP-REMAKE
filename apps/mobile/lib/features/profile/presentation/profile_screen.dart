import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_theme.dart';
import '../../../app/theme/taifa_typography.dart';
import '../../../shared/widgets/taifa_logo.dart';
import '../application/profile_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  var _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(profileControllerProvider.notifier).bootstrap();
      final p = ref.read(profileControllerProvider).profile;
      if (p != null && mounted) {
        _name.text = p.displayName;
        _phone.text = p.phone;
        setState(() => _loaded = true);
      }
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileControllerProvider);
    final ctrl = ref.read(profileControllerProvider.notifier);
    final palette = context.taifa;
    final p = state.profile;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: palette.textPrimary,
                  ),
                ),
                const TaifaLogo(variant: TaifaLogoVariant.mark, size: 32),
                const SizedBox(width: 8),
                Text(
                  'Profile',
                  style: TaifaTypography.sectionTitle(
                    palette.textPrimary,
                  ).copyWith(fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!_loaded || p == null)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: TaifaColors.emerald700,
                  child: Text(
                    p.displayName.isEmpty
                        ? '?'
                        : p.displayName[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Verified TAIFA member',
                  style: TextStyle(color: palette.textMuted, fontSize: 12),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _name,
                onChanged: ctrl.updateName,
                decoration: const InputDecoration(labelText: 'Display name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phone,
                onChanged: ctrl.updatePhone,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Email',
                  style: TextStyle(color: palette.textMuted, fontSize: 12),
                ),
                subtitle: Text(
                  p.email,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'City',
                  style: TextStyle(color: palette.textMuted, fontSize: 12),
                ),
                subtitle: Text(
                  p.city,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Preferred language',
                style: TextStyle(color: palette.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'sw', label: Text('Kiswahili')),
                  ButtonSegment(value: 'en', label: Text('English')),
                ],
                selected: {p.preferredLanguage},
                onSelectionChanged: (s) => ctrl.updateLanguage(s.first),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: state.isBusy ? null : ctrl.save,
                style: FilledButton.styleFrom(
                  backgroundColor: TaifaColors.emerald700,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(
                  state.saved
                      ? 'Saved'
                      : (state.isBusy ? 'Saving…' : 'Save profile'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

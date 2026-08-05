import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_theme.dart';
import '../../../app/theme/taifa_typography.dart';
import '../../../app/theme/theme_mode_provider.dart';
import '../../../shared/widgets/taifa_logo.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.taifa;
    final mode = ref.watch(themeModeProvider);
    final themeCtrl = ref.read(themeModeProvider.notifier);

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
                Text(
                  'Settings',
                  style: TaifaTypography.sectionTitle(
                    palette.textPrimary,
                  ).copyWith(fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Appearance',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: palette.textPrimary,
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Dark mode',
                style: TextStyle(color: palette.textPrimary),
              ),
              subtitle: Text(
                'Preference is saved on this device',
                style: TextStyle(color: palette.textMuted, fontSize: 12),
              ),
              value: mode == ThemeMode.dark,
              activeThumbColor: TaifaColors.emerald500,
              onChanged: (v) =>
                  themeCtrl.set(v ? ThemeMode.dark : ThemeMode.light),
            ),
            const Divider(height: 28),
            Text(
              'Account',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: palette.textPrimary,
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.person_rounded, color: palette.textMuted),
              title: Text(
                'Profile',
                style: TextStyle(color: palette.textPrimary),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: palette.textMuted,
              ),
              onTap: () => context.go('/profile'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.notifications_rounded,
                color: palette.textMuted,
              ),
              title: Text(
                'Notifications',
                style: TextStyle(color: palette.textPrimary),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: palette.textMuted,
              ),
              onTap: () => context.go('/notifications'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.nfc_rounded, color: palette.textMuted),
              title: Text(
                'NFC Tap-to-Translate',
                style: TextStyle(color: palette.textPrimary),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: palette.textMuted,
              ),
              onTap: () => context.go('/nfc'),
            ),
            const Divider(height: 28),
            Text(
              'Security (demo)',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: palette.textPrimary,
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Biometric unlock',
                style: TextStyle(color: palette.textPrimary),
              ),
              subtitle: Text(
                'Mocked preference for Demo Complete',
                style: TextStyle(color: palette.textMuted, fontSize: 12),
              ),
              value: true,
              onChanged: (_) {},
            ),
            const SizedBox(height: 12),
            Text(
              'TAIFA · Foundation Sprint',
              style: TextStyle(color: palette.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

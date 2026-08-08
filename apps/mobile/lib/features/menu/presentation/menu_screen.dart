import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_theme.dart';
import '../../../app/theme/taifa_typography.dart';
import '../../../shared/widgets/taifa_logo.dart';
import '../../ecosystem/application/ecosystem_modules_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Super-app directory — shows enabled modules from My Services.
class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.taifa;
    final modules = ref.watch(enabledModulesProvider).modules;
    final enabled = modules.where((m) => m.enabled && !m.meta.isCore).toList();

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            Row(
              children: [
                const TaifaLogo(variant: TaifaLogoVariant.mark, size: 36),
                const SizedBox(width: 10),
                Text(
                  'Everything',
                  style: TaifaTypography.sectionTitle(
                    palette.textPrimary,
                  ).copyWith(fontSize: 22),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${enabled.length} services enabled · manage in My Services',
              style: TextStyle(color: palette.textMuted),
            ),
            const SizedBox(height: 16),
            _MenuTile(
              label: 'My Services',
              subtitle: 'Enable or disable modules',
              icon: LucideIcons.layoutGrid,
              route: '/my-services',
              tint: TaifaColors.ocean400,
            ),
            ...enabled.map(
              (m) => _MenuTile(
                label: m.meta.name,
                subtitle: m.meta.subtitle.isNotEmpty
                    ? m.meta.subtitle
                    : (m.meta.isOps ? 'Operations' : 'Service'),
                icon: m.meta.icon,
                route: m.meta.route,
                tint: m.meta.tint,
              ),
            ),
            if (enabled.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No services enabled yet. Open My Services to turn modules on.',
                  style: TextStyle(color: palette.textMuted),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.route,
    required this.tint,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final String route;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => context.go(route),
          borderRadius: BorderRadius.circular(16),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: tint.withValues(alpha: 0.18),
              child: Icon(icon, color: tint),
            ),
            title: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: palette.textPrimary,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: TextStyle(color: palette.textMuted, fontSize: 12),
            ),
            trailing: Icon(LucideIcons.chevronRight, color: palette.textMuted),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/taifa_colors.dart';
import '../../../../app/theme/taifa_dimens.dart';
import '../../../../app/theme/taifa_icons.dart';
import '../../../../app/theme/taifa_theme.dart';
import '../../../../data/social/social_repository.dart';
import '../../../../shared/widgets/taifa_pressable.dart';

/// Shared chrome for the social-payments screens: back button + title, in the
/// same shape as `send_money_screen.dart`'s header.
class SocialScreenHeader extends StatelessWidget {
  const SocialScreenHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return Row(
      children: [
        InkWell(
          onTap: () => context.canPop() ? context.pop() : context.go('/wallet'),
          customBorder: const CircleBorder(),
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.surface,
              border: Border.all(color: palette.border),
            ),
            child: Icon(
              TaifaIcons.back,
              size: TaifaIconSize.md,
              color: palette.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: TaifaSpacing.md),
        Expanded(
          child: Text(
            title,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: palette.textPrimary),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

SnackBar _socialSnack({
  required String message,
  required Color background,
  required IconData icon,
}) {
  return SnackBar(
    backgroundColor: background,
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.all(TaifaSpacing.md),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(TaifaRadii.md),
    ),
    content: Row(
      children: [
        Icon(icon, size: TaifaIconSize.md, color: Colors.white),
        const SizedBox(width: TaifaSpacing.sm),
        Expanded(
          child: Text(message, style: const TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

void showSocialError(BuildContext context, Object error) {
  final message = error is SocialException
      ? error.message
      : 'Something went wrong.';
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      _socialSnack(
        message: message,
        background: TaifaColors.danger,
        icon: TaifaIcons.error,
      ),
    );
}

void showSocialSuccess(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      _socialSnack(
        message: message,
        background: TaifaColors.emerald700,
        icon: TaifaIcons.success,
      ),
    );
}

/// A card-style container matching the surface/border treatment used
/// throughout the wallet feature (`_SourceRow`, `_NoteField`, ...).
class SocialCard extends StatelessWidget {
  const SocialCard({super.key, required this.child, this.onTap, this.padding});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final card = Container(
      padding: padding ?? const EdgeInsets.all(TaifaSpacing.md),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(TaifaRadii.lg),
        border: Border.all(color: palette.border),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(TaifaRadii.lg),
      child: card,
    );
  }
}

/// An empty list is a moment to teach, not a dead end: the glyph sits in a
/// soft brand halo, the copy explains what the surface is for, and (where the
/// user can actually do something about it) a CTA starts the flow.
class SocialEmptyState extends StatelessWidget {
  const SocialEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.title,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;

  /// Supporting line. Kept as `message` so existing call sites still work.
  final String message;
  final String? title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: TaifaSpacing.xl,
          vertical: TaifaSpacing.xxxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Concentric halo — the same gold/emerald wash as the wallet card,
            // so an empty screen still feels like part of the brand.
            Container(
              width: 96,
              height: 96,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    TaifaColors.gold500.withValues(alpha: 0.16),
                    TaifaColors.emerald600.withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
              child: Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.surface,
                  border: Border.all(
                    color: TaifaColors.gold500.withValues(alpha: 0.22),
                  ),
                ),
                child: Icon(
                  icon,
                  size: TaifaIconSize.xl,
                  color: palette.accent,
                ),
              ),
            ),
            const SizedBox(height: TaifaSpacing.lg),
            if (title != null) ...[
              Text(
                title!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: TaifaSpacing.xs),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: palette.textMuted,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: TaifaSpacing.lg),
              SizedBox(
                width: 220,
                child: SocialPrimaryButton(
                  label: actionLabel!,
                  onTap: onAction!,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SocialPrimaryButton extends StatelessWidget {
  const SocialPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.loading = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onTap;
  final bool loading;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final active = enabled && !loading;
    return TaifaPressable(
      onTap: active ? onTap : null,
      semanticLabel: label,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: TaifaColors.goldGradient,
          borderRadius: BorderRadius.circular(TaifaRadii.xl),
          boxShadow: [
            BoxShadow(
              color: TaifaColors.gold500.withValues(alpha: 0.28),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
      ),
    );
  }
}

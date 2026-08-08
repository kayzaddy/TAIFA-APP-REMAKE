import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/taifa_colors.dart';
import '../../../../app/theme/taifa_dimens.dart';
import '../../../../app/theme/taifa_theme.dart';
import '../../../../data/social/social_repository.dart';

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
            child: Icon(Icons.arrow_back_rounded, size: 18, color: palette.textPrimary),
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

void showSocialError(BuildContext context, Object error) {
  final message = error is SocialException ? error.message : 'Something went wrong.';
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: TaifaColors.danger,
        content: Text(message, style: const TextStyle(color: Colors.white)),
      ),
    );
}

void showSocialSuccess(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: TaifaColors.emerald700,
        content: Text(message, style: const TextStyle(color: Colors.white)),
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

class SocialEmptyState extends StatelessWidget {
  const SocialEmptyState({super.key, required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TaifaSpacing.xxxl),
      child: Column(
        children: [
          Icon(icon, size: 40, color: palette.textMuted),
          const SizedBox(height: TaifaSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: palette.textMuted),
          ),
        ],
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
    return GestureDetector(
      onTap: active ? onTap : null,
      child: AnimatedOpacity(
        duration: TaifaMotion.fast,
        opacity: active ? 1 : 0.5,
        child: Container(
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: TaifaColors.goldGradient,
            borderRadius: BorderRadius.circular(TaifaRadii.xl),
          ),
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                )
              : Text(
                  label,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.black),
                ),
        ),
      ),
    );
  }
}

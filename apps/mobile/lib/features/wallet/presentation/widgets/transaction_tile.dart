import 'package:flutter/material.dart';

import '../../../../app/theme/taifa_colors.dart';
import '../../../../app/theme/taifa_dimens.dart';
import '../../../../app/theme/taifa_theme.dart';
import '../../domain/transaction.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A single row in the recent-transactions list. Matches the mockup's txn rows:
/// tinted status icon, counterparty + context, signed amount.
class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.transaction});

  final WalletTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    final t = transaction;
    final isCredit = t.isCredit;

    final (icon, tint) = _visual(t);
    final amountColor = isCredit
        ? TaifaColors.emerald500
        : (t.status == TransactionStatus.failed
              ? TaifaColors.dangerSoft
              : palette.textPrimary);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TaifaSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tint.withValues(alpha: 0.14),
            ),
            child: Icon(icon, size: 17, color: tint),
          ),
          const SizedBox(width: TaifaSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.counterparty,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _subtitle(t),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 9, color: palette.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: TaifaSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                t.signedAmount.format(withSign: true),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: amountColor,
                ),
              ),
              if (t.status != TransactionStatus.succeeded)
                Text(
                  _statusLabel(t.status),
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: t.status == TransactionStatus.failed
                        ? TaifaColors.dangerSoft
                        : palette.accent,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  (IconData, Color) _visual(WalletTransaction t) {
    if (t.isCredit) return (LucideIcons.arrowDownLeft, TaifaColors.emerald500);
    return switch (t.type) {
      TransactionType.rideFare => (
        LucideIcons.carTaxiFront,
        TaifaColors.dangerSoft,
      ),
      TransactionType.billPayment => (LucideIcons.zap, TaifaColors.gold400),
      TransactionType.sendMoney => (
        LucideIcons.arrowUpRight,
        TaifaColors.gold400,
      ),
      _ => (LucideIcons.arrowUpRight, TaifaColors.ocean400),
    };
  }

  String _subtitle(WalletTransaction t) {
    final when = _relative(t.createdAt);
    return '${t.type.label} · ${t.method.label} · $when';
  }

  String _statusLabel(TransactionStatus s) => switch (s) {
    TransactionStatus.processing => 'Processing',
    TransactionStatus.pending => 'Pending',
    TransactionStatus.failed => 'Failed',
    TransactionStatus.reversed => 'Reversed',
    TransactionStatus.succeeded => '',
  };

  static String _relative(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/taifa_colors.dart';
import '../../../app/theme/taifa_dimens.dart';
import '../../../app/theme/taifa_theme.dart';
import '../../../app/theme/taifa_typography.dart';
import '../application/transit_providers.dart';

/// Full-screen digital boarding pass (signed QR payload as scannable text block).
class TransitQrScreen extends ConsumerStatefulWidget {
  const TransitQrScreen({super.key});

  @override
  ConsumerState<TransitQrScreen> createState() => _TransitQrScreenState();
}

class _TransitQrScreenState extends ConsumerState<TransitQrScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ticket = ref.watch(transitControllerProvider).activeTicket;
    final palette = context.taifa;

    if (ticket == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Boarding pass')),
        body: Center(
          child: Text(
            'No active ticket. Buy a ride from Transit Home.',
            style: TextStyle(color: palette.textMuted),
          ),
        ),
      );
    }

    final payload = jsonEncode(ticket.qr);
    final expires = DateTime.tryParse(ticket.validTo);

    return Scaffold(
      backgroundColor: TaifaColors.black900,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Boarding pass'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(TaifaSpacing.screenH),
        child: Column(
          children: [
            Text(
              ticket.routeName.isNotEmpty ? ticket.routeName : 'Mwendokasi BRT',
              style: TaifaTypography.sectionTitle(Colors.white).copyWith(
                fontSize: 22,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              ticket.mediaCode,
              style: const TextStyle(
                color: TaifaColors.gold400,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: TaifaSpacing.lg),
            Expanded(
              child: Center(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.qr_code_2_rounded,
                        size: 120,
                        color: TaifaColors.emerald900,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        ticket.mediaCode,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: TaifaColors.black900,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Show this code to the conductor or validator device.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: TaifaColors.black900.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: TaifaSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: SelectableText(
                payload,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontFamily: 'monospace',
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Meta(
                  label: 'Fare',
                  value: ticket.fare.format(),
                ),
                _Meta(
                  label: 'Valid until',
                  value: expires != null
                      ? '${expires.hour.toString().padLeft(2, '0')}:${expires.minute.toString().padLeft(2, '0')}'
                      : '—',
                ),
                _Meta(
                  label: 'Status',
                  value: ticket.status.toUpperCase(),
                ),
              ],
            ),
            const SizedBox(height: TaifaSpacing.lg),
            OutlinedButton.icon(
              onPressed: () async {
                final port = ref.read(nfcBoardingPortProvider);
                final available = await port.isAvailable;
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      available
                          ? 'NFC token: ${await port.readTransitToken() ?? ticket.mediaCode}'
                          : 'NFC simulated — use media code ${ticket.mediaCode} at validators',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.nfc_rounded),
              label: const Text('Simulate NFC tap'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

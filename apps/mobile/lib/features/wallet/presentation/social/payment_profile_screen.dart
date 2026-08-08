import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/taifa_dimens.dart';
import '../../../../app/theme/taifa_theme.dart';
import '../../application/social_providers.dart';
import 'social_widgets.dart';

/// Lets the wallet owner set the phone number + display name that make them
/// findable by contacts/money-requests/split-bills/standing orders, and
/// toggle self-service merchant mode (adds a platform fee to payment links
/// created afterwards).
class PaymentProfileScreen extends ConsumerStatefulWidget {
  const PaymentProfileScreen({super.key});

  @override
  ConsumerState<PaymentProfileScreen> createState() => _PaymentProfileScreenState();
}

class _PaymentProfileScreenState extends ConsumerState<PaymentProfileScreen> {
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  bool _savingProfile = false;
  bool? _isMerchant;
  bool _savingMerchant = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: TaifaSpacing.screenH),
          child: Column(
            children: [
              const SizedBox(height: TaifaSpacing.sm),
              const SocialScreenHeader(title: 'Profile & Merchant'),
              const SizedBox(height: TaifaSpacing.xl),
              Expanded(
                child: ListView(
                  children: [
                    Text('FINDABLE BY PHONE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1, color: palette.textMuted)),
                    Text(
                      'Set your number so friends can pay/request you and split bills with you.',
                      style: TextStyle(fontSize: 10, color: palette.textMuted),
                    ),
                    const SizedBox(height: TaifaSpacing.sm),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(color: palette.textPrimary),
                      decoration: const InputDecoration(labelText: 'Phone number', hintText: '+255...'),
                    ),
                    const SizedBox(height: TaifaSpacing.sm),
                    TextField(
                      controller: _nameController,
                      style: TextStyle(color: palette.textPrimary),
                      decoration: const InputDecoration(labelText: 'Display name'),
                    ),
                    const SizedBox(height: TaifaSpacing.md),
                    SocialPrimaryButton(label: 'Save profile', loading: _savingProfile, onTap: _saveProfile),
                    const SizedBox(height: TaifaSpacing.xxl),
                    Divider(color: palette.border),
                    const SizedBox(height: TaifaSpacing.lg),
                    Text('MERCHANT MODE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1, color: palette.textMuted)),
                    const SizedBox(height: TaifaSpacing.xs),
                    SocialCard(
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _isMerchant ?? false,
                        onChanged: _savingMerchant ? null : _toggleMerchant,
                        title: Text('Accept payments as a merchant', style: TextStyle(fontSize: 12, color: palette.textPrimary)),
                        subtitle: Text(
                          'Payment links you create afterwards carry a small platform fee — customers still pay the sticker price.',
                          style: TextStyle(fontSize: 10, color: palette.textMuted),
                        ),
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

  Future<void> _saveProfile() async {
    setState(() => _savingProfile = true);
    try {
      await ref.read(socialRepositoryProvider).setMyProfile(
        phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        displayName: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
      );
      if (mounted) {
        setState(() => _savingProfile = false);
        showSocialSuccess(context, 'Profile saved.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _savingProfile = false);
        showSocialError(context, e);
      }
    }
  }

  Future<void> _toggleMerchant(bool value) async {
    setState(() {
      _isMerchant = value;
      _savingMerchant = true;
    });
    try {
      final result = await ref.read(socialRepositoryProvider).setMerchantMode(value);
      if (mounted) {
        setState(() {
          _isMerchant = result.isMerchant;
          _savingMerchant = false;
        });
        showSocialSuccess(
          context,
          result.isMerchant ? 'Merchant mode on — fee ${result.feeBps / 100}% on new links.' : 'Merchant mode off.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isMerchant = !value;
          _savingMerchant = false;
        });
        showSocialError(context, e);
      }
    }
  }
}

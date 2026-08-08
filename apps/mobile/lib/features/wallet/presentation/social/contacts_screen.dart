import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/taifa_colors.dart';
import '../../../../app/theme/taifa_dimens.dart';
import '../../../../app/theme/taifa_theme.dart';
import '../../../../data/dto/social_dto.dart';
import '../../application/social_providers.dart';
import 'social_widgets.dart';

class ContactsScreen extends ConsumerWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(contactsProvider);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: TaifaSpacing.screenH),
          child: Column(
            children: [
              const SizedBox(height: TaifaSpacing.sm),
              SocialScreenHeader(
                title: 'Contacts',
                trailing: IconButton(
                  icon: const Icon(Icons.person_add_rounded),
                  onPressed: () async {
                    final added = await showModalBottomSheet<bool>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: context.taifa.background,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(TaifaRadii.nav))),
                      builder: (_) => const _AddContactSheet(),
                    );
                    if (added == true) ref.invalidate(contactsProvider);
                  },
                ),
              ),
              const SizedBox(height: TaifaSpacing.lg),
              Expanded(
                child: contactsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Could not load contacts.\n$e', textAlign: TextAlign.center)),
                  data: (contacts) {
                    if (contacts.isEmpty) {
                      return const SocialEmptyState(icon: Icons.contacts_rounded, message: 'No saved contacts yet.\nAdd someone by their phone number.');
                    }
                    final favorites = contacts.where((c) => c.favorite).toList();
                    final others = contacts.where((c) => !c.favorite).toList();
                    return RefreshIndicator(
                      onRefresh: () async => ref.invalidate(contactsProvider),
                      child: ListView(
                        children: [
                          if (favorites.isNotEmpty) ...[
                            _SectionLabel('Favorites'),
                            for (final c in favorites) _ContactTile(contact: c),
                            const SizedBox(height: TaifaSpacing.md),
                          ],
                          if (others.isNotEmpty) ...[
                            _SectionLabel('All contacts'),
                            for (final c in others) _ContactTile(contact: c),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: TaifaSpacing.xs),
    child: Text(text.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1, color: context.taifa.textMuted)),
  );
}

class _ContactTile extends ConsumerWidget {
  const _ContactTile({required this.contact});
  final TaifaContact contact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.taifa;
    return Padding(
      padding: const EdgeInsets.only(bottom: TaifaSpacing.sm),
      child: SocialCard(
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: TaifaColors.gold500.withValues(alpha: 0.2),
              child: Text(
                contact.displayName.isNotEmpty ? contact.displayName[0].toUpperCase() : '?',
                style: const TextStyle(color: TaifaColors.gold400, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: TaifaSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(contact.displayName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: palette.textPrimary)),
                  Text(contact.phoneNumber, style: TextStyle(fontSize: 10, color: palette.textMuted)),
                ],
              ),
            ),
            IconButton(
              icon: Icon(contact.favorite ? Icons.star_rounded : Icons.star_border_rounded, color: contact.favorite ? TaifaColors.gold500 : palette.textMuted, size: 20),
              onPressed: () async {
                try {
                  await ref.read(socialRepositoryProvider).toggleFavorite(contact.id, !contact.favorite);
                  ref.invalidate(contactsProvider);
                } catch (e) {
                  if (context.mounted) showSocialError(context, e);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              onPressed: () async {
                try {
                  await ref.read(socialRepositoryProvider).removeContact(contact.id);
                  ref.invalidate(contactsProvider);
                } catch (e) {
                  if (context.mounted) showSocialError(context, e);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AddContactSheet extends ConsumerStatefulWidget {
  const _AddContactSheet();

  @override
  ConsumerState<_AddContactSheet> createState() => _AddContactSheetState();
}

class _AddContactSheetState extends ConsumerState<_AddContactSheet> {
  final _phoneController = TextEditingController();
  final _labelController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return Padding(
      padding: EdgeInsets.only(
        left: TaifaSpacing.screenH,
        right: TaifaSpacing.screenH,
        top: TaifaSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + TaifaSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add contact', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: palette.textPrimary)),
          const SizedBox(height: TaifaSpacing.lg),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: TextStyle(color: palette.textPrimary),
            decoration: const InputDecoration(labelText: 'Phone number', hintText: '+255...'),
          ),
          const SizedBox(height: TaifaSpacing.sm),
          TextField(
            controller: _labelController,
            style: TextStyle(color: palette.textPrimary),
            decoration: const InputDecoration(labelText: 'Label (optional)', hintText: 'Best friend'),
          ),
          const SizedBox(height: TaifaSpacing.md),
          SocialPrimaryButton(label: 'Save contact', loading: _saving, onTap: _submit),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      showSocialError(context, Exception('Enter a phone number.'));
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(socialRepositoryProvider).addContact(phone, label: _labelController.text.trim());
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showSocialError(context, e);
      }
    }
  }
}

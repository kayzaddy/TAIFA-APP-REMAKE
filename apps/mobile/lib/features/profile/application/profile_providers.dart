import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/profile_models.dart';

abstract interface class ProfileRepository {
  Future<UserProfile> load();
  Future<UserProfile> save(UserProfile profile);
}

class SeedProfileRepository implements ProfileRepository {
  static const _kName = 'taifa_profile_name';
  static const _kPhone = 'taifa_profile_phone';
  static const _kLang = 'taifa_profile_lang';

  @override
  Future<UserProfile> load() async {
    final prefs = await SharedPreferences.getInstance();
    return UserProfile(
      displayName: prefs.getString(_kName) ?? 'Amani',
      phone: prefs.getString(_kPhone) ?? '+255 712 000 441',
      email: 'amani@taifa.app',
      city: 'Dar es Salaam',
      preferredLanguage: prefs.getString(_kLang) ?? 'sw',
    );
  }

  @override
  Future<UserProfile> save(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kName, profile.displayName);
    await prefs.setString(_kPhone, profile.phone);
    await prefs.setString(_kLang, profile.preferredLanguage);
    return profile;
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => SeedProfileRepository(),
);

class ProfileUiState {
  const ProfileUiState({
    this.profile,
    this.isBusy = false,
    this.saved = false,
    this.error,
  });

  final UserProfile? profile;
  final bool isBusy;
  final bool saved;
  final String? error;

  ProfileUiState copyWith({
    UserProfile? profile,
    bool? isBusy,
    bool? saved,
    String? error,
    bool clearError = false,
  }) {
    return ProfileUiState(
      profile: profile ?? this.profile,
      isBusy: isBusy ?? this.isBusy,
      saved: saved ?? this.saved,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ProfileController extends Notifier<ProfileUiState> {
  ProfileRepository get _repo => ref.read(profileRepositoryProvider);

  @override
  ProfileUiState build() => const ProfileUiState(isBusy: true);

  Future<void> bootstrap() async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final p = await _repo.load();
      state = state.copyWith(profile: p, isBusy: false, saved: false);
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  void updateName(String v) {
    final p = state.profile;
    if (p == null) return;
    state = state.copyWith(profile: p.copyWith(displayName: v), saved: false);
  }

  void updatePhone(String v) {
    final p = state.profile;
    if (p == null) return;
    state = state.copyWith(profile: p.copyWith(phone: v), saved: false);
  }

  void updateLanguage(String code) {
    final p = state.profile;
    if (p == null) return;
    state = state.copyWith(
      profile: p.copyWith(preferredLanguage: code),
      saved: false,
    );
  }

  Future<void> save() async {
    final p = state.profile;
    if (p == null) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final saved = await _repo.save(p);
      state = state.copyWith(profile: saved, isBusy: false, saved: true);
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }
}

final profileControllerProvider =
    NotifierProvider<ProfileController, ProfileUiState>(ProfileController.new);

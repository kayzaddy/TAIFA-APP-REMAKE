import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../core/auth_token_storage.dart';
import '../core/merchant_api_client.dart';

class MerchantAuthState {
  const MerchantAuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.merchantId,
    this.email,
    this.roles = const [],
    this.error,
  });

  final bool isLoading;
  final bool isAuthenticated;
  final String? merchantId;
  final String? email;
  final List<String> roles;
  final String? error;

  MerchantAuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    String? merchantId,
    String? email,
    List<String>? roles,
    String? error,
  }) {
    return MerchantAuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      merchantId: merchantId ?? this.merchantId,
      email: email ?? this.email,
      roles: roles ?? this.roles,
      error: error,
    );
  }
}

final merchantAuthControllerProvider =
    NotifierProvider<MerchantAuthController, MerchantAuthState>(MerchantAuthController.new);

class MerchantAuthController extends Notifier<MerchantAuthState> {
  @override
  MerchantAuthState build() => const MerchantAuthState();

  MerchantApiClient get _api => ref.read(merchantApiClientProvider);
  MerchantAuthStorage get _storage => ref.read(merchantAuthStorageProvider);

  Future<void> bootstrap() async {
    final token = await _storage.readAccessToken();
    if (token == null || token.isEmpty) return;
    state = state.copyWith(isLoading: true);
    try {
      final session = await _api.session();
      state = MerchantAuthState(
        isAuthenticated: true,
        email: session['email'] as String?,
        merchantId: session['merchant_id'] as String?,
        roles: (session['roles'] as List<dynamic>? ?? []).cast<String>(),
      );
    } catch (_) {
      await _storage.clear();
      state = const MerchantAuthState();
    }
  }

  Future<bool> signup({
    required String email,
    required String password,
    String fullName = '',
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.signup({
        'email': email,
        'password': password,
        'full_name': fullName,
      });
      await _storage.writeAccessToken(res['access_token'] as String);
      state = MerchantAuthState(
        isAuthenticated: true,
        email: email,
        merchantId: res['merchant_id'] as String?,
        roles: (res['roles'] as List<dynamic>? ?? []).cast<String>(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.login({'email': email, 'password': password});
      if (res['mfa_required'] == true) {
        state = state.copyWith(isLoading: false, error: 'MFA required — use MFA flow');
        return false;
      }
      await _storage.writeAccessToken(res['access_token'] as String);
      state = MerchantAuthState(
        isAuthenticated: true,
        email: email,
        merchantId: res['merchant_id'] as String?,
        roles: (res['roles'] as List<dynamic>? ?? []).cast<String>(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } catch (_) {}
    await _storage.clear();
    state = const MerchantAuthState();
  }
}

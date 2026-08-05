import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/tap_pay/rest_tap_repository.dart';
import '../../wallet/application/wallet_providers.dart'
    show apiClientProvider, apiConfigProvider;
import '../domain/tap_models.dart';
import 'seed_tap_repository.dart';
import 'tap_repository.dart';

final tapPayRepositoryProvider = Provider<TapPayRepository>((ref) {
  final config = ref.watch(apiConfigProvider);
  if (config.useRemoteBackend) {
    return RestTapPayRepository(ref.watch(apiClientProvider));
  }
  return SeedTapPayRepository();
});

class TapPayUiState {
  const TapPayUiState({
    this.phase = TapPhase.ready,
    this.prefs,
    this.session,
    this.amountMinor = 2500,
    this.message,
    this.error,
    this.isBusy = false,
  });

  final TapPhase phase;
  final TapFundingPrefs? prefs;
  final TapSession? session;
  final int amountMinor;
  final String? message;
  final String? error;
  final bool isBusy;

  TapPayUiState copyWith({
    TapPhase? phase,
    TapFundingPrefs? prefs,
    TapSession? session,
    int? amountMinor,
    String? message,
    String? error,
    bool? isBusy,
    bool clearError = false,
  }) {
    return TapPayUiState(
      phase: phase ?? this.phase,
      prefs: prefs ?? this.prefs,
      session: session ?? this.session,
      amountMinor: amountMinor ?? this.amountMinor,
      message: message ?? this.message,
      error: clearError ? null : (error ?? this.error),
      isBusy: isBusy ?? this.isBusy,
    );
  }
}

enum TapPhase { ready, detecting, auth, success, fallback, failed }

class TapPayController extends Notifier<TapPayUiState> {
  @override
  TapPayUiState build() => const TapPayUiState();

  TapPayRepository get _repo => ref.read(tapPayRepositoryProvider);

  Future<void> loadPrefs() async {
    try {
      final prefs = await _repo.fundingPrefs();
      state = state.copyWith(prefs: prefs);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void setAmount(int minor) => state = state.copyWith(amountMinor: minor);

  Future<void> simulateTap() async {
    state = state.copyWith(
      isBusy: true,
      phase: TapPhase.detecting,
      clearError: true,
      message: 'Detecting terminal…',
    );
    try {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      final result = await _repo.startTap(
        merchantId: '',
        amountMinor: state.amountMinor,
        channel: 'nfc',
        terminalCode: 'SOFTPOS-1',
      );
      final session = result.session;
      state = state.copyWith(
        session: session,
        isBusy: false,
        phase: session.needsAuth ? TapPhase.auth : TapPhase.detecting,
        message: session.needsAuth
            ? 'Authenticate to pay ${session.merchantDisplay}'
            : 'Confirming…',
      );
      if (!session.needsAuth) {
        await confirm();
      }
    } catch (e) {
      state = state.copyWith(
        isBusy: false,
        phase: TapPhase.failed,
        error: e.toString(),
      );
    }
  }

  Future<void> authenticate({String method = 'biometric'}) async {
    final code = state.session?.publicCode;
    if (code == null) return;
    state = state.copyWith(isBusy: true, clearError: true, message: 'Verifying…');
    try {
      final session = await _repo.authenticate(code, method: method);
      state = state.copyWith(session: session, isBusy: false);
      await confirm();
    } catch (e) {
      state = state.copyWith(isBusy: false, phase: TapPhase.failed, error: e.toString());
    }
  }

  Future<void> confirm() async {
    final code = state.session?.publicCode;
    if (code == null) return;
    state = state.copyWith(isBusy: true, message: 'Authorizing payment…');
    try {
      final session = await _repo.confirm(code);
      state = state.copyWith(
        session: session,
        isBusy: false,
        phase: session.isSuccess
            ? TapPhase.success
            : (session.status == 'fallback' ? TapPhase.fallback : TapPhase.failed),
        message: session.isSuccess ? 'Payment complete' : session.failureReason,
      );
    } catch (e) {
      final msg = e.toString();
      state = state.copyWith(
        isBusy: false,
        phase: msg.contains('insufficient') ? TapPhase.fallback : TapPhase.failed,
        error: msg,
        message: msg.contains('insufficient')
            ? 'Fund wallet or choose next source'
            : msg,
      );
    }
  }

  void reset() {
    state = TapPayUiState(prefs: state.prefs, amountMinor: state.amountMinor);
  }
}

final tapPayControllerProvider =
    NotifierProvider<TapPayController, TapPayUiState>(TapPayController.new);

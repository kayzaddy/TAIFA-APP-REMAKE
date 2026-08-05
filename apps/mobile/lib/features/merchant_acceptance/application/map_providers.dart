import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/merchant_acceptance/rest_map_repository.dart';
import '../../wallet/application/wallet_providers.dart'
    show apiClientProvider, apiConfigProvider;
import '../domain/map_models.dart';
import 'map_repository.dart';
import 'seed_map_repository.dart';

final mapRepositoryProvider = Provider<MapRepository>((ref) {
  final config = ref.watch(apiConfigProvider);
  if (config.useRemoteBackend) {
    return RestMapRepository(ref.watch(apiClientProvider));
  }
  return SeedMapRepository();
});

class MapUiState {
  const MapUiState({
    this.profile,
    this.analytics = const MapAnalytics(),
    this.lastQr,
    this.lastLink,
    this.lastInvoice,
    this.lastReceipt,
    this.lastIntent,
    this.isBusy = false,
    this.error,
    this.message,
  });

  final MapProfile? profile;
  final MapAnalytics analytics;
  final MapQr? lastQr;
  final MapPaymentLink? lastLink;
  final MapInvoice? lastInvoice;
  final MapReceipt? lastReceipt;
  final MapIntent? lastIntent;
  final bool isBusy;
  final String? error;
  final String? message;

  MapUiState copyWith({
    MapProfile? profile,
    MapAnalytics? analytics,
    MapQr? lastQr,
    MapPaymentLink? lastLink,
    MapInvoice? lastInvoice,
    MapReceipt? lastReceipt,
    MapIntent? lastIntent,
    bool? isBusy,
    String? error,
    String? message,
    bool clearError = false,
  }) {
    return MapUiState(
      profile: profile ?? this.profile,
      analytics: analytics ?? this.analytics,
      lastQr: lastQr ?? this.lastQr,
      lastLink: lastLink ?? this.lastLink,
      lastInvoice: lastInvoice ?? this.lastInvoice,
      lastReceipt: lastReceipt ?? this.lastReceipt,
      lastIntent: lastIntent ?? this.lastIntent,
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : (error ?? this.error),
      message: message ?? this.message,
    );
  }
}

class MapController extends Notifier<MapUiState> {
  @override
  MapUiState build() => const MapUiState();

  MapRepository get _repo => ref.read(mapRepositoryProvider);

  Future<void> bootstrap() async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final profile = await _repo.bootstrap();
      final analytics = await _repo.analytics();
      state = state.copyWith(
        profile: profile,
        analytics: analytics,
        isBusy: false,
        message: 'Acceptance profile ready',
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> refreshAnalytics() async {
    try {
      final analytics = await _repo.analytics();
      state = state.copyWith(analytics: analytics);
    } catch (_) {}
  }

  Future<void> issueDynamicQr(int amountMinor, {String description = ''}) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final result = await _repo.issueQr(
        amountMinor: amountMinor,
        kind: 'dynamic',
        description: description,
      );
      state = state.copyWith(
        lastQr: result.qr,
        lastIntent: result.intent,
        isBusy: false,
        message: 'Dynamic QR issued',
      );
      await refreshAnalytics();
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> issueStaticQr() async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final result = await _repo.issueQr(amountMinor: null, kind: 'static');
      state = state.copyWith(
        lastQr: result.qr,
        isBusy: false,
        message: 'Static merchant QR ready',
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> createLink(int amountMinor) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final link = await _repo.createLink(amountMinor: amountMinor);
      state = state.copyWith(
        lastLink: link,
        isBusy: false,
        message: 'Payment link created',
      );
      await refreshAnalytics();
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> createInvoice(String number, int amountMinor) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final inv = await _repo.createInvoice(
        invoiceNumber: number,
        amountMinor: amountMinor,
      );
      state = state.copyWith(
        lastInvoice: inv,
        isBusy: false,
        message: 'Invoice $number created',
      );
      await refreshAnalytics();
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> payCode(String publicCode) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final result = await _repo.payIntent(publicCode);
      state = state.copyWith(
        lastIntent: result.intent,
        lastReceipt: result.receipt,
        isBusy: false,
        message: 'Payment captured via Taifa Payments',
      );
      await refreshAnalytics();
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> payLink(String pathToken) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final resolved = await _repo.resolveLink(pathToken);
      final result = await _repo.payIntent(resolved.intent.publicCode);
      state = state.copyWith(
        lastLink: resolved.link,
        lastIntent: result.intent,
        lastReceipt: result.receipt,
        isBusy: false,
        message: 'Paid ${resolved.merchantDisplay}',
      );
      await refreshAnalytics();
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }
}

final mapControllerProvider = NotifierProvider<MapController, MapUiState>(MapController.new);

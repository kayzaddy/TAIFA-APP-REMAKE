import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/nfc_catalog.dart';
import '../domain/nfc_models.dart';

class NfcUiState {
  const NfcUiState({
    this.phase = NfcPhase.home,
    this.packs = const [],
    this.selected,
    this.error,
  });

  final NfcPhase phase;
  final List<NfcPack> packs;
  final NfcPack? selected;
  final String? error;

  NfcUiState copyWith({
    NfcPhase? phase,
    List<NfcPack>? packs,
    NfcPack? selected,
    String? error,
    bool clearSelected = false,
    bool clearError = false,
  }) {
    return NfcUiState(
      phase: phase ?? this.phase,
      packs: packs ?? this.packs,
      selected: clearSelected ? null : (selected ?? this.selected),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class NfcController extends Notifier<NfcUiState> {
  Timer? _scan;

  @override
  NfcUiState build() {
    ref.onDispose(() => _scan?.cancel());
    return NfcUiState(packs: NfcCatalog.packs());
  }

  void backHome() {
    _scan?.cancel();
    state = state.copyWith(
      phase: NfcPhase.home,
      clearSelected: true,
      clearError: true,
    );
  }

  void simulateTap(NfcPack pack) {
    _scan?.cancel();
    state = state.copyWith(
      phase: NfcPhase.scanning,
      selected: pack,
      clearError: true,
    );
    _scan = Timer(const Duration(milliseconds: 1400), () {
      if (!ref.mounted) return;
      state = state.copyWith(phase: NfcPhase.result);
    });
  }
}

final nfcControllerProvider = NotifierProvider<NfcController, NfcUiState>(
  NfcController.new,
);

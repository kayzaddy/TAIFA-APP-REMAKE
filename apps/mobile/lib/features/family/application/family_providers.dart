import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/family/rest_family_repository.dart';
import '../../wallet/application/wallet_providers.dart'
    show apiClientProvider, apiConfigProvider;
import '../../wallet/domain/currency.dart';
import '../../wallet/domain/money.dart';
import '../domain/family_models.dart';
import 'family_repository.dart';

/// Seed offline, or live transfers when `TAIFA_USE_REMOTE=true`.
final familyRepositoryProvider = Provider<FamilyRepository>((ref) {
  final config = ref.watch(apiConfigProvider);
  if (config.useRemoteBackend) {
    return RestFamilyRepository(ref.watch(apiClientProvider));
  }
  return SeedFamilyRepository();
});

enum FamilyPhase { home, detail, confirm, receipt, history }

class FamilyUiState {
  const FamilyUiState({
    this.phase = FamilyPhase.home,
    this.members = const [],
    this.selected,
    this.amountMajor = 20000,
    this.kind = FamilyTxKind.send,
    this.note = 'Monthly allowance',
    this.transfer,
    this.history = const [],
    this.isBusy = false,
    this.error,
  });

  final FamilyPhase phase;
  final List<FamilyMember> members;
  final FamilyMember? selected;
  final int amountMajor;
  final FamilyTxKind kind;
  final String note;
  final FamilyTransfer? transfer;
  final List<FamilyTransfer> history;
  final bool isBusy;
  final String? error;

  Money get amount => Money.major(amountMajor, Currency.tzs);

  FamilyUiState copyWith({
    FamilyPhase? phase,
    List<FamilyMember>? members,
    FamilyMember? selected,
    int? amountMajor,
    FamilyTxKind? kind,
    String? note,
    FamilyTransfer? transfer,
    List<FamilyTransfer>? history,
    bool? isBusy,
    String? error,
    bool clearSelected = false,
    bool clearTransfer = false,
    bool clearError = false,
  }) {
    return FamilyUiState(
      phase: phase ?? this.phase,
      members: members ?? this.members,
      selected: clearSelected ? null : (selected ?? this.selected),
      amountMajor: amountMajor ?? this.amountMajor,
      kind: kind ?? this.kind,
      note: note ?? this.note,
      transfer: clearTransfer ? null : (transfer ?? this.transfer),
      history: history ?? this.history,
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class FamilyController extends Notifier<FamilyUiState> {
  FamilyRepository get _repo => ref.read(familyRepositoryProvider);

  @override
  FamilyUiState build() => const FamilyUiState();

  Future<void> bootstrap() async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final members = await _repo.members();
      final history = await _repo.history();
      state = state.copyWith(
        members: members,
        history: history,
        isBusy: false,
        phase: FamilyPhase.home,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  void open(FamilyMember member) => state = state.copyWith(
    selected: member,
    phase: FamilyPhase.detail,
    clearTransfer: true,
    clearError: true,
  );

  void backHome() => state = state.copyWith(
    phase: FamilyPhase.home,
    clearSelected: true,
    clearTransfer: true,
    clearError: true,
  );

  void setKind(FamilyTxKind kind) => state = state.copyWith(kind: kind);

  void setAmount(int major) =>
      state = state.copyWith(amountMajor: major.clamp(1000, 2000000));

  void setNote(String note) => state = state.copyWith(note: note);

  void goConfirm() {
    if (state.selected == null) return;
    state = state.copyWith(phase: FamilyPhase.confirm, clearError: true);
  }

  Future<void> submit() async {
    final member = state.selected;
    if (member == null) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final draft = FamilyTransfer(
        id: 'draft',
        member: member,
        amount: state.amount,
        kind: state.kind,
        status: FamilyTxStatus.drafting,
        createdAt: DateTime.now(),
        note: state.note,
      );
      final paid = await _repo.send(draft);
      state = state.copyWith(
        transfer: paid,
        history: await _repo.history(),
        isBusy: false,
        phase: FamilyPhase.receipt,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  void openHistory() => state = state.copyWith(phase: FamilyPhase.history);
}

final familyControllerProvider =
    NotifierProvider<FamilyController, FamilyUiState>(FamilyController.new);

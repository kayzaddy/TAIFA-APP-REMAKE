import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/education/rest_edu_payment_repository.dart';
import '../../wallet/application/wallet_providers.dart'
    show apiClientProvider, apiConfigProvider;
import '../domain/education_models.dart';
import 'education_repository.dart';

final schoolRepositoryProvider = Provider<SchoolRepository>(
  (ref) => SeedSchoolRepository(),
);

/// Seed offline, or live commerce API when `TAIFA_USE_REMOTE=true`.
final eduPaymentRepositoryProvider = Provider<EduPaymentRepository>((ref) {
  final config = ref.watch(apiConfigProvider);
  if (config.useRemoteBackend) {
    return RestEduPaymentRepository(ref.watch(apiClientProvider));
  }
  return SeedEduPaymentRepository();
});

enum EducationPhase { home, detail, checkout, invoiced, receipt, history }

class EducationUiState {
  const EducationUiState({
    this.phase = EducationPhase.home,
    this.schools = const [],
    this.query = '',
    this.selected,
    this.studentName = 'Neema Juma',
    this.payment,
    this.history = const [],
    this.isBusy = false,
    this.error,
  });

  final EducationPhase phase;
  final List<School> schools;
  final String query;
  final School? selected;
  final String studentName;
  final EduPayment? payment;
  final List<EduPayment> history;
  final bool isBusy;
  final String? error;

  EducationUiState copyWith({
    EducationPhase? phase,
    List<School>? schools,
    String? query,
    School? selected,
    String? studentName,
    EduPayment? payment,
    List<EduPayment>? history,
    bool? isBusy,
    String? error,
    bool clearSelected = false,
    bool clearPayment = false,
    bool clearError = false,
  }) {
    return EducationUiState(
      phase: phase ?? this.phase,
      schools: schools ?? this.schools,
      query: query ?? this.query,
      selected: clearSelected ? null : (selected ?? this.selected),
      studentName: studentName ?? this.studentName,
      payment: clearPayment ? null : (payment ?? this.payment),
      history: history ?? this.history,
      isBusy: isBusy ?? this.isBusy,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class EducationController extends Notifier<EducationUiState> {
  SchoolRepository get _schools => ref.read(schoolRepositoryProvider);
  EduPaymentRepository get _payments => ref.read(eduPaymentRepositoryProvider);

  @override
  EducationUiState build() => const EducationUiState();

  Future<void> bootstrap() async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final list = await _schools.list();
      final history = await _payments.history();
      state = state.copyWith(
        schools: list,
        history: history,
        isBusy: false,
        phase: EducationPhase.home,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> search(String q) async {
    state = state.copyWith(query: q, isBusy: true, clearError: true);
    state = state.copyWith(
      schools: await _schools.list(query: q),
      isBusy: false,
    );
  }

  void open(School s) => state = state.copyWith(
    selected: s,
    phase: EducationPhase.detail,
    clearPayment: true,
    clearError: true,
  );

  void backHome() => state = state.copyWith(
    phase: EducationPhase.home,
    clearSelected: true,
    clearPayment: true,
    clearError: true,
  );

  void goCheckout() {
    if (state.selected == null) return;
    state = state.copyWith(phase: EducationPhase.checkout, clearError: true);
  }

  void setStudent(String n) => state = state.copyWith(studentName: n);

  Future<void> createInvoice() async {
    final s = state.selected;
    if (s == null) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final draft = EduPayment(
        id: 'draft',
        school: s,
        studentName: state.studentName.trim().isEmpty
            ? 'Neema Juma'
            : state.studentName.trim(),
        amount: s.termFee,
        status: EduPaymentStatus.drafting,
        createdAt: DateTime.now(),
      );
      final inv = await _payments.invoice(draft);
      state = state.copyWith(
        payment: inv,
        isBusy: false,
        phase: EducationPhase.invoiced,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> pay() async {
    final p = state.payment;
    if (p == null) return;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final paid = await _payments.pay(p.id);
      state = state.copyWith(
        payment: paid,
        history: await _payments.history(),
        isBusy: false,
        phase: EducationPhase.receipt,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  void openHistory() => state = state.copyWith(phase: EducationPhase.history);
}

final educationControllerProvider =
    NotifierProvider<EducationController, EducationUiState>(
      EducationController.new,
    );

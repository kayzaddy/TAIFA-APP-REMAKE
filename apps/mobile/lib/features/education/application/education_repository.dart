import '../data/education_catalog.dart';
import '../domain/education_models.dart';

abstract interface class SchoolRepository {
  Future<List<School>> list({String? query});
}

abstract interface class EduPaymentRepository {
  Future<EduPayment> invoice(EduPayment draft);
  Future<EduPayment> pay(String id);
  Future<List<EduPayment>> history();
}

class SeedSchoolRepository implements SchoolRepository {
  @override
  Future<List<School>> list({String? query}) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final all = EducationCatalog.all();
    final q = query?.trim().toLowerCase();
    if (q == null || q.isEmpty) return all;
    return all
        .where(
          (s) =>
              s.name.toLowerCase().contains(q) ||
              s.level.toLowerCase().contains(q) ||
              s.area.toLowerCase().contains(q),
        )
        .toList();
  }
}

class SeedEduPaymentRepository implements EduPaymentRepository {
  final Map<String, EduPayment> _byId = {};
  final List<String> _order = [];
  int _seq = 0;

  @override
  Future<EduPayment> invoice(EduPayment draft) async {
    await Future<void>.delayed(const Duration(milliseconds: 360));
    final id = 'edu-${DateTime.now().millisecondsSinceEpoch}-${_seq++}';
    final inv = EduPayment(
      id: id,
      school: draft.school,
      studentName: draft.studentName,
      amount: draft.amount,
      status: EduPaymentStatus.invoiced,
      createdAt: DateTime.now(),
      invoiceNo: 'INV-EDU-${3000 + _seq}',
    );
    _byId[id] = inv;
    _order.insert(0, id);
    return inv;
  }

  @override
  Future<EduPayment> pay(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final cur = _byId[id]!;
    final paid = cur.copyWith(
      status: EduPaymentStatus.paid,
      paymentRef: 'EDU-${id.hashCode.abs().toRadixString(36).toUpperCase()}',
    );
    _byId[id] = paid;
    return paid;
  }

  @override
  Future<List<EduPayment>> history() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _order.map((id) => _byId[id]!).toList();
  }
}

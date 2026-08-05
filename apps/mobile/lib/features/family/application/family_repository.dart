import '../data/family_catalog.dart';
import '../domain/family_models.dart';

abstract interface class FamilyRepository {
  Future<List<FamilyMember>> members();
  Future<FamilyTransfer> send(FamilyTransfer draft);
  Future<List<FamilyTransfer>> history();
}

class SeedFamilyRepository implements FamilyRepository {
  final Map<String, FamilyTransfer> _byId = {};
  final List<String> _order = [];
  int _seq = 0;

  @override
  Future<List<FamilyMember>> members() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return FamilyCatalog.members();
  }

  @override
  Future<FamilyTransfer> send(FamilyTransfer draft) async {
    await Future<void>.delayed(const Duration(milliseconds: 420));
    final id = 'fam-${DateTime.now().millisecondsSinceEpoch}-${_seq++}';
    final paid = FamilyTransfer(
      id: id,
      member: draft.member,
      amount: draft.amount,
      kind: draft.kind,
      status: FamilyTxStatus.paid,
      createdAt: DateTime.now(),
      note: draft.note,
      paymentRef: 'FAM-${id.hashCode.abs().toRadixString(36).toUpperCase()}',
    );
    _byId[id] = paid;
    _order.insert(0, id);
    return paid;
  }

  @override
  Future<List<FamilyTransfer>> history() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _order.map((id) => _byId[id]!).toList();
  }
}

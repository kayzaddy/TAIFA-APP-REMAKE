import '../data/insurance_catalog.dart';
import '../domain/insurance_models.dart';

abstract interface class InsuranceRepository {
  Future<List<InsurancePlan>> listPlans();
  Future<InsurancePolicy> buy(InsurancePolicy draft);
  Future<List<InsurancePolicy>> history();
}

class SeedInsuranceRepository implements InsuranceRepository {
  final Map<String, InsurancePolicy> _byId = {};
  final List<String> _order = [];
  int _seq = 0;

  @override
  Future<List<InsurancePlan>> listPlans() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return InsuranceCatalog.plans();
  }

  @override
  Future<InsurancePolicy> buy(InsurancePolicy draft) async {
    await Future<void>.delayed(const Duration(milliseconds: 420));
    final id = 'pol-${DateTime.now().millisecondsSinceEpoch}-${_seq++}';
    final active = InsurancePolicy(
      id: id,
      plan: draft.plan,
      status: PolicyStatus.active,
      createdAt: DateTime.now(),
      policyRef: 'POL-${id.hashCode.abs().toRadixString(36).toUpperCase()}',
    );
    _byId[id] = active;
    _order.insert(0, id);
    return active;
  }

  @override
  Future<List<InsurancePolicy>> history() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _order.map((id) => _byId[id]!).toList();
  }
}

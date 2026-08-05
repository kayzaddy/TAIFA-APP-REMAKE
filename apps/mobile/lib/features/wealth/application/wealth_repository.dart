import '../../wallet/domain/currency.dart';
import '../../wallet/domain/money.dart';
import '../data/wealth_catalog.dart';
import '../domain/wealth_models.dart';

abstract interface class WealthRepository {
  Future<List<HarambeeCircle>> list();
  Future<WealthContribution> contribute(WealthContribution draft);
  Future<List<WealthContribution>> history();
}

class SeedWealthRepository implements WealthRepository {
  final Map<String, HarambeeCircle> _circles = {
    for (final c in WealthCatalog.circles()) c.id: c,
  };
  final Map<String, WealthContribution> _byId = {};
  final List<String> _order = [];
  int _seq = 0;

  @override
  Future<List<HarambeeCircle>> list() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _circles.values.toList();
  }

  @override
  Future<WealthContribution> contribute(WealthContribution draft) async {
    await Future<void>.delayed(const Duration(milliseconds: 420));
    final id = 'wth-${DateTime.now().millisecondsSinceEpoch}-${_seq++}';
    final paid = WealthContribution(
      id: id,
      circle: draft.circle,
      amount: draft.amount,
      status: ContributionStatus.paid,
      createdAt: DateTime.now(),
      paymentRef: 'HRB-${id.hashCode.abs().toRadixString(36).toUpperCase()}',
    );
    final c = draft.circle;
    _circles[c.id] = HarambeeCircle(
      id: c.id,
      name: c.name,
      purpose: c.purpose,
      target: c.target,
      raised: Money(
        c.raised.minorUnits + draft.amount.minorUnits,
        Currency.tzs,
      ),
      members: c.members,
    );
    _byId[id] = paid;
    _order.insert(0, id);
    return paid;
  }

  @override
  Future<List<WealthContribution>> history() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _order.map((id) => _byId[id]!).toList();
  }
}

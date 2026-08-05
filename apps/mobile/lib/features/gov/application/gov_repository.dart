import '../data/gov_catalog.dart';
import '../domain/gov_models.dart';

abstract interface class GovServiceRepository {
  Future<List<GovService>> list({String? query});
}

abstract interface class GovRequestRepository {
  Future<GovRequest> submit(GovRequest draft);
  Future<GovRequest> pay(String id);
  Future<List<GovRequest>> history();
}

class SeedGovServiceRepository implements GovServiceRepository {
  @override
  Future<List<GovService>> list({String? query}) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final all = GovCatalog.all();
    final q = query?.trim().toLowerCase();
    if (q == null || q.isEmpty) return all;
    return all
        .where(
          (s) =>
              s.title.toLowerCase().contains(q) ||
              s.agency.toLowerCase().contains(q) ||
              s.category.toLowerCase().contains(q),
        )
        .toList();
  }
}

class SeedGovRequestRepository implements GovRequestRepository {
  final Map<String, GovRequest> _byId = {};
  final List<String> _order = [];
  int _seq = 0;

  @override
  Future<GovRequest> submit(GovRequest draft) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final id = 'gov-${DateTime.now().millisecondsSinceEpoch}-${_seq++}';
    final req = GovRequest(
      id: id,
      service: draft.service,
      status: GovRequestStatus.inReview,
      createdAt: DateTime.now(),
      applicantName: draft.applicantName,
      reference: 'GVR-${200000 + _seq * 17}',
    );
    _byId[id] = req;
    _order.insert(0, id);
    return req;
  }

  @override
  Future<GovRequest> pay(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 420));
    final cur = _byId[id]!;
    final paid = cur.copyWith(
      status: GovRequestStatus.paid,
      paymentRef: 'GOV-${id.hashCode.abs().toRadixString(36).toUpperCase()}',
    );
    _byId[id] = paid;
    return paid;
  }

  @override
  Future<List<GovRequest>> history() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return _order.map((id) => _byId[id]!).toList();
  }
}

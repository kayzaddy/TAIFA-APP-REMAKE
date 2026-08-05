import '../data/housing_catalog.dart';
import '../domain/housing_models.dart';

abstract interface class HousingRepository {
  Future<List<HousingListing>> list({String? query});
  Future<HousingInquiry> inquire(HousingInquiry draft);
  Future<HousingInquiry> payDeposit(String id);
  Future<List<HousingInquiry>> history();
}

class SeedHousingRepository implements HousingRepository {
  final Map<String, HousingInquiry> _byId = {};
  final List<String> _order = [];
  int _seq = 0;

  @override
  Future<List<HousingListing>> list({String? query}) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final all = HousingCatalog.all();
    final q = query?.trim().toLowerCase();
    if (q == null || q.isEmpty) return all;
    return all
        .where(
          (l) =>
              l.title.toLowerCase().contains(q) ||
              l.area.toLowerCase().contains(q) ||
              l.tagline.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Future<HousingInquiry> inquire(HousingInquiry draft) async {
    await Future<void>.delayed(const Duration(milliseconds: 360));
    final id = 'hsq-${DateTime.now().millisecondsSinceEpoch}-${_seq++}';
    final now = DateTime.now();
    final viewing = DateTime(now.year, now.month, now.day + 2, 15, 0);
    final created = HousingInquiry(
      id: id,
      listing: draft.listing,
      status: HousingInquiryStatus.scheduled,
      createdAt: now,
      viewingAt: viewing,
    );
    _byId[id] = created;
    _order.insert(0, id);
    return created;
  }

  @override
  Future<HousingInquiry> payDeposit(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final cur = _byId[id]!;
    final paid = cur.copyWith(
      status: HousingInquiryStatus.depositPaid,
      paymentRef: 'HSG-${id.hashCode.abs().toRadixString(36).toUpperCase()}',
    );
    _byId[id] = paid;
    return paid;
  }

  @override
  Future<List<HousingInquiry>> history() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _order.map((id) => _byId[id]!).toList();
  }
}

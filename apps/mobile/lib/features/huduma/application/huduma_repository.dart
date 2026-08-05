import '../data/huduma_catalog.dart';
import '../domain/huduma_models.dart';

abstract interface class HudumaRepository {
  Future<List<HudumaService>> list();
  Future<HudumaBooking> book(HudumaBooking draft);
  Future<List<HudumaBooking>> history();
}

class SeedHudumaRepository implements HudumaRepository {
  final Map<String, HudumaBooking> _byId = {};
  final List<String> _order = [];
  int _seq = 0;

  @override
  Future<List<HudumaService>> list() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return HudumaCatalog.services();
  }

  @override
  Future<HudumaBooking> book(HudumaBooking draft) async {
    await Future<void>.delayed(const Duration(milliseconds: 420));
    final id = 'hdm-${DateTime.now().millisecondsSinceEpoch}-${_seq++}';
    final paid = HudumaBooking(
      id: id,
      service: draft.service,
      status: HudumaBookingStatus.paid,
      slotLabel: draft.slotLabel,
      createdAt: DateTime.now(),
      paymentRef: 'HDM-${id.hashCode.abs().toRadixString(36).toUpperCase()}',
    );
    _byId[id] = paid;
    _order.insert(0, id);
    return paid;
  }

  @override
  Future<List<HudumaBooking>> history() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _order.map((id) => _byId[id]!).toList();
  }
}

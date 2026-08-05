import '../data/tourism_catalog.dart';
import '../domain/tourism_models.dart';
import 'tourism_repository.dart';

class SeedTourismRepository implements TourismRepository {
  @override
  Future<List<TourExperience>> list({String? query}) async {
    await Future<void>.delayed(const Duration(milliseconds: 240));
    final all = TourismCatalog.all();
    final q = query?.trim().toLowerCase();
    if (q == null || q.isEmpty) return all;
    return all
        .where(
          (t) =>
              t.title.toLowerCase().contains(q) ||
              t.region.toLowerCase().contains(q) ||
              t.tagline.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Future<TourExperience> getById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return TourismCatalog.all().firstWhere((t) => t.id == id);
  }
}

class SeedTourBookingRepository implements TourBookingRepository {
  final Map<String, TourBooking> _byId = {};
  final List<String> _order = [];
  int _seq = 0;

  @override
  Future<TourBooking> book(TourBooking draft) async {
    await Future<void>.delayed(const Duration(milliseconds: 360));
    final id = 'tour-${DateTime.now().millisecondsSinceEpoch}-${_seq++}';
    final code = 'EXP-${(200000 + _seq * 173) % 900000}';
    final booked = TourBooking(
      id: id,
      tour: draft.tour,
      guests: draft.guests,
      date: draft.date,
      total: draft.total,
      status: TourBookingStatus.confirmed,
      createdAt: DateTime.now(),
      confirmationCode: code,
    );
    _byId[id] = booked;
    _order.insert(0, id);
    return booked;
  }

  @override
  Future<TourBooking> pay(String bookingId) async {
    await Future<void>.delayed(const Duration(milliseconds: 420));
    final booking = await getById(bookingId);
    final paid = booking.copyWith(
      status: TourBookingStatus.paid,
      paymentRef:
          'TOUR-${bookingId.hashCode.abs().toRadixString(36).toUpperCase()}',
    );
    _byId[bookingId] = paid;
    return paid;
  }

  @override
  Future<List<TourBooking>> history({int limit = 20}) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return _order.take(limit).map((id) => _byId[id]!).toList();
  }

  @override
  Future<TourBooking> getById(String id) async {
    final b = _byId[id];
    if (b == null) throw StateError('Tour booking not found: $id');
    return b;
  }
}

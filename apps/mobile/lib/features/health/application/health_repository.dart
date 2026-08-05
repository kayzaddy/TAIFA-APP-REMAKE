import '../data/health_catalog.dart';
import '../domain/health_models.dart';

abstract interface class HealthFacilityRepository {
  Future<List<HealthFacility>> list({String? query});
}

abstract interface class AppointmentRepository {
  Future<HealthAppointment> book(HealthAppointment draft);
  Future<HealthAppointment> pay(String id);
  Future<List<HealthAppointment>> history();
}

class SeedHealthFacilityRepository implements HealthFacilityRepository {
  @override
  Future<List<HealthFacility>> list({String? query}) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final all = HealthCatalog.all();
    final q = query?.trim().toLowerCase();
    if (q == null || q.isEmpty) return all;
    return all
        .where(
          (f) =>
              f.name.toLowerCase().contains(q) ||
              f.specialty.toLowerCase().contains(q) ||
              f.area.toLowerCase().contains(q),
        )
        .toList();
  }
}

class SeedAppointmentRepository implements AppointmentRepository {
  final Map<String, HealthAppointment> _byId = {};
  final List<String> _order = [];
  int _seq = 0;

  @override
  Future<HealthAppointment> book(HealthAppointment draft) async {
    await Future<void>.delayed(const Duration(milliseconds: 380));
    final id = 'apt-${DateTime.now().millisecondsSinceEpoch}-${_seq++}';
    final booked = HealthAppointment(
      id: id,
      facility: draft.facility,
      slot: draft.slot,
      patientName: draft.patientName,
      fee: draft.fee,
      status: AppointmentStatus.confirmed,
      createdAt: DateTime.now(),
      confirmationCode: 'HL-${1000 + _seq * 13}',
    );
    _byId[id] = booked;
    _order.insert(0, id);
    return booked;
  }

  @override
  Future<HealthAppointment> pay(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final cur = _byId[id]!;
    final paid = cur.copyWith(
      status: AppointmentStatus.paid,
      paymentRef: 'HLT-${id.hashCode.abs().toRadixString(36).toUpperCase()}',
    );
    _byId[id] = paid;
    return paid;
  }

  @override
  Future<List<HealthAppointment>> history() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _order.map((id) => _byId[id]!).toList();
  }
}

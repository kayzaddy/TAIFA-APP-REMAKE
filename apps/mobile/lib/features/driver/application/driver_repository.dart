import '../../wallet/domain/currency.dart';
import '../../wallet/domain/money.dart';
import '../data/driver_seed.dart';
import '../domain/driver_models.dart';

abstract interface class DriverRepository {
  Future<List<DriverJob>> offers();
  Future<DriverJob> update(DriverJob job);
  Future<Money> todayEarnings();
}

class SeedDriverRepository implements DriverRepository {
  final Map<String, DriverJob> _byId = {
    for (final j in DriverSeed.jobs()) j.id: j,
  };
  Money _earned = Money.zero(Currency.tzs);

  @override
  Future<List<DriverJob>> offers() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return _byId.values
        .where(
          (j) =>
              j.status != DriverJobStatus.declined &&
              j.status != DriverJobStatus.completed,
        )
        .toList();
  }

  @override
  Future<DriverJob> update(DriverJob job) async {
    await Future<void>.delayed(const Duration(milliseconds: 260));
    _byId[job.id] = job;
    if (job.status == DriverJobStatus.completed) {
      _earned = _earned + job.fare;
    }
    return job;
  }

  @override
  Future<Money> todayEarnings() async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    return _earned;
  }
}

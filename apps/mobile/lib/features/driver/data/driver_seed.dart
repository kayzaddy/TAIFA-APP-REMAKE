import '../../wallet/domain/currency.dart';
import '../../wallet/domain/money.dart';
import '../domain/driver_models.dart';

class DriverSeed {
  const DriverSeed._();

  static List<DriverJob> jobs() {
    Money m(int major) => Money.major(major, Currency.tzs);
    return [
      DriverJob(
        id: 'dj-1',
        riderName: 'Amani J.',
        pickup: 'Mikocheni B',
        dropoff: 'Masaki',
        fare: m(8500),
        etaMinutes: 6,
        status: DriverJobStatus.offered,
      ),
      DriverJob(
        id: 'dj-2',
        riderName: 'Fatma S.',
        pickup: 'Sinza',
        dropoff: 'Ubungo',
        fare: m(6200),
        etaMinutes: 4,
        status: DriverJobStatus.offered,
      ),
    ];
  }
}

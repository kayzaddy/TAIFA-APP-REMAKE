import '../../wallet/domain/currency.dart';
import '../../wallet/domain/money.dart';
import '../domain/flight_models.dart';

/// Domestic + regional East Africa flight offers for the Foundation Sprint.
class FlightCatalog {
  const FlightCatalog._();

  static const dar = Airport(
    code: 'DAR',
    city: 'Dar es Salaam',
    name: 'Julius Nyerere Intl',
  );
  static const jro = Airport(
    code: 'JRO',
    city: 'Kilimanjaro',
    name: 'Kilimanjaro Intl',
  );
  static const znz = Airport(
    code: 'ZNZ',
    city: 'Zanzibar',
    name: 'Abeid Amani Karume',
  );
  static const nbo = Airport(
    code: 'NBO',
    city: 'Nairobi',
    name: 'Jomo Kenyatta',
  );
  static const ebb = Airport(
    code: 'EBB',
    city: 'Entebbe',
    name: 'Entebbe Intl',
  );

  static List<Airport> airports() => const [dar, jro, znz, nbo, ebb];

  static List<FlightOffer> search({
    required String originCode,
    required String destinationCode,
    required DateTime date,
  }) {
    Money m(int major) => Money.major(major, Currency.tzs);
    final day = DateTime(date.year, date.month, date.day);
    final all = <FlightOffer>[
      FlightOffer(
        id: 'flt-pw-401',
        airline: 'Precision Air',
        flightNumber: 'PW 401',
        origin: dar,
        destination: znz,
        departAt: day.add(const Duration(hours: 7, minutes: 30)),
        arriveAt: day.add(const Duration(hours: 8, minutes: 15)),
        durationMinutes: 45,
        price: m(145000),
        popular: true,
      ),
      FlightOffer(
        id: 'flt-tc-210',
        airline: 'Air Tanzania',
        flightNumber: 'TC 210',
        origin: dar,
        destination: znz,
        departAt: day.add(const Duration(hours: 11, minutes: 10)),
        arriveAt: day.add(const Duration(hours: 11, minutes: 55)),
        durationMinutes: 45,
        price: m(132000),
      ),
      FlightOffer(
        id: 'flt-pw-512',
        airline: 'Precision Air',
        flightNumber: 'PW 512',
        origin: dar,
        destination: jro,
        departAt: day.add(const Duration(hours: 9, minutes: 0)),
        arriveAt: day.add(const Duration(hours: 10, minutes: 20)),
        durationMinutes: 80,
        price: m(218000),
        popular: true,
      ),
      FlightOffer(
        id: 'flt-kq-862',
        airline: 'Kenya Airways',
        flightNumber: 'KQ 862',
        origin: dar,
        destination: nbo,
        departAt: day.add(const Duration(hours: 14, minutes: 40)),
        arriveAt: day.add(const Duration(hours: 16, minutes: 5)),
        durationMinutes: 85,
        price: m(385000),
        cabin: 'Economy+',
      ),
      FlightOffer(
        id: 'flt-tc-880',
        airline: 'Air Tanzania',
        flightNumber: 'TC 880',
        origin: dar,
        destination: ebb,
        departAt: day.add(const Duration(hours: 16, minutes: 20)),
        arriveAt: day.add(const Duration(hours: 18, minutes: 10)),
        durationMinutes: 110,
        price: m(420000),
      ),
      FlightOffer(
        id: 'flt-pw-305',
        airline: 'Precision Air',
        flightNumber: 'PW 305',
        origin: znz,
        destination: dar,
        departAt: day.add(const Duration(hours: 18, minutes: 0)),
        arriveAt: day.add(const Duration(hours: 18, minutes: 45)),
        durationMinutes: 45,
        price: m(145000),
      ),
      FlightOffer(
        id: 'flt-tc-211',
        airline: 'Air Tanzania',
        flightNumber: 'TC 211',
        origin: jro,
        destination: dar,
        departAt: day.add(const Duration(hours: 13, minutes: 30)),
        arriveAt: day.add(const Duration(hours: 14, minutes: 50)),
        durationMinutes: 80,
        price: m(205000),
      ),
    ];

    return all
        .where(
          (f) =>
              f.origin.code == originCode &&
              f.destination.code == destinationCode,
        )
        .toList();
  }
}

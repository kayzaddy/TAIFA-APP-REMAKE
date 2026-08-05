import '../../wallet/domain/currency.dart';
import '../../wallet/domain/money.dart';
import '../domain/health_models.dart';

class HealthCatalog {
  const HealthCatalog._();

  static List<HealthFacility> all() {
    Money m(int major) => Money.major(major, Currency.tzs);
    return [
      HealthFacility(
        id: 'hlt-amana',
        name: 'Amana Regional Hospital',
        area: 'Ilala · Dar es Salaam',
        specialty: 'General · OPD',
        rating: 4.5,
        consultFee: m(15000),
      ),
      HealthFacility(
        id: 'hlt-muhimbili',
        name: 'Muhimbili Special Clinics',
        area: 'Upanga · Dar es Salaam',
        specialty: 'Cardiology · Referral',
        rating: 4.8,
        consultFee: m(45000),
      ),
      HealthFacility(
        id: 'hlt-aga',
        name: 'Aga Khan Hospital',
        area: 'Sea View · Dar es Salaam',
        specialty: 'Family medicine',
        rating: 4.7,
        consultFee: m(60000),
      ),
      HealthFacility(
        id: 'hlt-kairuki',
        name: 'Kairuki Hospital',
        area: 'Mikocheni · Dar es Salaam',
        specialty: 'Paediatrics',
        rating: 4.6,
        consultFee: m(35000),
      ),
    ];
  }
}

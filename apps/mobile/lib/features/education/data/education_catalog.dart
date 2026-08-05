import '../../wallet/domain/currency.dart';
import '../../wallet/domain/money.dart';
import '../domain/education_models.dart';

class EducationCatalog {
  const EducationCatalog._();

  static List<School> all() {
    Money m(int major) => Money.major(major, Currency.tzs);
    return [
      School(
        id: 'edu-azan',
        name: 'Azania Secondary',
        level: 'O-Level · Secondary',
        area: 'Upanga · Dar es Salaam',
        termFee: m(450000),
      ),
      School(
        id: 'edu-feza',
        name: 'Feza Boys Secondary',
        level: 'A-Level · Secondary',
        area: 'Mbezi · Dar es Salaam',
        termFee: m(890000),
      ),
      School(
        id: 'edu-ismo',
        name: 'Isamilo Primary',
        level: 'Primary',
        area: 'Mwanza City',
        termFee: m(180000),
      ),
      School(
        id: 'edu-udsm',
        name: 'UDSM Continuing Education',
        level: 'Short courses',
        area: 'Ubungo · Dar es Salaam',
        termFee: m(320000),
      ),
    ];
  }
}

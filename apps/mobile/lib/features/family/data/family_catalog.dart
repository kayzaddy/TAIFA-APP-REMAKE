import '../../wallet/domain/currency.dart';
import '../../wallet/domain/money.dart';
import '../domain/family_models.dart';

class FamilyCatalog {
  const FamilyCatalog._();

  static List<FamilyMember> members() {
    Money m(int major) => Money.major(major, Currency.tzs);
    return [
      FamilyMember(
        id: 'fm-neema',
        name: 'Neema Juma',
        role: 'Daughter · Student',
        phone: '+255 754 110 221',
        allowance: m(80000),
      ),
      FamilyMember(
        id: 'fm-asha',
        name: 'Asha Kibaki',
        role: 'Spouse · Co-owner',
        phone: '+255 713 882 441',
        allowance: m(0),
      ),
      FamilyMember(
        id: 'fm-baba',
        name: 'Juma Kibaki',
        role: 'Father · View only',
        phone: '+255 765 330 119',
        allowance: m(50000),
      ),
      FamilyMember(
        id: 'fm-kassim',
        name: 'Kassim Ally',
        role: 'Brother · Shared bills',
        phone: '+255 678 204 551',
        allowance: m(120000),
      ),
    ];
  }
}

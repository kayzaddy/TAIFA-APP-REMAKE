/// Path fragments for `/api/v1/commerce/family-transfers*` (relative to API base).
abstract final class FamilyApiPaths {
  static const familyTransfers = 'commerce/family-transfers';

  static String familyTransfer(String id) => 'commerce/family-transfers/$id';
}

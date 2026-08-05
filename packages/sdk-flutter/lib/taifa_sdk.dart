/// Taifa Flutter SDK — re-exports the mobile API client patterns.
///
/// Prefer using the in-app `TaifaApiClient` + `EcosystemClient` from the Super App.
/// This package documents the public contract for external Flutter modules.

library taifa_sdk;

/// Ecosystem REST prefixes (relative to `/api/v1/`).
class TaifaPaths {
  static const ecosystemBlueprint = 'ecosystem/blueprint';
  static const ecosystemModules = 'ecosystem/modules';
  static const ecosystemOpenCatalog = 'ecosystem/open/catalog';
  static const paymentsWallet = 'payments/wallet';
  static String ecosystemAiInvoke(String capability) =>
      'ecosystem/ai/$capability/invoke';
  static String ecosystemModuleEnable(String code) =>
      'ecosystem/modules/$code/enable';
}

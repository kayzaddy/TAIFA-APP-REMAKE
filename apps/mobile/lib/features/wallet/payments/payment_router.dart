import '../domain/payment_method.dart';
import 'payment_gateway.dart';
import 'payment_provider.dart';

/// Chooses which [PaymentGateway] services a request. This is the seam that
/// keeps providers swappable: callers express *intent* (pay this method, this
/// amount, this operation) and the router resolves the concrete rail, honouring
/// a preference order with graceful fallback to an aggregator.
class PaymentRouter {
  PaymentRouter(List<PaymentGateway> gateways)
    : _gateways = List.unmodifiable(gateways);

  final List<PaymentGateway> _gateways;

  /// Preferred provider order for a given method. Direct operator rails first,
  /// then the Selcom aggregator as a catch-all fallback.
  List<PaymentProvider> _preferenceFor(PaymentMethod method) {
    switch (method) {
      case MobileMoneyMethod(:final operator):
        final direct = switch (operator) {
          MobileMoneyOperator.mpesa => PaymentProvider.mpesa,
          MobileMoneyOperator.airtelMoney => PaymentProvider.airtelMoney,
          MobileMoneyOperator.mixxByYas => PaymentProvider.selcom,
          MobileMoneyOperator.halopesa => PaymentProvider.selcom,
        };
        return [direct, PaymentProvider.selcom];
      case CardMethod():
        return [PaymentProvider.cardScheme, PaymentProvider.selcom];
      case BankMethod():
        return [PaymentProvider.bankRail, PaymentProvider.selcom];
      case TaifaWalletMethod():
        // Internal balance movements never leave the platform — no external
        // rail should be resolved for them.
        return const [];
    }
  }

  /// Resolves the best capable gateway for [request], or throws if none can
  /// service it (a routing/contract error, not a decline).
  PaymentGateway resolve(PaymentRequest request) {
    final preference = _preferenceFor(request.method);

    for (final provider in preference) {
      for (final g in _gateways) {
        if (g.provider == provider && g.canHandle(request)) return g;
      }
    }

    // Fallback: any registered gateway that can handle it.
    for (final g in _gateways) {
      if (g.canHandle(request)) return g;
    }

    throw PaymentContractException(
      'No payment rail can handle ${request.operation.name} of '
      '${request.amount} via ${request.method.runtimeType}.',
    );
  }

  /// All gateways that could service [request] (for diagnostics / smart retry).
  List<PaymentGateway> candidates(PaymentRequest request) =>
      _gateways.where((g) => g.canHandle(request)).toList(growable: false);
}

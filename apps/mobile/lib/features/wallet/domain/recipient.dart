import 'payment_method.dart';

/// A saved payee. The [method] carries how they get paid (mobile money, wallet,
/// bank), which the router uses to pick a rail.
class Recipient {
  const Recipient({
    required this.id,
    required this.name,
    required this.handle,
    required this.method,
    this.verified = false,
  });

  final String id;
  final String name;
  final String handle; // masked phone / @tag
  final PaymentMethod method;
  final bool verified;

  String get initial => name.isNotEmpty ? name[0].toUpperCase() : '?';
}

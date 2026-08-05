import '../../features/wallet/domain/currency.dart';
import '../../features/wallet/domain/money.dart';
import '../../features/wealth/application/wealth_repository.dart';
import '../../features/wealth/data/wealth_catalog.dart';
import '../../features/wealth/domain/wealth_models.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import 'wealth_api_paths.dart';
import 'wealth_contribution_dto.dart';

/// Live [WealthRepository]: circles stay seed-local; contributions persist on
/// `/commerce/wealth-contributions`.
class RestWealthRepository implements WealthRepository {
  RestWealthRepository(this._client);

  final TaifaApiClient _client;
  final Map<String, HarambeeCircle> _circles = {
    for (final c in WealthCatalog.circles()) c.id: c,
  };
  final Map<String, HarambeeCircle> _byContribution = {};

  @override
  Future<List<HarambeeCircle>> list() async => _circles.values.toList();

  @override
  Future<WealthContribution> contribute(WealthContribution draft) async {
    try {
      final paymentRef =
          draft.paymentRef ??
          'HRB-${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}';
      final paidDraft = draft.copyWith(
        status: ContributionStatus.paid,
        paymentRef: paymentRef,
      );
      final json = await _client.postJson(
        WealthApiPaths.wealthContributions,
        body: WealthContributionDto.createBody(paidDraft),
      );
      final contrib = WealthContributionDto.toDomain(
        json,
        circle: draft.circle,
      ).copyWith(status: ContributionStatus.paid, paymentRef: paymentRef);
      _byContribution[contrib.id] = draft.circle;
      final c = draft.circle;
      _circles[c.id] = HarambeeCircle(
        id: c.id,
        name: c.name,
        purpose: c.purpose,
        target: c.target,
        raised: Money(
          c.raised.minorUnits + draft.amount.minorUnits,
          Currency.tzs,
        ),
        members: c.members,
      );
      return contrib;
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<List<WealthContribution>> history() async {
    try {
      final list = await _client.getJsonList(
        WealthApiPaths.wealthContributions,
      );
      return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).map(
        (json) {
          final id = json['id'].toString();
          final circleId = json['circle_id'] as String? ?? '';
          return WealthContributionDto.toDomain(
            json,
            circle: _byContribution[id] ?? _circles[circleId],
          );
        },
      ).toList();
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  String _message(ApiException e) => switch (e) {
    NetworkException() => e.message,
    ApiStatusException(:final message) => message,
    ApiDecodeException() => e.message,
  };
}

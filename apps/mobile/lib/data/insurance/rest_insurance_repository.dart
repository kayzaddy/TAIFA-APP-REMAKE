import '../../features/insurance/application/insurance_repository.dart';
import '../../features/insurance/data/insurance_catalog.dart';
import '../../features/insurance/domain/insurance_models.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import 'insurance_api_paths.dart';
import 'insurance_policy_dto.dart';

/// Live [InsuranceRepository]: plans stay seed-local; policies persist on
/// `/commerce/insurance-policies`.
class RestInsuranceRepository implements InsuranceRepository {
  RestInsuranceRepository(this._client);

  final TaifaApiClient _client;
  final Map<String, InsurancePlan> _plans = {};

  @override
  Future<List<InsurancePlan>> listPlans() async => InsuranceCatalog.plans();

  @override
  Future<InsurancePolicy> buy(InsurancePolicy draft) async {
    try {
      final policyRef =
          draft.policyRef ??
          'POL-${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}';
      final withRef = draft.copyWith(
        status: PolicyStatus.active,
        policyRef: policyRef,
      );
      final json = await _client.postJson(
        InsuranceApiPaths.insurancePolicies,
        body: InsurancePolicyDto.createBody(withRef),
      );
      final policy = InsurancePolicyDto.toDomain(
        json,
        plan: draft.plan,
      ).copyWith(status: PolicyStatus.active, policyRef: policyRef);
      _plans[policy.id] = draft.plan;
      return policy;
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<List<InsurancePolicy>> history() async {
    try {
      final list = await _client.getJsonList(
        InsuranceApiPaths.insurancePolicies,
      );
      return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).map(
        (json) {
          final id = json['id'].toString();
          return InsurancePolicyDto.toDomain(json, plan: _plans[id]);
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

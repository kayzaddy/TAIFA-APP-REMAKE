import '../../features/family/application/family_repository.dart';
import '../../features/family/data/family_catalog.dart';
import '../../features/family/domain/family_models.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import 'family_api_paths.dart';
import 'family_transfer_dto.dart';

/// Live [FamilyRepository]: members stay seed-local; transfers persist on
/// `/commerce/family-transfers`.
class RestFamilyRepository implements FamilyRepository {
  RestFamilyRepository(this._client);

  final TaifaApiClient _client;
  final Map<String, FamilyMember> _members = {};

  @override
  Future<List<FamilyMember>> members() async => FamilyCatalog.members();

  @override
  Future<FamilyTransfer> send(FamilyTransfer draft) async {
    try {
      final paymentRef =
          draft.paymentRef ??
          'FAM-${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}';
      final paid = draft.copyWith(
        status: FamilyTxStatus.paid,
        paymentRef: paymentRef,
      );
      final json = await _client.postJson(
        FamilyApiPaths.familyTransfers,
        body: FamilyTransferDto.createBody(paid),
      );
      final transfer = FamilyTransferDto.toDomain(
        json,
        member: draft.member,
      ).copyWith(status: FamilyTxStatus.paid, paymentRef: paymentRef);
      _members[transfer.id] = draft.member;
      return transfer;
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<List<FamilyTransfer>> history() async {
    try {
      final list = await _client.getJsonList(FamilyApiPaths.familyTransfers);
      return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).map(
        (json) {
          final id = json['id'].toString();
          return FamilyTransferDto.toDomain(json, member: _members[id]);
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

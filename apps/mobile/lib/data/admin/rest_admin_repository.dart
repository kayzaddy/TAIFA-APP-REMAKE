import '../../features/admin/application/admin_repository.dart';
import '../../features/admin/data/admin_seed.dart';
import '../../features/admin/domain/admin_models.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import 'admin_api_paths.dart';
import 'admin_case_dto.dart';

/// Live [AdminRepository]: hydrates demo cases once, then advances via API.
class RestAdminRepository implements AdminRepository {
  RestAdminRepository(this._client);

  final TaifaApiClient _client;
  bool _seeded = false;

  @override
  Future<List<AdminCase>> listCases() async {
    try {
      var list = await _fetch();
      if (list.isEmpty && !_seeded) {
        await _hydrateSeed();
        _seeded = true;
        list = await _fetch();
      }
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<AdminStats> stats() async {
    final cases = await listCases();
    final open = cases
        .where((c) => c.status != AdminCaseStatus.resolved)
        .length;
    return AdminStats(
      activeUsers: 12840,
      openCases: open,
      merchants: 642,
      flaggedWallets: cases
          .where(
            (c) =>
                c.kind == AdminCaseKind.freeze &&
                c.status != AdminCaseStatus.resolved,
          )
          .length,
    );
  }

  @override
  Future<AdminCase> advance(String id) async {
    try {
      final current = AdminCaseDto.toDomain(
        await _client.getJson(AdminApiPaths.adminCase(id)),
      );
      final next = switch (current.status) {
        AdminCaseStatus.open => AdminCaseStatus.reviewing,
        AdminCaseStatus.reviewing => AdminCaseStatus.resolved,
        AdminCaseStatus.resolved => AdminCaseStatus.resolved,
      };
      final json = await _client.patchJson(
        AdminApiPaths.adminCase(id),
        body: AdminCaseDto.patchBody(current.copyWith(status: next)),
      );
      return AdminCaseDto.toDomain(json);
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  Future<List<AdminCase>> _fetch() async {
    final list = await _client.getJsonList(AdminApiPaths.adminCases);
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .map(AdminCaseDto.toDomain)
        .toList();
  }

  Future<void> _hydrateSeed() async {
    for (final c in AdminSeed.cases()) {
      await _client.postJson(
        AdminApiPaths.adminCases,
        body: AdminCaseDto.createBody(c),
      );
    }
  }

  String _message(ApiException e) => switch (e) {
    NetworkException() => e.message,
    ApiStatusException(:final message) => message,
    ApiDecodeException() => e.message,
  };
}

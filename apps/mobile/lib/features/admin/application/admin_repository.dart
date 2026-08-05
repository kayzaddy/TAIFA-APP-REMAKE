import '../data/admin_seed.dart';
import '../domain/admin_models.dart';

abstract interface class AdminRepository {
  Future<List<AdminCase>> listCases();
  Future<AdminStats> stats();
  Future<AdminCase> advance(String id);
}

class SeedAdminRepository implements AdminRepository {
  final Map<String, AdminCase> _byId = {
    for (final c in AdminSeed.cases()) c.id: c,
  };

  @override
  Future<List<AdminCase>> listCases() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final list = _byId.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
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
    await Future<void>.delayed(const Duration(milliseconds: 280));
    final cur = _byId[id]!;
    final next = switch (cur.status) {
      AdminCaseStatus.open => AdminCaseStatus.reviewing,
      AdminCaseStatus.reviewing => AdminCaseStatus.resolved,
      AdminCaseStatus.resolved => AdminCaseStatus.resolved,
    };
    final updated = cur.copyWith(status: next);
    _byId[id] = updated;
    return updated;
  }
}

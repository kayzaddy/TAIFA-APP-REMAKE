import '../data/jobs_catalog.dart';
import '../domain/jobs_models.dart';

abstract interface class JobsRepository {
  Future<List<JobListing>> list({String? query});
  Future<JobAssignment> accept(JobListing job);
  Future<JobAssignment> advance(String id);
  Future<List<JobAssignment>> history();
}

class SeedJobsRepository implements JobsRepository {
  final Map<String, JobAssignment> _byId = {};
  final List<String> _order = [];
  int _seq = 0;

  @override
  Future<List<JobListing>> list({String? query}) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final all = JobsCatalog.all();
    final q = query?.trim().toLowerCase();
    if (q == null || q.isEmpty) return all;
    return all
        .where(
          (j) =>
              j.title.toLowerCase().contains(q) ||
              j.area.toLowerCase().contains(q) ||
              j.summary.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Future<JobAssignment> accept(JobListing job) async {
    await Future<void>.delayed(const Duration(milliseconds: 320));
    final id = 'joba-${DateTime.now().millisecondsSinceEpoch}-${_seq++}';
    final a = JobAssignment(
      id: id,
      job: job,
      status: JobAssignmentStatus.accepted,
      createdAt: DateTime.now(),
    );
    _byId[id] = a;
    _order.insert(0, id);
    return a;
  }

  @override
  Future<JobAssignment> advance(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 280));
    final cur = _byId[id]!;
    final next = switch (cur.status) {
      JobAssignmentStatus.accepted => JobAssignmentStatus.inProgress,
      JobAssignmentStatus.inProgress => JobAssignmentStatus.completed,
      JobAssignmentStatus.completed => JobAssignmentStatus.paid,
      _ => cur.status,
    };
    final updated = cur.copyWith(
      status: next,
      paymentRef: next == JobAssignmentStatus.paid
          ? 'JOB-${id.hashCode.abs().toRadixString(36).toUpperCase()}'
          : cur.paymentRef,
    );
    _byId[id] = updated;
    return updated;
  }

  @override
  Future<List<JobAssignment>> history() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _order.map((id) => _byId[id]!).toList();
  }
}

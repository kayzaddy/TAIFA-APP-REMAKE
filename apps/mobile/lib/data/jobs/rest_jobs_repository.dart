import '../../features/jobs/application/jobs_repository.dart';
import '../../features/jobs/data/jobs_catalog.dart';
import '../../features/jobs/domain/jobs_models.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import 'job_assignment_dto.dart';
import 'jobs_api_paths.dart';

/// Live [JobsRepository]: listings stay seed-local; assignments persist on
/// `/commerce/job-assignments`.
class RestJobsRepository implements JobsRepository {
  RestJobsRepository(this._client);

  final TaifaApiClient _client;
  final Map<String, JobListing> _jobs = {};

  @override
  Future<List<JobListing>> list({String? query}) async {
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
    try {
      final json = await _client.postJson(
        JobsApiPaths.jobAssignments,
        body: JobAssignmentDto.createBody(job),
      );
      final assignment = JobAssignmentDto.toDomain(
        json,
        job: job,
      ).copyWith(status: JobAssignmentStatus.accepted);
      _jobs[assignment.id] = job;
      return assignment;
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<JobAssignment> advance(String id) async {
    final current = await _getById(id);
    final next = switch (current.status) {
      JobAssignmentStatus.accepted => JobAssignmentStatus.inProgress,
      JobAssignmentStatus.inProgress => JobAssignmentStatus.completed,
      JobAssignmentStatus.completed => JobAssignmentStatus.paid,
      _ => current.status,
    };
    return _patch(
      current.copyWith(
        status: next,
        paymentRef: next == JobAssignmentStatus.paid
            ? 'JOB-${id.hashCode.abs().toRadixString(36).toUpperCase()}'
            : current.paymentRef,
      ),
    );
  }

  @override
  Future<List<JobAssignment>> history() async {
    try {
      final list = await _client.getJsonList(JobsApiPaths.jobAssignments);
      return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).map(
        (json) {
          final id = json['id'].toString();
          return JobAssignmentDto.toDomain(json, job: _jobs[id]);
        },
      ).toList();
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  Future<JobAssignment> _getById(String id) async {
    try {
      final json = await _client.getJson(JobsApiPaths.jobAssignment(id));
      return JobAssignmentDto.toDomain(json, job: _jobs[id]);
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  Future<JobAssignment> _patch(JobAssignment assignment) async {
    try {
      final json = await _client.patchJson(
        JobsApiPaths.jobAssignment(assignment.id),
        body: JobAssignmentDto.patchBody(assignment),
      );
      _jobs[assignment.id] = assignment.job;
      return JobAssignmentDto.toDomain(json, job: assignment.job);
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

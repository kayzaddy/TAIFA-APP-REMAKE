/// Path fragments for `/api/v1/commerce/job-assignments*` (relative to API base).
abstract final class JobsApiPaths {
  static const jobAssignments = 'commerce/job-assignments';

  static String jobAssignment(String id) => 'commerce/job-assignments/$id';
}

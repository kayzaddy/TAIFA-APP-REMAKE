/// Path fragments for `/api/v1/commerce/driver-jobs*` (relative to API base).
abstract final class DriverApiPaths {
  static const driverJobs = 'commerce/driver-jobs';

  static String driverJob(String id) => 'commerce/driver-jobs/$id';
}

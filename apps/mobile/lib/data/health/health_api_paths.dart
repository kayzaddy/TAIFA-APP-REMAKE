/// Path fragments for `/api/v1/commerce/health-appointments*` (relative to API base).
abstract final class HealthApiPaths {
  static const healthAppointments = 'commerce/health-appointments';

  static String healthAppointment(String id) =>
      'commerce/health-appointments/$id';
  static String appointmentPay(String id) =>
      'commerce/health-appointments/$id/pay';
}

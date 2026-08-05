import '../../features/jobs/data/jobs_catalog.dart';
import '../../features/jobs/domain/jobs_models.dart';
import '../../features/wallet/domain/currency.dart';
import '../../features/wallet/domain/money.dart';

/// Maps `/api/v1/commerce/job-assignments` JSON ↔ domain [JobAssignment].
class JobAssignmentDto {
  const JobAssignmentDto._();

  static JobAssignment toDomain(Map<String, dynamic> json, {JobListing? job}) {
    final currency = Currency.fromCode(json['currency'] as String? ?? 'TZS');
    final jobId = json['job_id'] as String? ?? '';
    final pay = Money((json['pay_minor'] as num?)?.toInt() ?? 0, currency);
    final payRef = (json['payment_ref'] as String?)?.trim();

    return JobAssignment(
      id: json['id'].toString(),
      job:
          job ??
          _resolveJob(
            jobId,
            json['job_title'] as String? ?? 'Job',
            json['area'] as String? ?? '',
            json['kind'] as String? ?? 'gig',
            json['summary'] as String? ?? '',
            pay,
          ),
      status: statusFromApi(json['status'] as String? ?? 'accepted'),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      paymentRef: (payRef == null || payRef.isEmpty) ? null : payRef,
    );
  }

  static Map<String, dynamic> createBody(JobListing job) => {
    'job_id': job.id,
    'job_title': job.title,
    'area': job.area,
    'kind': job.kind == JobKind.logistics ? 'logistics' : 'gig',
    'summary': job.summary,
    'pay_minor': job.pay.minorUnits,
    'currency': job.pay.currency.code,
  };

  static Map<String, dynamic> patchBody(JobAssignment assignment) {
    final body = <String, dynamic>{'status': statusToApi(assignment.status)};
    return body;
  }

  static String statusToApi(JobAssignmentStatus status) => switch (status) {
    JobAssignmentStatus.open || JobAssignmentStatus.accepted => 'accepted',
    JobAssignmentStatus.inProgress => 'in_progress',
    JobAssignmentStatus.completed => 'completed',
    JobAssignmentStatus.paid => 'paid',
  };

  static JobAssignmentStatus statusFromApi(String raw) => switch (raw) {
    'in_progress' => JobAssignmentStatus.inProgress,
    'completed' => JobAssignmentStatus.completed,
    'paid' => JobAssignmentStatus.paid,
    _ => JobAssignmentStatus.accepted,
  };

  static JobListing _resolveJob(
    String id,
    String title,
    String area,
    String kind,
    String summary,
    Money pay,
  ) {
    try {
      return JobsCatalog.all().firstWhere((j) => j.id == id);
    } catch (_) {
      return JobListing(
        id: id.isEmpty ? 'job-unknown' : id,
        title: title,
        area: area,
        pay: pay,
        kind: kind == 'logistics' ? JobKind.logistics : JobKind.gig,
        summary: summary,
      );
    }
  }
}

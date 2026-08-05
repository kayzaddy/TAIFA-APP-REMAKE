import '../../wallet/domain/money.dart';

enum JobKind { gig, logistics }

class JobListing {
  const JobListing({
    required this.id,
    required this.title,
    required this.area,
    required this.pay,
    required this.kind,
    required this.summary,
  });

  final String id;
  final String title;
  final String area;
  final Money pay;
  final JobKind kind;
  final String summary;
}

enum JobAssignmentStatus { open, accepted, inProgress, completed, paid }

extension JobAssignmentStatusX on JobAssignmentStatus {
  String get label => switch (this) {
    JobAssignmentStatus.open => 'Open',
    JobAssignmentStatus.accepted => 'Accepted',
    JobAssignmentStatus.inProgress => 'In progress',
    JobAssignmentStatus.completed => 'Completed',
    JobAssignmentStatus.paid => 'Paid',
  };
}

class JobAssignment {
  const JobAssignment({
    required this.id,
    required this.job,
    required this.status,
    required this.createdAt,
    this.paymentRef,
  });

  final String id;
  final JobListing job;
  final JobAssignmentStatus status;
  final DateTime createdAt;
  final String? paymentRef;

  JobAssignment copyWith({JobAssignmentStatus? status, String? paymentRef}) {
    return JobAssignment(
      id: id,
      job: job,
      status: status ?? this.status,
      createdAt: createdAt,
      paymentRef: paymentRef ?? this.paymentRef,
    );
  }
}

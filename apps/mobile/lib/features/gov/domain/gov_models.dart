import '../../wallet/domain/money.dart';

class GovService {
  const GovService({
    required this.id,
    required this.title,
    required this.agency,
    required this.description,
    required this.fee,
    required this.etaDays,
    required this.category,
  });

  final String id;
  final String title;
  final String agency;
  final String description;
  final Money fee;
  final int etaDays;
  final String category;
}

enum GovRequestStatus {
  drafting,
  submitted,
  inReview,
  approved,
  paid,
  rejected,
}

extension GovRequestStatusX on GovRequestStatus {
  String get label => switch (this) {
    GovRequestStatus.drafting => 'Draft',
    GovRequestStatus.submitted => 'Submitted',
    GovRequestStatus.inReview => 'In review',
    GovRequestStatus.approved => 'Approved',
    GovRequestStatus.paid => 'Fee paid',
    GovRequestStatus.rejected => 'Rejected',
  };
}

class GovRequest {
  const GovRequest({
    required this.id,
    required this.service,
    required this.status,
    required this.createdAt,
    required this.applicantName,
    this.reference,
    this.paymentRef,
  });

  final String id;
  final GovService service;
  final GovRequestStatus status;
  final DateTime createdAt;
  final String applicantName;
  final String? reference;
  final String? paymentRef;

  GovRequest copyWith({
    GovRequestStatus? status,
    String? reference,
    String? paymentRef,
  }) {
    return GovRequest(
      id: id,
      service: service,
      status: status ?? this.status,
      createdAt: createdAt,
      applicantName: applicantName,
      reference: reference ?? this.reference,
      paymentRef: paymentRef ?? this.paymentRef,
    );
  }
}

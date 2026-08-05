import '../../wallet/domain/currency.dart';
import '../../wallet/domain/money.dart';
import '../domain/jobs_models.dart';

class JobsCatalog {
  const JobsCatalog._();

  static List<JobListing> all() {
    Money m(int major) => Money.major(major, Currency.tzs);
    return [
      JobListing(
        id: 'job-parcel',
        title: 'Parcel run · Kariakoo → Mikocheni',
        area: 'Dar es Salaam',
        pay: m(12000),
        kind: JobKind.logistics,
        summary: 'Small package · cash on delivery optional',
      ),
      JobListing(
        id: 'job-move',
        title: 'Help move furniture',
        area: 'Sinza · Dar es Salaam',
        pay: m(45000),
        kind: JobKind.gig,
        summary: '2 hours · afternoon slot',
      ),
      JobListing(
        id: 'job-docs',
        title: 'Document drop · TRA',
        area: 'Ilala · Dar es Salaam',
        pay: m(8000),
        kind: JobKind.logistics,
        summary: 'Sealed envelope · same-day',
      ),
      JobListing(
        id: 'job-event',
        title: 'Event setup crew',
        area: 'Hyatt Regency · Kivukoni',
        pay: m(35000),
        kind: JobKind.gig,
        summary: 'Evening · 4 hours',
      ),
    ];
  }
}

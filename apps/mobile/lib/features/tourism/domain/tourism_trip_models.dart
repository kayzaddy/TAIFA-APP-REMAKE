/// Trip-centric DTOS models (orchestration layer above tour/stay bookings).
class TourismTrip {
  const TourismTrip({
    required this.id,
    required this.title,
    required this.status,
    required this.partySize,
    required this.budgetTier,
    required this.travelStyle,
    required this.interests,
    required this.tourBookingIds,
    required this.stayBookingIds,
    this.startDate,
    this.endDate,
    this.selectedItineraryId,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String status;
  final int partySize;
  final String budgetTier;
  final String travelStyle;
  final List<String> interests;
  final List<String> tourBookingIds;
  final List<String> stayBookingIds;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? selectedItineraryId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isPlanning => status == 'planning';
  bool get isReady => status == 'ready' || status == 'active';

  factory TourismTrip.fromJson(Map<String, dynamic> json) => TourismTrip(
        id: '${json['id']}',
        title: '${json['title'] ?? 'My Tanzania trip'}',
        status: '${json['status'] ?? 'planning'}',
        partySize: (json['party_size'] as num?)?.toInt() ?? 2,
        budgetTier: '${json['budget_tier'] ?? 'mid'}',
        travelStyle: '${json['travel_style'] ?? 'leisure'}',
        interests: (json['interests'] as List?)
                ?.map((e) => '$e')
                .toList() ??
            const [],
        tourBookingIds: (json['tour_booking_ids'] as List?)
                ?.map((e) => '$e')
                .toList() ??
            const [],
        stayBookingIds: (json['stay_booking_ids'] as List?)
                ?.map((e) => '$e')
                .toList() ??
            const [],
        startDate: _parseDate(json['start_date']),
        endDate: _parseDate(json['end_date']),
        selectedItineraryId: json['selected_itinerary_id']?.toString(),
        createdAt: _parseDateTime(json['created_at']),
        updatedAt: _parseDateTime(json['updated_at']),
      );
}

class TourismItineraryDay {
  const TourismItineraryDay({
    required this.day,
    required this.title,
    required this.items,
  });

  final int day;
  final String title;
  final List<TourismItineraryItem> items;

  factory TourismItineraryDay.fromJson(Map<String, dynamic> json) =>
      TourismItineraryDay(
        day: (json['day'] as num?)?.toInt() ?? 1,
        title: '${json['title'] ?? ''}',
        items: (json['items'] as List?)
                ?.whereType<Map>()
                .map((e) => TourismItineraryItem.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            const [],
      );
}

class TourismItineraryItem {
  const TourismItineraryItem({
    required this.time,
    required this.title,
    required this.kind,
    this.note = '',
  });

  final String time;
  final String title;
  final String kind;
  final String note;

  factory TourismItineraryItem.fromJson(Map<String, dynamic> json) =>
      TourismItineraryItem(
        time: '${json['time'] ?? ''}',
        title: '${json['title'] ?? ''}',
        kind: '${json['kind'] ?? 'activity'}',
        note: '${json['note'] ?? ''}',
      );
}

class TourismItinerary {
  const TourismItinerary({
    required this.id,
    required this.tripId,
    required this.version,
    required this.label,
    required this.summary,
    required this.days,
    required this.estimateMinor,
    required this.currency,
  });

  final String id;
  final String tripId;
  final int version;
  final String label;
  final String summary;
  final List<TourismItineraryDay> days;
  final int estimateMinor;
  final String currency;

  factory TourismItinerary.fromJson(Map<String, dynamic> json) =>
      TourismItinerary(
        id: '${json['id']}',
        tripId: '${json['trip_id'] ?? ''}',
        version: (json['version'] as num?)?.toInt() ?? 1,
        label: '${json['label'] ?? ''}',
        summary: '${json['summary'] ?? ''}',
        days: (json['days'] as List?)
                ?.whereType<Map>()
                .map((e) => TourismItineraryDay.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            const [],
        estimateMinor: (json['estimate_minor'] as num?)?.toInt() ?? 0,
        currency: '${json['currency'] ?? 'TZS'}',
      );
}

DateTime? _parseDate(dynamic value) {
  if (value == null || '$value'.isEmpty) return null;
  return DateTime.tryParse('$value');
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null || '$value'.isEmpty) return null;
  return DateTime.tryParse('$value');
}

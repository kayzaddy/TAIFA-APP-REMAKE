class TourismNearbyPlace {
  const TourismNearbyPlace({
    required this.id,
    required this.kind,
    required this.name,
    required this.phone,
    required this.distanceKm,
  });

  final String id;
  final String kind;
  final String name;
  final String phone;
  final double distanceKm;

  factory TourismNearbyPlace.fromJson(Map<String, dynamic> json) =>
      TourismNearbyPlace(
        id: '${json['id']}',
        kind: '${json['kind']}',
        name: '${json['name']}',
        phone: '${json['phone'] ?? ''}',
        distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
      );
}

class TourismAssistanceCase {
  const TourismAssistanceCase({
    required this.id,
    this.tripId,
    required this.kind,
    required this.status,
    this.safetyIncidentId,
    this.notes = '',
  });

  final String id;
  final String? tripId;
  final String kind;
  final String status;
  final String? safetyIncidentId;
  final String notes;

  factory TourismAssistanceCase.fromJson(Map<String, dynamic> json) =>
      TourismAssistanceCase(
        id: '${json['id']}',
        tripId: json['trip_id']?.toString(),
        kind: '${json['kind']}',
        status: '${json['status']}',
        safetyIncidentId: json['safety_incident_id']?.toString(),
        notes: '${json['notes'] ?? ''}',
      );
}

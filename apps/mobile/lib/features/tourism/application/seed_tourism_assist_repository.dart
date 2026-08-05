import 'package:uuid/uuid.dart';

import '../domain/tourism_assist_models.dart';
import '../domain/tourism_connectivity_models.dart';
import 'tourism_assist_repository.dart';

class SeedTourismAssistRepository implements TourismAssistRepository {
  @override
  Future<List<TourismNearbyPlace>> nearby({
    double? latitude,
    double? longitude,
  }) async {
    return const [
      TourismNearbyPlace(
        id: 'hosp-muhimbili',
        kind: 'hospital',
        name: 'Muhimbili National Hospital',
        phone: '+255 22 215 0000',
        distanceKm: 2.4,
      ),
      TourismNearbyPlace(
        id: 'police-central',
        kind: 'police',
        name: 'Central Police Station — Dar',
        phone: '112',
        distanceKm: 1.1,
      ),
    ];
  }

  @override
  Future<TourismAssistanceCase> sendSos({
    String? tripId,
    double? latitude,
    double? longitude,
    String notes = '',
  }) async {
    return TourismAssistanceCase(
      id: const Uuid().v4(),
      tripId: tripId,
      kind: 'sos',
      status: 'open',
      safetyIncidentId: const Uuid().v4(),
      notes: notes,
    );
  }

  @override
  Future<TourismEsimActivation> esimQr(String orderId) async {
    return TourismEsimActivation(
      orderId: orderId,
      qrPayload: 'LPA:1\$smdp.taifa-connect.example\$TAIFA-SEED',
      activationCode: 'TAIFA-SEED',
    );
  }
}

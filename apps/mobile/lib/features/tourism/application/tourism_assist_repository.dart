import '../domain/tourism_assist_models.dart';
import '../domain/tourism_connectivity_models.dart';

abstract class TourismAssistRepository {
  Future<List<TourismNearbyPlace>> nearby({double? latitude, double? longitude});

  Future<TourismAssistanceCase> sendSos({
    String? tripId,
    double? latitude,
    double? longitude,
    String notes = '',
  });

  Future<TourismEsimActivation> esimQr(String orderId);
}

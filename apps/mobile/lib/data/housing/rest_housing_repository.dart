import '../../features/housing/application/housing_repository.dart';
import '../../features/housing/data/housing_catalog.dart';
import '../../features/housing/domain/housing_models.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import 'housing_api_paths.dart';
import 'housing_inquiry_dto.dart';

/// Live [HousingRepository]: listings stay seed-local; inquiries persist on
/// `/commerce/housing-inquiries`.
class RestHousingRepository implements HousingRepository {
  RestHousingRepository(this._client);

  final TaifaApiClient _client;
  final Map<String, HousingListing> _listings = {};

  @override
  Future<List<HousingListing>> list({String? query}) async {
    final all = HousingCatalog.all();
    final q = query?.trim().toLowerCase();
    if (q == null || q.isEmpty) return all;
    return all
        .where(
          (l) =>
              l.title.toLowerCase().contains(q) ||
              l.area.toLowerCase().contains(q) ||
              l.tagline.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Future<HousingInquiry> inquire(HousingInquiry draft) async {
    try {
      final now = DateTime.now();
      final viewing =
          draft.viewingAt ?? DateTime(now.year, now.month, now.day + 2, 15, 0);
      final withViewing = draft.copyWith(
        status: HousingInquiryStatus.scheduled,
        viewingAt: viewing,
      );
      final json = await _client.postJson(
        HousingApiPaths.housingInquiries,
        body: HousingInquiryDto.createBody(withViewing),
      );
      final inquiry = HousingInquiryDto.toDomain(
        json,
        listing: draft.listing,
      ).copyWith(status: HousingInquiryStatus.scheduled, viewingAt: viewing);
      _listings[inquiry.id] = draft.listing;
      return inquiry;
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<HousingInquiry> payDeposit(String id) async {
    try {
      final json = await _client.postJson(
        HousingApiPaths.housingInquiryPay(id),
        body: const {},
        idempotencyKey: 'housing-pay-$id',
      );
      return HousingInquiryDto.toDomain(json, listing: _listings[id]);
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<List<HousingInquiry>> history() async {
    try {
      final list = await _client.getJsonList(HousingApiPaths.housingInquiries);
      return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).map(
        (json) {
          final id = json['id'].toString();
          return HousingInquiryDto.toDomain(json, listing: _listings[id]);
        },
      ).toList();
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  String _message(ApiException e) => switch (e) {
    NetworkException() => e.message,
    ApiStatusException(:final message) => message,
    ApiDecodeException() => e.message,
  };
}

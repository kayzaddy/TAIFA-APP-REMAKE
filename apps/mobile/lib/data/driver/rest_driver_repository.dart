import '../../features/driver/application/driver_repository.dart';
import '../../features/driver/data/driver_seed.dart';
import '../../features/driver/domain/driver_models.dart';
import '../../features/wallet/domain/currency.dart';
import '../../features/wallet/domain/money.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import 'driver_api_paths.dart';
import 'driver_job_dto.dart';

/// Live [DriverRepository]: hydrates demo offers once, then updates via API.
class RestDriverRepository implements DriverRepository {
  RestDriverRepository(this._client);

  final TaifaApiClient _client;
  bool _seeded = false;

  @override
  Future<List<DriverJob>> offers() async {
    try {
      var list = await _fetch();
      if (list.isEmpty && !_seeded) {
        await _hydrateSeed();
        _seeded = true;
        list = await _fetch();
      }
      return list
          .where(
            (j) =>
                j.status != DriverJobStatus.declined &&
                j.status != DriverJobStatus.completed,
          )
          .toList();
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<DriverJob> update(DriverJob job) async {
    try {
      final json = await _client.patchJson(
        DriverApiPaths.driverJob(job.id),
        body: DriverJobDto.patchBody(job),
      );
      return DriverJobDto.toDomain(json);
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  @override
  Future<Money> todayEarnings() async {
    try {
      final list = await _fetch();
      var earned = Money.zero(Currency.tzs);
      for (final j in list.where(
        (j) => j.status == DriverJobStatus.completed,
      )) {
        earned = earned + j.fare;
      }
      return earned;
    } on ApiException catch (e) {
      throw StateError(_message(e));
    }
  }

  Future<List<DriverJob>> _fetch() async {
    final list = await _client.getJsonList(DriverApiPaths.driverJobs);
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .map(DriverJobDto.toDomain)
        .toList();
  }

  Future<void> _hydrateSeed() async {
    for (final job in DriverSeed.jobs()) {
      await _client.postJson(
        DriverApiPaths.driverJobs,
        body: DriverJobDto.createBody(job),
      );
    }
  }

  String _message(ApiException e) => switch (e) {
    NetworkException() => e.message,
    ApiStatusException(:final message) => message,
    ApiDecodeException() => e.message,
  };
}

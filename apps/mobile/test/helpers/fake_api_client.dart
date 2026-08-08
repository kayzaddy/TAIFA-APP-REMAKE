import 'package:taifa/data/api/api_client.dart';
import 'package:taifa/data/api/api_exception.dart';

/// A programmable [TaifaApiClient] that records requests and returns canned
/// responses — no `http`, no network. Shared across the social-payments
/// repository tests (mirrors the private fake in
/// `test/wallet/rest_wallet_repository_test.dart`).
class FakeApiClient implements TaifaApiClient {
  FakeApiClient({
    this.getResponse,
    this.getListResponse,
    this.postResponse,
    this.patchResponse,
    this.throwOnGet,
    this.throwOnPost,
  });

  Map<String, dynamic>? getResponse;
  List<dynamic>? getListResponse;
  Map<String, dynamic>? postResponse;
  Map<String, dynamic>? patchResponse;
  ApiException? throwOnGet;
  ApiException? throwOnPost;

  String? lastGetPath;
  String? lastPostPath;
  String? lastPatchPath;
  String? lastDeletePath;
  Map<String, dynamic>? lastBody;
  String? lastIdempotencyKey;

  @override
  Future<Map<String, dynamic>> getJson(String path) async {
    lastGetPath = path;
    if (throwOnGet != null) throw throwOnGet!;
    return getResponse ?? (throw const ApiDecodeException());
  }

  @override
  Future<List<dynamic>> getJsonList(String path) async {
    lastGetPath = path;
    return getListResponse ?? (throw const ApiDecodeException());
  }

  @override
  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic> body = const {},
    String? idempotencyKey,
  }) async {
    lastPostPath = path;
    lastBody = body;
    lastIdempotencyKey = idempotencyKey;
    if (throwOnPost != null) throw throwOnPost!;
    return postResponse ?? (throw const ApiDecodeException());
  }

  @override
  Future<Map<String, dynamic>> patchJson(
    String path, {
    Map<String, dynamic> body = const {},
  }) async {
    lastPatchPath = path;
    lastBody = body;
    return patchResponse ?? postResponse ?? (throw const ApiDecodeException());
  }

  @override
  Future<void> deleteJson(String path) async {
    lastDeletePath = path;
  }
}

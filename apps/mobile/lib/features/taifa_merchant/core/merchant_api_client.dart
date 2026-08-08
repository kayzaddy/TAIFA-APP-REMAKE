import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'auth_token_storage.dart';
import 'merchant_app_config.dart';

final merchantDioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(merchantAuthStorageProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: MerchantAppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.readAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ),
  );
  return dio;
});

final merchantApiClientProvider = Provider<MerchantApiClient>((ref) {
  return MerchantApiClient(ref.watch(merchantDioProvider));
});

class MerchantApiClient {
  MerchantApiClient(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> signup(Map<String, dynamic> body) async {
    final res = await _dio.post<Map<String, dynamic>>('/auth/signup', data: body);
    return res.data!;
  }

  Future<Map<String, dynamic>> login(Map<String, dynamic> body) async {
    final res = await _dio.post<Map<String, dynamic>>('/auth/login', data: body);
    return res.data!;
  }

  Future<void> logout() async {
    await _dio.post('/auth/logout');
  }

  Future<Map<String, dynamic>> session() async {
    final res = await _dio.get<Map<String, dynamic>>('/auth/session');
    return res.data!;
  }

  Future<Map<String, dynamic>> registerMerchant(Map<String, dynamic> body) async {
    final res = await _dio.post<Map<String, dynamic>>('/merchants/register', data: body);
    return res.data!;
  }

  Future<Map<String, dynamic>> merchantMe() async {
    final res = await _dio.get<Map<String, dynamic>>('/merchants/me');
    return res.data!;
  }

  Future<Map<String, dynamic>> dashboard() async {
    final res = await _dio.get<Map<String, dynamic>>('/dashboard');
    return res.data!;
  }

  Future<List<dynamic>> listBranches() async {
    final res = await _dio.get<List<dynamic>>('/branches');
    return res.data ?? [];
  }

  Future<Map<String, dynamic>> createBranch(Map<String, dynamic> body) async {
    final res = await _dio.post<Map<String, dynamic>>('/branches', data: body);
    return res.data!;
  }

  Future<List<dynamic>> listEmployees() async {
    final res = await _dio.get<List<dynamic>>('/employees');
    return res.data ?? [];
  }

  Future<Map<String, dynamic>> inviteEmployee(Map<String, dynamic> body) async {
    final res = await _dio.post<Map<String, dynamic>>('/employees', data: body);
    return res.data!;
  }

  Future<List<dynamic>> listDevices() async {
    final res = await _dio.get<List<dynamic>>('/devices');
    return res.data ?? [];
  }

  Future<Map<String, dynamic>> registerDevice(Map<String, dynamic> body) async {
    final res = await _dio.post<Map<String, dynamic>>('/devices', data: body);
    return res.data!;
  }

  Future<Map<String, dynamic>> activateDevice(String id) async {
    final res = await _dio.post<Map<String, dynamic>>('/devices/$id/activate');
    return res.data!;
  }

  Future<Map<String, dynamic>> getBusinessProfile() async {
    final res = await _dio.get<Map<String, dynamic>>('/business-profile');
    return res.data!;
  }

  Future<Map<String, dynamic>> updateBusinessProfile(Map<String, dynamic> body) async {
    final res = await _dio.patch<Map<String, dynamic>>('/business-profile', data: body);
    return res.data!;
  }

  Future<Map<String, dynamic>> getSettings() async {
    final res = await _dio.get<Map<String, dynamic>>('/settings');
    return res.data!;
  }

  Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> body) async {
    final res = await _dio.patch<Map<String, dynamic>>('/settings', data: body);
    return res.data!;
  }

  Future<List<dynamic>> listNotifications({bool unreadOnly = false}) async {
    final res = await _dio.get<List<dynamic>>(
      '/notifications',
      queryParameters: {'unread_only': unreadOnly},
    );
    return res.data ?? [];
  }

  Future<Map<String, dynamic>> getNotificationPreferences() async {
    final res = await _dio.get<Map<String, dynamic>>('/notifications/preferences');
    return res.data!;
  }

  Future<Map<String, dynamic>> updateNotificationPreferences(Map<String, dynamic> body) async {
    final res = await _dio.patch<Map<String, dynamic>>('/notifications/preferences', data: body);
    return res.data!;
  }

  Future<void> markNotificationRead(String id) async {
    await _dio.post('/notifications/$id/read');
  }

  Future<Map<String, dynamic>> getBranchDashboard(String branchId) async {
    final res = await _dio.get<Map<String, dynamic>>('/branches/$branchId/dashboard');
    return res.data!;
  }

  Future<Map<String, dynamic>> suspendEmployee(String id) async {
    final res = await _dio.post<Map<String, dynamic>>('/employees/$id/suspend');
    return res.data!;
  }

  Future<Map<String, dynamic>> assignDevice(String id, Map<String, dynamic> body) async {
    final res = await _dio.post<Map<String, dynamic>>('/devices/$id/assign', data: body);
    return res.data!;
  }

  Future<Map<String, dynamic>> registerTerminal(String deviceId) async {
    final res = await _dio.post<Map<String, dynamic>>('/payments/terminals', data: {'device_id': deviceId});
    return res.data!;
  }

  Future<Map<String, dynamic>> startSoftposSession(Map<String, dynamic> body) async {
    final res = await _dio.post<Map<String, dynamic>>('/payments/softpos/sessions', data: body);
    return res.data!;
  }

  Future<Map<String, dynamic>> confirmSoftpos(String transactionId, Map<String, dynamic> body) async {
    final res = await _dio.post<Map<String, dynamic>>('/payments/softpos/$transactionId/confirm', data: body);
    return res.data!;
  }

  Future<Map<String, dynamic>> createQr(Map<String, dynamic> body) async {
    final res = await _dio.post<Map<String, dynamic>>('/payments/qr', data: body);
    return res.data!;
  }

  Future<Map<String, dynamic>> completeQr(String qrId) async {
    final res = await _dio.post<Map<String, dynamic>>('/payments/qr/$qrId/complete');
    return res.data!;
  }

  Future<Map<String, dynamic>> createPaymentLink(Map<String, dynamic> body) async {
    final res = await _dio.post<Map<String, dynamic>>('/payments/links', data: body);
    return res.data!;
  }

  Future<List<dynamic>> listTransactions({String? q}) async {
    final res = await _dio.get<List<dynamic>>('/payments/transactions', queryParameters: q != null ? {'q': q} : null);
    return res.data ?? [];
  }

  Future<Map<String, dynamic>> refundTransaction(String id, Map<String, dynamic> body) async {
    final res = await _dio.post<Map<String, dynamic>>('/payments/transactions/$id/refund', data: body);
    return res.data!;
  }

  Future<Map<String, dynamic>> paymentAnalyticsToday() async {
    final res = await _dio.get<Map<String, dynamic>>('/payments/analytics/today');
    return res.data!;
  }
}

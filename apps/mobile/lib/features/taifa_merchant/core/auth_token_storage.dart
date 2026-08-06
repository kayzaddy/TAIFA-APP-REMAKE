import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kTokenKey = 'taifa_merchant_access_token';

final merchantAuthStorageProvider = Provider<MerchantAuthStorage>((ref) {
  return MerchantAuthStorage(const FlutterSecureStorage());
});

class MerchantAuthStorage {
  MerchantAuthStorage(this._storage);

  final FlutterSecureStorage _storage;

  Future<String?> readAccessToken() => _storage.read(key: _kTokenKey);

  Future<void> writeAccessToken(String token) => _storage.write(key: _kTokenKey, value: token);

  Future<void> clear() => _storage.delete(key: _kTokenKey);
}

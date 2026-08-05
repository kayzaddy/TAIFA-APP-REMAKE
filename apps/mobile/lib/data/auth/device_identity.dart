// Private injectable field can't be a named initializing formal; suppress the
// otherwise-inapplicable lint.
// ignore_for_file: prefer_initializing_formals

import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// A stable, per-install identifier. It is generated once and persisted, so the
/// device-bound auth token minted against it stays valid across app launches.
///
/// NOTE: `shared_preferences` is adequate for this identifier; the *token* it is
/// paired with is the secret and, in a hardened build, belongs in the platform
/// keystore/keychain (a drop-in swap behind this same API).
class DeviceIdentity {
  DeviceIdentity({SharedPreferences? prefs}) : _prefs = prefs;

  static const _key = 'taifa.device_id';

  SharedPreferences? _prefs;
  String? _cached;

  Future<String> id() async {
    if (_cached != null) return _cached!;
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    var value = prefs.getString(_key);
    if (value == null || value.isEmpty) {
      value = _generate();
      await prefs.setString(_key, value);
    }
    return _cached = value;
  }

  static String _generate() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}

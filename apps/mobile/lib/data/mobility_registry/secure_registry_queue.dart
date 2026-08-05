import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class QueuedRegistrySubmission {
  const QueuedRegistrySubmission({
    required this.type,
    required this.payload,
    required this.queuedAt,
  });

  final String type;
  final Map<String, dynamic> payload;
  final DateTime queuedAt;

  Map<String, dynamic> toJson() => {
    'type': type,
    'payload': payload,
    'queued_at': queuedAt.toUtc().toIso8601String(),
  };

  factory QueuedRegistrySubmission.fromJson(Map<String, dynamic> json) =>
      QueuedRegistrySubmission(
        type: json['type'] as String,
        payload: Map<String, dynamic>.from(json['payload'] as Map),
        queuedAt: DateTime.parse(json['queued_at'] as String),
      );
}

abstract interface class RegistryQueue {
  Future<List<QueuedRegistrySubmission>> read();
  Future<void> write(List<QueuedRegistrySubmission> entries);
  Future<void> add(QueuedRegistrySubmission entry);
}

/// Small encrypted command queue. Document binaries are deliberately excluded;
/// they remain user-selected and upload only through the authenticated API.
class SecureRegistryQueue implements RegistryQueue {
  SecureRegistryQueue({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'taifa.mobility_registry.pending.v1';
  final FlutterSecureStorage _storage;

  @override
  Future<List<QueuedRegistrySubmission>> read() async {
    final encoded = await _storage.read(key: _key);
    if (encoded == null || encoded.isEmpty) return [];
    final decoded = jsonDecode(encoded) as List<dynamic>;
    return decoded
        .map(
          (entry) => QueuedRegistrySubmission.fromJson(
            Map<String, dynamic>.from(entry as Map),
          ),
        )
        .toList();
  }

  @override
  Future<void> write(List<QueuedRegistrySubmission> entries) async {
    if (entries.isEmpty) {
      await _storage.delete(key: _key);
      return;
    }
    await _storage.write(
      key: _key,
      value: jsonEncode(entries.map((entry) => entry.toJson()).toList()),
    );
  }

  @override
  Future<void> add(QueuedRegistrySubmission entry) async {
    final entries = await read();
    final reference = entry.payload['client_reference'];
    if (entries.any(
      (queued) => queued.payload['client_reference'] == reference,
    )) {
      return;
    }
    entries.add(entry);
    await write(entries);
  }
}

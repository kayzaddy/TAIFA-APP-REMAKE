import 'dart:math';

/// Generates and tracks idempotency keys so a retried request never double-moves
/// money. In production this is backed by a durable store (Postgres/Redis) with
/// the persisted [PaymentResult]; here it is an in-memory implementation with
/// the exact same interface.
abstract interface class IdempotencyStore {
  /// Returns a previously stored result for [key], or null if unseen.
  Object? peek(String key);

  /// Records the terminal [result] for [key]. Must be called at most once per
  /// key after the operation reaches a terminal state.
  void remember(String key, Object result);

  bool contains(String key);
}

class InMemoryIdempotencyStore implements IdempotencyStore {
  final Map<String, Object> _store = {};

  @override
  Object? peek(String key) => _store[key];

  @override
  void remember(String key, Object result) => _store[key] = result;

  @override
  bool contains(String key) => _store.containsKey(key);
}

/// Creates a collision-resistant idempotency key. Callers should generate one
/// per user intent (e.g. per tap of "Send") and reuse it across retries.
class IdempotencyKeys {
  const IdempotencyKeys._();

  static final Random _rng = Random.secure();

  static String generate([String prefix = 'idem']) {
    final ts = DateTime.now().microsecondsSinceEpoch;
    final rand = List.generate(
      8,
      (_) => _rng.nextInt(16).toRadixString(16),
    ).join();
    return '${prefix}_${ts.toRadixString(36)}_$rand';
  }
}

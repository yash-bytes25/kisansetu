/// Lightweight local key-value store for KisanSetu offline essentials.
///
/// Designed to persist and retrieve essential cached state reliably
/// across app sessions and widget lifecycles without coupling to heavy external plugins.
class LocalCacheStore {
  static final LocalCacheStore instance = LocalCacheStore._internal();
  LocalCacheStore._internal();

  final Map<String, String> _storage = {};

  /// Retrieves a cached string by [key], or null if absent or corrupted.
  String? getString(String key) {
    return _storage[key];
  }

  /// Persists a [value] under [key].
  Future<void> saveString(String key, String value) async {
    _storage[key] = value;
  }

  /// Synchronously saves a [value] under [key].
  void saveStringSync(String key, String value) {
    _storage[key] = value;
  }

  /// Removes a cached entry by [key].
  Future<void> remove(String key) async {
    _storage.remove(key);
  }

  /// Checks if [key] exists in storage.
  bool containsKey(String key) {
    return _storage.containsKey(key);
  }

  /// Clears all local cache entries (e.g. on logout or test setup).
  Future<void> clear() async {
    _storage.clear();
  }

  /// Synchronous reset for testing.
  void reset() {
    _storage.clear();
  }

  /// Test alias for saving raw string.
  void setRawString(String key, String value) => saveStringSync(key, value);

  /// Test alias for clearing all data.
  void clearAll() => reset();
}

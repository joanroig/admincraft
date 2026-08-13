import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class SecureValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class PlatformSecureValueStore implements SecureValueStore {
  final FlutterSecureStorage _storage;

  const PlatformSecureValueStore([
    this._storage = const FlutterSecureStorage(),
  ]);

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

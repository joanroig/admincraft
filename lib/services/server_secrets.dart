import 'package:admincraft/services/secure_value_store.dart';

/// Holds the parts of a server profile that must not sit in plain storage: the
/// bridge secret key and the pinned certificate.
///
/// Profiles themselves stay in shared preferences, which is readable by anything
/// that can read the app's data directory. A secret key there is enough to run
/// commands on someone's server, so the secrets live in the platform keystore
/// instead and are joined back onto the profile when it is read.
///
/// Values are cached in memory at startup because the model reads profiles
/// synchronously, while the keystore is asynchronous.
class ServerSecrets {
  final SecureValueStore _store;
  final Map<String, String> _values;

  /// False when the keystore could not be read at all, in which case profiles
  /// keep working from whatever plain storage still holds. Losing access to a
  /// key should not lock someone out of their own server list.
  final bool available;

  ServerSecrets._(this._store, this._values, this.available);

  static String _key(String id, String field) => 'server.$id.$field';

  /// Reads the secrets for [ids] into memory.
  static Future<ServerSecrets> load(
    Iterable<String> ids,
    SecureValueStore store,
  ) async {
    final values = <String, String>{};
    try {
      for (final id in ids) {
        for (final field in const ['secretKey', 'certificate']) {
          final value = await store.read(_key(id, field));
          if (value != null) values[_key(id, field)] = value;
        }
      }
      return ServerSecrets._(store, values, true);
    } catch (e) {
      // A keystore that is unavailable (a locked profile, an unsupported
      // browser) must not take the server list down with it.
      return ServerSecrets._(store, values, false);
    }
  }

  String secretKeyFor(String id) => _values[_key(id, 'secretKey')] ?? '';
  String certificateFor(String id) => _values[_key(id, 'certificate')] ?? '';

  /// True when nothing has been stored for [id] yet, which is how a profile
  /// written before secrets moved out of plain storage is recognised.
  bool isEmptyFor(String id) =>
      !_values.containsKey(_key(id, 'secretKey')) &&
      !_values.containsKey(_key(id, 'certificate'));

  Future<void> write(String id, {required String secretKey, required String certificate}) async {
    if (!available) return;
    _values[_key(id, 'secretKey')] = secretKey;
    _values[_key(id, 'certificate')] = certificate;
    await _store.write(_key(id, 'secretKey'), secretKey);
    await _store.write(_key(id, 'certificate'), certificate);
  }

  Future<void> remove(String id) async {
    _values.remove(_key(id, 'secretKey'));
    _values.remove(_key(id, 'certificate'));
    if (!available) return;
    await _store.delete(_key(id, 'secretKey'));
    await _store.delete(_key(id, 'certificate'));
  }

  /// Confirms a value survives a round trip before the plain copy is dropped.
  ///
  /// Writing and then failing to read back is the one outcome that would lose
  /// someone's key, so migration only deletes the old copy after this passes.
  Future<bool> verify(String id, String expectedSecretKey) async {
    if (!available) return false;
    try {
      return await _store.read(_key(id, 'secretKey')) == expectedSecretKey;
    } catch (_) {
      return false;
    }
  }
}

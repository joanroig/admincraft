import 'dart:convert';

import 'package:admincraft/models/server_profile.dart';
import 'package:cryptography/cryptography.dart';

/// Raised when a payload cannot be read, so the UI can tell a wrong passphrase
/// apart from a corrupt or unrelated blob.
class ConfigTransferException implements Exception {
  final String message;
  const ConfigTransferException(this.message);

  @override
  String toString() => message;
}

/// Moves server profiles between devices as a single encrypted blob.
///
/// The blob always carries credentials that grant full command execution on a
/// server, and it is meant to travel through channels the app does not control
/// (a clipboard, a file, cloud storage), so encryption is not optional.
///
/// The envelope is versioned and its header is plain JSON, so a future format
/// can be recognised and rejected with a useful message rather than failing as
/// a decryption error.
class ConfigTransfer {
  static const int _version = 1;
  static const String _magic = 'admincraft-config';

  /// Deliberately slow: the passphrase is chosen by a person, so the cost of
  /// guessing it is whatever this makes it.
  static const int _iterations = 120000;

  static final _cipher = AesGcm.with256bits();

  static Future<SecretKey> _deriveKey(String passphrase, List<int> salt) {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: _iterations,
      bits: 256,
    );
    return pbkdf2.deriveKeyFromPassword(password: passphrase, nonce: salt);
  }

  /// Encrypts [servers] into a self-describing, transferable string.
  static Future<String> export(
      List<ServerProfile> servers, String passphrase) async {
    final plaintext = utf8.encode(
      jsonEncode(
          {'servers': servers.map((server) => server.toJson()).toList()}),
    );

    // A random salt per export means two exports of the same data with the
    // same passphrase do not produce the same blob.
    final salt = AesGcm.with256bits().newNonce();
    final key = await _deriveKey(passphrase, salt);

    final box = await _cipher.encrypt(plaintext, secretKey: key);

    return jsonEncode({
      'magic': _magic,
      'version': _version,
      'salt': base64Encode(salt),
      'nonce': base64Encode(box.nonce),
      'mac': base64Encode(box.mac.bytes),
      'data': base64Encode(box.cipherText),
    });
  }

  /// Reads a blob produced by [export].
  ///
  /// Throws [ConfigTransferException] with something the user can act on:
  /// blobs arrive by copy and paste, so truncation and pasting the wrong thing
  /// are ordinary occurrences rather than edge cases.
  static Future<List<ServerProfile>> import(
      String blob, String passphrase) async {
    final Map<String, dynamic> envelope;
    try {
      final decoded = jsonDecode(blob.trim());
      if (decoded is! Map<String, dynamic>) throw const FormatException();
      envelope = decoded;
    } catch (_) {
      throw const ConfigTransferException(
        'That does not look like an Admincraft config. Check the whole text was copied.',
      );
    }

    if (envelope['magic'] != _magic) {
      throw const ConfigTransferException('That is not an Admincraft config.');
    }

    final version = envelope['version'];
    if (version is int && version > _version) {
      throw const ConfigTransferException(
        'This config was made by a newer version of Admincraft. Update the app to read it.',
      );
    }
    if (version != _version) {
      throw const ConfigTransferException(
          'This Admincraft config has an unsupported format.');
    }

    final List<int> salt;
    final List<int> nonce;
    final List<int> mac;
    final List<int> cipherText;
    try {
      salt = base64Decode(envelope['salt'] as String);
      nonce = base64Decode(envelope['nonce'] as String);
      mac = base64Decode(envelope['mac'] as String);
      cipherText = base64Decode(envelope['data'] as String);

      // AES-GCM uses a 12-byte nonce and a 16-byte authentication tag here.
      // Check these before decryption so truncated envelopes produce a useful
      // import error instead of leaking an implementation exception.
      if (salt.isEmpty ||
          nonce.length != 12 ||
          mac.length != 16 ||
          cipherText.isEmpty) {
        throw const FormatException();
      }
    } catch (_) {
      throw const ConfigTransferException(
          'This Admincraft config is incomplete or damaged.');
    }

    final key = await _deriveKey(passphrase, salt);

    final List<int> plaintext;
    try {
      plaintext = await _cipher.decrypt(
        SecretBox(
          cipherText,
          nonce: nonce,
          mac: Mac(mac),
        ),
        secretKey: key,
      );
    } catch (_) {
      // AES-GCM fails the same way for a wrong key and for tampered data, so
      // the likely cause is the one worth naming.
      throw const ConfigTransferException(
          'Wrong passphrase, or the config is damaged.');
    }

    try {
      final decoded =
          jsonDecode(utf8.decode(plaintext)) as Map<String, dynamic>;
      final servers = decoded['servers'] as List<dynamic>;
      return servers
          .map((entry) => ServerProfile.fromJson(entry as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw const ConfigTransferException(
          'The decrypted config contains invalid server data.');
    }
  }

  /// Suggested file name for an export.
  static String fileName() => 'admincraft-servers.json';
}

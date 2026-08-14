import 'dart:convert';

import 'package:admincraft/models/connection_security.dart';
import 'package:admincraft/models/app_theme.dart';
import 'package:admincraft/models/server_profile.dart';
import 'package:admincraft/services/server_secrets.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PersistenceService {
  static const _aliasKey = 'alias';
  static const _ipKey = 'ip';
  static const _portKey = 'port';
  static const _secretKeyKey = 'secretKey';
  static const _certificateKey = 'certificateKey';
  static const _connectionSecurityKey = 'connectionSecurity';
  static const _serversKey = 'servers';
  static const _serversUpdatedAtKey = 'serversUpdatedAt';
  static const _selectedServerKey = 'selectedServer';
  static const _commandUsageKey = 'commandUsage';
  static const _maxOutLinesKey = 'maxOutLines';
  static const _themeModeKey = 'themeMode';
  static const _appThemeKey = 'appTheme';
  static const _fontKey = 'font';
  static const _fontSizeKey = 'fontSize';
  static const _commandHistoryKey = 'commandHistory';
  static const _userCommandsKey = 'userCommands';

  final SharedPreferences _prefs;

  /// Null only in tests and before the keystore has been read.
  final ServerSecrets? _secrets;

  PersistenceService(this._prefs, [this._secrets]);

  /// Ids of stored profiles, needed to load their secrets before the model is
  /// built. Read straight from the entries so it works without a vault.
  static List<String> storedServerIds(SharedPreferences prefs) {
    final stored = prefs.getStringList(_serversKey);
    if (stored == null) return const ['default'];
    return stored
        .map((entry) => (jsonDecode(entry) as Map<String, dynamic>)['id'] as String)
        .toList();
  }

  Future<void> _set<T>(String key, T value) async {
    if (value is String) {
      await _prefs.setString(key, value);
    } else if (value is int) {
      await _prefs.setInt(key, value);
    } else if (value is double) {
      await _prefs.setDouble(key, value);
    } else if (value is bool) {
      await _prefs.setBool(key, value);
    } else if (value is List<String>) {
      await _prefs.setStringList(key, value);
    } else {
      throw ArgumentError('Unsupported type: ${value.runtimeType}');
    }
  }

  Future<void> saveMaxOutLines(int lines) async {
    await _set(_maxOutLinesKey, lines);
  }

  Future<void> saveThemeMode(ThemeMode themeMode) async {
    await _set(_themeModeKey, themeMode.index);
  }

  Future<void> saveAppTheme(AppTheme appTheme) async {
    await _set(_appThemeKey, appTheme.name);
  }

  Future<void> saveFont(String font) async {
    await _set(_fontKey, font);
  }

  Future<void> saveFontSize(double fontSize) async {
    await _set(_fontSizeKey, fontSize);
  }

  Future<void> saveCommandHistory(List<String> history) async {
    await _set(_commandHistoryKey, history);
  }

  Future<void> saveUserCommands(Set<String> userCommands) async {
    await _set(_userCommandsKey, userCommands.toList());
  }

  String get alias => _prefs.getString(_aliasKey) ?? 'My World';
  String get ip => _prefs.getString(_ipKey) ?? '';
  int get port => _prefs.getInt(_portKey) ?? 8080;
  String get secretKey => _prefs.getString(_secretKeyKey) ?? '';
  String get certificate => _prefs.getString(_certificateKey) ?? '';

  ConnectionSecurity get connectionSecurity {
    final stored = _prefs.getString(_connectionSecurityKey);
    if (stored == null) return _legacyConnectionSecurity;
    return ConnectionSecurity.values.firstWhere(
      (security) => security.name == stored,
      orElse: () => _legacyConnectionSecurity,
    );
  }

  /// Before this setting existed, TLS was enabled exactly when a certificate
  /// had been loaded. Keep users on the behaviour they already had.
  ConnectionSecurity get _legacyConnectionSecurity => certificate.isEmpty
      ? ConnectionSecurity.privateNetwork
      : ConnectionSecurity.customCertificate;

  // ---------------------------------------------------------------------------
  // Server profiles
  // ---------------------------------------------------------------------------

  /// Saved servers.
  ///
  /// When nothing has been stored yet the single set of connection details
  /// from before multi-server support is promoted to the first profile, so an
  /// existing install keeps its server instead of starting empty.
  List<ServerProfile> get servers {
    final stored = _prefs.getStringList(_serversKey);
    if (stored != null) {
      return stored.map((entry) {
        final json = jsonDecode(entry) as Map<String, dynamic>;
        final profile = ServerProfile.fromJson(json);

        // Secrets live in the keystore. A profile written before that still
        // carries them inline, so fall back to whatever the entry itself has
        // rather than blanking the key and breaking the connection.
        final secrets = _secrets;
        if (secrets == null || secrets.isEmptyFor(profile.id)) return profile;

        return profile.copyWith(
          secretKey: secrets.secretKeyFor(profile.id),
          certificate: secrets.certificateFor(profile.id),
        );
      }).toList();
    }

    return [
      ServerProfile(
        id: 'default',
        alias: alias,
        ip: ip,
        port: port,
        secretKey: secretKey,
        certificate: certificate,
        security: connectionSecurity,
      )
    ];
  }

  Future<void> saveServers(List<ServerProfile> servers) async {
    final secrets = _secrets;

    // Write the keystore first: a profile saved without its key is unusable,
    // whereas a key with no profile is merely orphaned.
    if (secrets != null && secrets.available) {
      for (final server in servers) {
        await secrets.write(
          server.id,
          secretKey: server.secretKey,
          certificate: server.certificate,
        );
      }
    }

    // Only omit the secrets from plain storage once they are safely elsewhere.
    final keepSecretsInline = secrets == null || !secrets.available;
    await _set(
      _serversKey,
      servers
          .map((server) =>
              jsonEncode(server.toJson(includeSecrets: keepSecretsInline)))
          .toList(),
    );
    await _set(
      _serversUpdatedAtKey,
      DateTime.now().toUtc().millisecondsSinceEpoch,
    );
  }

  /// Forgets the secrets belonging to a deleted profile.
  ///
  /// Without this the key outlives the server it belonged to, which is exactly
  /// the sort of leftover the keystore is meant to avoid.
  Future<void> forgetServerSecrets(String id) async {
    await _secrets?.remove(id);
  }

  DateTime? get serversUpdatedAt {
    final value = _prefs.getInt(_serversUpdatedAtKey);
    return value == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
  }

  /// How often each command has been sent, used to order completions so the
  /// commands someone actually reaches for come first.
  Map<String, int> get commandUsage {
    final stored = _prefs.getString(_commandUsageKey);
    if (stored == null) return {};
    final decoded = jsonDecode(stored) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(key, value as int));
  }

  Future<void> saveCommandUsage(Map<String, int> usage) async {
    await _set(_commandUsageKey, jsonEncode(usage));
  }

  String? get selectedServerId => _prefs.getString(_selectedServerKey);

  Future<void> saveSelectedServerId(String id) async {
    await _set(_selectedServerKey, id);
  }

  int get maxOutLines => _prefs.getInt(_maxOutLinesKey) ?? 100;
  ThemeMode get themeMode =>
      ThemeMode.values[_prefs.getInt(_themeModeKey) ?? 0];
  AppTheme get appTheme {
    final stored = _prefs.getString(_appThemeKey);
    return AppTheme.values.firstWhere(
      (theme) => theme.name == stored,
      orElse: () => AppTheme.dirt,
    );
  }

  String get font => _prefs.getString(_fontKey) ?? 'Roboto';
  double get fontSize => _prefs.getDouble(_fontSizeKey) ?? 16;

  List<String> get commandHistory =>
      _prefs.getStringList(_commandHistoryKey) ?? [];
  Set<String> get userCommands =>
      _prefs.getStringList(_userCommandsKey)?.toSet() ?? {};

  Future<void> addCommandToHistory(String command) async {
    final history = List<String>.from(commandHistory);
    history.remove(command);
    history.add(command);
    await saveCommandHistory(history);
  }

  Future<void> removeCommandFromHistory(int index) async {
    final history = List<String>.from(commandHistory);
    if (index >= 0 && index < history.length) {
      history.removeAt(index);
      await saveCommandHistory(history);
    }
  }

  Future<void> clearCommandHistory() async {
    await saveCommandHistory([]);
  }

  Future<void> addUserCommand(String command) async {
    final commands = userCommands.toList();
    commands.add(command);
    await saveUserCommands(commands.toSet());
  }

  Future<void> removeUserCommand(String command) async {
    final commands = userCommands.toList();
    commands.remove(command);
    await saveUserCommands(commands.toSet());
  }

  Future<void> clearUserCommands() async {
    await saveUserCommands({});
  }
}

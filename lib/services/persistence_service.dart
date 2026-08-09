import 'dart:convert';

import 'package:admincraft/models/connection_security.dart';
import 'package:admincraft/models/server_profile.dart';
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
  static const _selectedServerKey = 'selectedServer';
  static const _commandUsageKey = 'commandUsage';
  static const _maxOutLinesKey = 'maxOutLines';
  static const _themeModeKey = 'themeMode';
  static const _fontKey = 'font';
  static const _fontSizeKey = 'fontSize';
  static const _commandHistoryKey = 'commandHistory';
  static const _userCommandsKey = 'userCommands';

  final SharedPreferences _prefs;

  PersistenceService(this._prefs);

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
  ConnectionSecurity get _legacyConnectionSecurity =>
      certificate.isEmpty ? ConnectionSecurity.privateNetwork : ConnectionSecurity.customCertificate;

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
      return stored
          .map((entry) => ServerProfile.fromJson(jsonDecode(entry) as Map<String, dynamic>))
          .toList();
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
    await _set(
      _serversKey,
      servers.map((server) => jsonEncode(server.toJson())).toList(),
    );
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
  ThemeMode get themeMode => ThemeMode.values[_prefs.getInt(_themeModeKey) ?? 0];
  String get font => _prefs.getString(_fontKey) ?? 'Roboto';
  double get fontSize => _prefs.getDouble(_fontSizeKey) ?? 16;

  List<String> get commandHistory => _prefs.getStringList(_commandHistoryKey) ?? [];
  Set<String> get userCommands => _prefs.getStringList(_userCommandsKey)?.toSet() ?? {};

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

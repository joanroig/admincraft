import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PersistenceService {
  static const _aliasKey = 'alias';
  static const _ipKey = 'ip';
  static const _portKey = 'port';
  static const _secretKeyKey = 'secretKey';
  static const _certificateKey = 'certificateKey';
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

  Future<void> saveConnectionDetails({
    required String alias,
    required String ip,
    required int port,
    required String secretKey,
    required String certificate,
  }) async {
    await Future.wait([
      _set(_aliasKey, alias),
      _set(_ipKey, ip),
      _set(_portKey, port),
      _set(_secretKeyKey, secretKey),
      _set(_certificateKey, certificate),
    ]);
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

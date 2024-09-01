import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PersistenceService {
  static const _aliasKey = 'alias';
  static const _hostnameKey = 'hostname';
  static const _usernameKey = 'username';
  static const _pemKeyContentKey = 'pemKeyContent';
  static const _portKey = 'port';
  static const _commandPrefixKey = 'commandPrefix';
  static const _maxOutLinesKey = 'maxOutLines';
  static const _themeModeKey = 'themeMode';
  static const _commandHistoryKey = 'commandHistory';
  static const _userCommandsKey = 'userCommands';

  final SharedPreferences _prefs;

  PersistenceService(this._prefs);

  Future<void> _set<T>(String key, T value) async {
    if (value is String) {
      await _prefs.setString(key, value);
    } else if (value is int) {
      await _prefs.setInt(key, value);
    } else if (value is List<String>) {
      await _prefs.setStringList(key, value);
    }
  }

  Future<void> saveConnectionDetails({
    required String alias,
    required String hostname,
    required String username,
    required String pemKeyContent,
    required int port,
    required String commandPrefix,
  }) async {
    await Future.wait([
      _set(_aliasKey, alias),
      _set(_hostnameKey, hostname),
      _set(_usernameKey, username),
      _set(_pemKeyContentKey, pemKeyContent),
      _set(_portKey, port),
      _set(_commandPrefixKey, commandPrefix),
    ]);
  }

  Future<void> saveMaxOutLines(int lines) async {
    await _set(_maxOutLinesKey, lines);
  }

  Future<void> saveThemeMode(ThemeMode themeMode) async {
    await _set(_themeModeKey, themeMode.index);
  }

  Future<void> saveCommandHistory(List<String> history) async {
    await _set(_commandHistoryKey, history);
  }

  Future<void> saveUserCommands(Set<String> userCommands) async {
    await _set(_userCommandsKey, userCommands.toList());
  }

  String get alias => _prefs.getString(_aliasKey) ?? 'My World';
  String get hostname => _prefs.getString(_hostnameKey) ?? '';
  String get username => _prefs.getString(_usernameKey) ?? 'ubuntu';
  String get pemKeyContent => _prefs.getString(_pemKeyContentKey) ?? '';
  int get port => _prefs.getInt(_portKey) ?? 22;
  String get commandPrefix => _prefs.getString(_commandPrefixKey) ?? 'sudo docker exec minecraft send-command';
  int get maxOutLines => _prefs.getInt(_maxOutLinesKey) ?? 100;
  ThemeMode get themeMode {
    final index = _prefs.getInt(_themeModeKey) ?? 0;
    return ThemeMode.values[index];
  }

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

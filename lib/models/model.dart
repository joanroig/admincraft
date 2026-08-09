import 'dart:async';

import 'package:admincraft/models/connection_security.dart';
import 'package:admincraft/services/persistence_service.dart';
import 'package:flutter/material.dart';

class Model with ChangeNotifier {
  final PersistenceService _persistenceService;
  String _output = '';

  String get output => _output;

  String get alias => _persistenceService.alias;
  String get ip => _persistenceService.ip;
  int get port => _persistenceService.port;
  String get secretKey => _persistenceService.secretKey;
  String get certificate => _persistenceService.certificate;
  ConnectionSecurity get connectionSecurity => _persistenceService.connectionSecurity;
  int get maxOutLines => _persistenceService.maxOutLines;
  ThemeMode get themeMode => _persistenceService.themeMode;
  String get font => _persistenceService.font;
  double get fontSize => _persistenceService.fontSize;

  // Provide read-only access to collections
  Set<String> get userCommands => Set.unmodifiable(_persistenceService.userCommands);
  List<String> get commandHistory => List.unmodifiable(_persistenceService.commandHistory);

  Model(this._persistenceService);

  Future<void> _updatePersistenceService(Future<void> Function() updateAction) async {
    await updateAction();
    notifyListeners();
  }

  Future<void> setConnectionDetails({
    required String alias,
    required String ip,
    required int port,
    required String secretKey,
    required String certificate,
    required ConnectionSecurity connectionSecurity,
  }) async {
    await _updatePersistenceService(() => _persistenceService.saveConnectionDetails(
          alias: alias,
          ip: ip,
          port: port,
          secretKey: secretKey,
          certificate: certificate,
          connectionSecurity: connectionSecurity,
        ));
  }

  Future<void> setMaxOutputLines(int lines) async {
    await _updatePersistenceService(() => _persistenceService.saveMaxOutLines(lines));
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    await _updatePersistenceService(() => _persistenceService.saveThemeMode(themeMode));
  }

  Future<void> setFont(String font) async {
    await _updatePersistenceService(() => _persistenceService.saveFont(font));
  }

  Future<void> setFontSize(double fontSize) async {
    await _updatePersistenceService(() => _persistenceService.saveFontSize(fontSize));
  }

  Future<void> setCommandHistory(List<String> history) async {
    await _updatePersistenceService(() => _persistenceService.saveCommandHistory(history));
  }

  Future<void> addUserCommand(String command) async {
    await _updatePersistenceService(() => _persistenceService.addUserCommand(command));
  }

  Future<void> removeUserCommand(String command) async {
    await _updatePersistenceService(() => _persistenceService.removeUserCommand(command));
  }

  /// Players currently connected, tracked from the server log so that command
  /// completion can offer real names instead of a fixed list.
  final Set<String> _onlinePlayers = {};
  Set<String> get onlinePlayers => Set.unmodifiable(_onlinePlayers);

  static final RegExp _connected = RegExp(r'Player connected:\s*([^,]+)');
  static final RegExp _disconnected = RegExp(r'Player disconnected:\s*([^,]+)');

  void _trackPlayers(String chunk) {
    for (final line in chunk.split('\n')) {
      final joined = _connected.firstMatch(line);
      if (joined != null) {
        _onlinePlayers.add(joined.group(1)!.trim());
        continue;
      }
      final left = _disconnected.firstMatch(line);
      if (left != null) {
        _onlinePlayers.remove(left.group(1)!.trim());
      }
    }
  }

  void clearOutput() {
    _output = '';
    _onlinePlayers.clear();
  }

  void appendOutputCommand(String command) {
    _trackPlayers(command);
    _output += "$command\n";
    final lines = _output.split('\n');
    if (lines.length > _persistenceService.maxOutLines) {
      _output = lines.sublist(lines.length - _persistenceService.maxOutLines).join('\n');
    }
    notifyListeners();
  }

  Future<void> addCommandToHistory(String command) async {
    await _updatePersistenceService(() => _persistenceService.addCommandToHistory(command));
  }

  Future<void> removeCommandFromHistory(int index) async {
    await _updatePersistenceService(() => _persistenceService.removeCommandFromHistory(index));
  }

  Future<void> clearCommandHistory() async {
    await _updatePersistenceService(() => _persistenceService.clearCommandHistory());
  }

  Future<void> clearUserCommands() async {
    await _updatePersistenceService(() => _persistenceService.clearUserCommands());
  }
}

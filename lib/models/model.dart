import 'dart:async';

import 'package:admincraft/models/connection_security.dart';
import 'package:admincraft/models/server_profile.dart';
import 'package:admincraft/models/world_state.dart';
import 'package:admincraft/services/console_parser.dart';
import 'package:admincraft/services/persistence_service.dart';
import 'package:flutter/material.dart';

class Model with ChangeNotifier {
  final PersistenceService _persistenceService;
  String _output = '';

  List<ServerProfile> _servers = [];
  late String _selectedServerId;

  String get output => _output;

  List<ServerProfile> get servers => List.unmodifiable(_servers);
  String get selectedServerId => _selectedServerId;

  /// The server the app is configured against. Every connection getter reads
  /// from here, so switching profile switches the whole app over.
  ServerProfile get selectedServer => _servers.firstWhere(
        (server) => server.id == _selectedServerId,
        orElse: () => _servers.first,
      );

  String get alias => selectedServer.alias;
  String get ip => selectedServer.ip;
  int get port => selectedServer.port;
  String get secretKey => selectedServer.secretKey;
  String get certificate => selectedServer.certificate;
  ConnectionSecurity get connectionSecurity => selectedServer.security;
  int get maxOutLines => _persistenceService.maxOutLines;
  ThemeMode get themeMode => _persistenceService.themeMode;
  String get font => _persistenceService.font;
  double get fontSize => _persistenceService.fontSize;

  // Provide read-only access to collections
  Set<String> get userCommands => Set.unmodifiable(_persistenceService.userCommands);
  List<String> get commandHistory => List.unmodifiable(_persistenceService.commandHistory);

  Model(this._persistenceService) {
    _servers = _persistenceService.servers;
    if (_servers.isEmpty) _servers = [ServerProfile.empty(_newId())];

    final stored = _persistenceService.selectedServerId;
    _selectedServerId = _servers.any((server) => server.id == stored) ? stored! : _servers.first.id;
  }

  static String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  Future<void> _persistServers() async {
    await _persistenceService.saveServers(_servers);
    notifyListeners();
  }

  /// Switches to another saved server.
  Future<void> selectServer(String id) async {
    if (!_servers.any((server) => server.id == id)) return;
    _selectedServerId = id;
    _resetSession();
    await _persistenceService.saveSelectedServerId(id);
    notifyListeners();
  }

  /// Adds a blank server and selects it, so the settings form edits the new
  /// one rather than overwriting whichever was open.
  Future<ServerProfile> addServer() async {
    final created = ServerProfile.empty(_newId());
    _servers = [..._servers, created];
    _selectedServerId = created.id;
    _resetSession();
    await _persistenceService.saveSelectedServerId(created.id);
    await _persistServers();
    return created;
  }

  /// Removes a server. The last one is kept: with none left there would be
  /// nothing for the connection getters to read.
  Future<void> deleteServer(String id) async {
    if (_servers.length <= 1) return;
    _servers = _servers.where((server) => server.id != id).toList();
    if (_selectedServerId == id) {
      _selectedServerId = _servers.first.id;
      _resetSession();
      await _persistenceService.saveSelectedServerId(_selectedServerId);
    }
    await _persistServers();
  }

  Future<void> _updatePersistenceService(Future<void> Function() updateAction) async {
    await updateAction();
    notifyListeners();
  }

  /// Applies edits to the selected server.
  Future<void> setConnectionDetails({
    required String alias,
    required String ip,
    required int port,
    required String secretKey,
    required String certificate,
    required ConnectionSecurity connectionSecurity,
  }) async {
    _servers = _servers
        .map((server) => server.id == _selectedServerId
            ? server.copyWith(
                alias: alias,
                ip: ip,
                port: port,
                secretKey: secretKey,
                certificate: certificate,
                security: connectionSecurity,
              )
            : server)
        .toList();
    await _persistServers();
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

  WorldState _world = const WorldState();
  WorldState get world => _world;

  /// Records what was set from here for the values the server cannot report
  /// back, so the panel can still show them.
  void recordWeather(String weather) {
    _world = _world.copyWith(lastWeather: weather);
    notifyListeners();
  }

  void recordDifficulty(String difficulty) {
    _world = _world.copyWith(lastDifficulty: difficulty);
    notifyListeners();
  }

  /// Drops everything tied to the connected server: output, tracked players
  /// and world state all belong to the session that is ending.
  void _resetSession() {
    _output = '';
    _onlinePlayers.clear();
    _world = const WorldState();
  }

  void clearOutput() => _resetSession();

  void appendOutputCommand(String command) {
    for (final (name, joined) in ConsoleParser.playerChanges(command)) {
      joined ? _onlinePlayers.add(name) : _onlinePlayers.remove(name);
    }
    _world = ConsoleParser.apply(_world, command);
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

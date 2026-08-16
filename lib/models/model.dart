import 'dart:async';

import 'package:admincraft/models/connection_security.dart';
import 'package:admincraft/models/app_theme.dart';
import 'package:admincraft/models/minecraft_edition.dart';
import 'package:admincraft/models/server_profile.dart';
import 'package:admincraft/models/world_state.dart';
import 'package:admincraft/services/console_parser.dart';
import 'package:admincraft/services/android_widget_service.dart';
import 'package:admincraft/services/persistence_service.dart';
import 'package:flutter/material.dart';

class Model with ChangeNotifier {
  final PersistenceService _persistenceService;
  String _output = '';

  List<ServerProfile> _servers = [];
  late String _selectedServerId;

  String get output => _output;

  List<ServerProfile> get servers => List.unmodifiable(_servers);
  DateTime? get serversUpdatedAt => _persistenceService.serversUpdatedAt;
  String get selectedServerId => _selectedServerId;

  /// The server the app is configured against. Every connection getter reads
  /// from here, so switching profile switches the whole app over.
  /// Whether the welcome screen has been left behind.
  ///
  /// A blank profile always exists so the connection getters have something to
  /// read, so this cannot be answered by counting servers.
  bool get onboardingCompleted => _persistenceService.onboardingCompleted;

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
  MinecraftEdition get minecraftEdition => selectedServer.edition;
  int get maxOutLines => _persistenceService.maxOutLines;
  ThemeMode get themeMode => _persistenceService.themeMode;
  AppTheme get appTheme => _persistenceService.appTheme;
  String get font => _persistenceService.font;
  double get fontSize => _persistenceService.fontSize;
  String get terminalFont => _persistenceService.terminalFont;
  double get terminalFontSize => _persistenceService.terminalFontSize;
  bool get terminalAutoScroll => _persistenceService.terminalAutoScroll;
  String get consoleTimestampMode => _persistenceService.consoleTimestampMode;
  String get consoleFilterPattern => _persistenceService.consoleFilterPattern;
  bool get hideCommonConsoleNoise => _persistenceService.hideCommonConsoleNoise;

  // Provide read-only access to collections
  Set<String> get userCommands =>
      Set.unmodifiable(_persistenceService.userCommands);
  List<String> get commandHistory =>
      List.unmodifiable(_persistenceService.commandHistory);
  List<String> get favoriteCommands =>
      List.unmodifiable(_persistenceService.favoriteCommands);

  Model(this._persistenceService) {
    _servers = _persistenceService.servers;
    if (_servers.isEmpty) _servers = [ServerProfile.empty(_newId())];

    final stored = _persistenceService.selectedServerId;
    _selectedServerId = _servers.any((server) => server.id == stored)
        ? stored!
        : _servers.first.id;

    _commandUsage = _persistenceService.commandUsage;
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
    await _persistenceService.forgetServerSecrets(id);
    if (_selectedServerId == id) {
      _selectedServerId = _servers.first.id;
      _resetSession();
      await _persistenceService.saveSelectedServerId(_selectedServerId);
    }
    await _persistServers();
  }

  /// Adds imported servers, replacing any whose id already exists.
  ///
  /// Matching on id means re-importing an updated config updates the servers
  /// already here instead of leaving two copies of the same profile. Profiles
  /// with different ids are appended.
  ///
  /// Returns how many were added and how many were updated, since the user
  /// otherwise has no way to tell what an import actually did.
  Future<({int added, int updated})> importServers(
    List<ServerProfile> incoming,
  ) async {
    var added = 0;
    var updated = 0;

    final merged = [..._servers];
    for (final server in incoming) {
      final index = merged.indexWhere((existing) => existing.id == server.id);
      if (index >= 0) {
        merged[index] = server;
        updated++;
      } else {
        merged.add(server);
        added++;
      }
    }

    _servers = merged;
    await _persistenceService.markOnboardingCompleted();
    await _persistServers();
    return (added: added, updated: updated);
  }

  /// Replaces the local profile set with an already decrypted cloud copy.
  Future<void> replaceServers(List<ServerProfile> incoming) async {
    if (incoming.isEmpty) return;
    _servers = [...incoming];
    if (!_servers.any((server) => server.id == _selectedServerId)) {
      _selectedServerId = _servers.first.id;
      await _persistenceService.saveSelectedServerId(_selectedServerId);
    }
    _resetSession();
    await _persistServers();
  }

  Future<void> _updatePersistenceService(
    Future<void> Function() updateAction,
  ) async {
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
    required MinecraftEdition minecraftEdition,
    String? iconAsset,
    String? customIconBase64,
  }) async {
    _servers = _servers
        .map(
          (server) => server.id == _selectedServerId
              ? server.copyWith(
                  alias: alias,
                  ip: ip,
                  port: port,
                  secretKey: secretKey,
                  certificate: certificate,
                  security: connectionSecurity,
                  edition: minecraftEdition,
                  iconAsset: iconAsset,
                  customIconBase64: customIconBase64,
                )
              : server,
        )
        .toList();
    await _persistenceService.markOnboardingCompleted();
    await _persistServers();
    await AndroidWidgetService.update(selectedServer, _world);
  }

  Future<void> setMaxOutputLines(int lines) async {
    await _updatePersistenceService(
      () => _persistenceService.saveMaxOutLines(lines),
    );
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    await _updatePersistenceService(
      () => _persistenceService.saveThemeMode(themeMode),
    );
  }

  Future<void> setAppTheme(AppTheme appTheme) async {
    await _updatePersistenceService(
      () => _persistenceService.saveAppTheme(appTheme),
    );
  }

  Future<void> setFont(String font) async {
    await _updatePersistenceService(() => _persistenceService.saveFont(font));
  }

  Future<void> setFontSize(double fontSize) async {
    await _updatePersistenceService(
      () => _persistenceService.saveFontSize(fontSize),
    );
  }

  Future<void> setCommandHistory(List<String> history) async {
    await _updatePersistenceService(
      () => _persistenceService.saveCommandHistory(history),
    );
  }

  Map<String, int> _commandUsage = {};
  Map<String, int> get commandUsage => Map.unmodifiable(_commandUsage);

  /// Counts a command as used, keyed by its name so that arguments do not
  /// fragment the count across "give bob stone" and "give ann dirt".
  Future<void> recordCommandUsage(String command) async {
    final name = command.trim().split(RegExp(r'\s+')).first.toLowerCase();
    if (name.isEmpty) return;
    _commandUsage = {..._commandUsage, name: (_commandUsage[name] ?? 0) + 1};
    await _persistenceService.saveCommandUsage(_commandUsage);
    notifyListeners();
  }

  Future<void> addUserCommand(String command) async {
    await _updatePersistenceService(
      () => _persistenceService.addUserCommand(command),
    );
  }

  Future<void> removeUserCommand(String command) async {
    await _updatePersistenceService(
      () => _persistenceService.removeUserCommand(command),
    );
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
    unawaited(AndroidWidgetService.update(selectedServer, _world));
  }

  void clearOutput() => _resetSession();

  /// Set once a `list` header has been seen, because the names arrive on the
  /// following line, which may even come in a later message.
  bool _expectingPlayerNames = false;

  void _trackPlayers(String chunk) {
    for (final (name, joined) in ConsoleParser.playerChanges(
      chunk,
      edition: minecraftEdition,
    )) {
      joined ? _onlinePlayers.add(name) : _onlinePlayers.remove(name);
    }

    for (final line in chunk.split('\n')) {
      final count = ConsoleParser.playerCountHeader(
        line,
        edition: minecraftEdition,
      );
      if (count != null) {
        // A `list` reply is authoritative, so it replaces what was tracked
        // from connect and disconnect lines rather than adding to it.
        _onlinePlayers.clear();
        final inlineNames = ConsoleParser.namesFromPlayerCountHeader(
          line,
          edition: minecraftEdition,
        );
        _onlinePlayers.addAll(inlineNames);
        _expectingPlayerNames = count > 0 && inlineNames.isEmpty;
        continue;
      }

      if (_expectingPlayerNames && line.trim().isNotEmpty) {
        _onlinePlayers.addAll(ConsoleParser.namesFrom(line));
        _expectingPlayerNames = false;
      }
    }
  }

  void appendOutputCommand(String command) {
    final previousPlayers = _world.playersOnline;
    final previousLimit = _world.playerLimit;
    _trackPlayers(command);
    _world = ConsoleParser.apply(_world, command, edition: minecraftEdition);
    if (_world.playersOnline != previousPlayers ||
        _world.playerLimit != previousLimit) {
      unawaited(AndroidWidgetService.update(selectedServer, _world));
    }
    _output += "$command\n";
    final lines = _output.split('\n');
    if (lines.length > _persistenceService.maxOutLines) {
      _output = lines
          .sublist(lines.length - _persistenceService.maxOutLines)
          .join('\n');
    }
    notifyListeners();
  }

  Future<void> addCommandToHistory(String command) async {
    await _updatePersistenceService(
      () => _persistenceService.addCommandToHistory(command),
    );
  }

  Future<void> removeCommandFromHistory(int index) async {
    await _updatePersistenceService(
      () => _persistenceService.removeCommandFromHistory(index),
    );
  }

  Future<void> clearCommandHistory() async {
    await _updatePersistenceService(
      () => _persistenceService.clearCommandHistory(),
    );
  }

  Future<void> clearUserCommands() async {
    await _updatePersistenceService(
      () => _persistenceService.clearUserCommands(),
    );
  }

  Future<void> setTerminalFont(String value) async {
    await _updatePersistenceService(
      () => _persistenceService.saveTerminalFont(value),
    );
  }

  Future<void> setTerminalFontSize(double value) async {
    await _updatePersistenceService(
      () => _persistenceService.saveTerminalFontSize(value),
    );
  }

  Future<void> setTerminalAutoScroll(bool value) async {
    await _updatePersistenceService(
      () => _persistenceService.saveTerminalAutoScroll(value),
    );
  }

  Future<void> setConsoleTimestampMode(String value) async {
    await _updatePersistenceService(
      () => _persistenceService.saveConsoleTimestampMode(value),
    );
  }

  Future<void> setConsoleFilterPattern(String value) async {
    await _updatePersistenceService(
      () => _persistenceService.saveConsoleFilterPattern(value),
    );
  }

  Future<void> setHideCommonConsoleNoise(bool value) async {
    await _updatePersistenceService(
      () => _persistenceService.saveHideCommonConsoleNoise(value),
    );
  }

  Future<void> addFavoriteCommand(String command) async {
    final normalized = command.trim();
    if (normalized.isEmpty || favoriteCommands.contains(normalized)) return;
    await _updatePersistenceService(
      () => _persistenceService.saveFavoriteCommands([
        ...favoriteCommands,
        normalized,
      ]),
    );
  }

  Future<void> removeFavoriteCommand(String command) async {
    await _updatePersistenceService(
      () => _persistenceService.saveFavoriteCommands(
        favoriteCommands.where((value) => value != command).toList(),
      ),
    );
  }
}

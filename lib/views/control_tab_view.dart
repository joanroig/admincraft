import 'dart:async';

import 'package:admincraft/controllers/connection_controller.dart';
import 'package:admincraft/data/bedrock_gamerules.dart';
import 'package:admincraft/models/connection_security.dart';
import 'package:admincraft/data/bedrock_ids.dart';
import 'package:admincraft/data/java_ids.dart';
import 'package:admincraft/models/minecraft_edition.dart';
import 'package:admincraft/models/model.dart';
import 'package:admincraft/models/world_state.dart';
import 'package:admincraft/services/console_output_formatter.dart';
import 'package:admincraft/utils/command_utils.dart';
import 'package:admincraft/utils/dialog_utils.dart';
import 'package:admincraft/utils/toast_utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// A command that needs one value from the user before it can be sent.
class _PromptedAction {
  final String label;
  final IconData icon;
  final String placeholder;
  final String Function(String value) build;

  const _PromptedAction(this.label, this.icon, this.placeholder, this.build);
}

/// One selectable value, such as a time of day or a weather type.
class _Choice {
  final String label;
  final IconData icon;
  final String value;

  const _Choice(this.label, this.icon, this.value);
}

class ControlTab extends StatefulWidget {
  final bool isEnabled;
  const ControlTab({super.key, required this.isEnabled});

  @override
  State<ControlTab> createState() => _ControlTabState();
}

class _ControlTabState extends State<ControlTab> {
  String? _lastCommand;
  bool _loadingRules = false;
  bool _responseExpanded = false;
  bool _gamerulesExpanded = false;

  static final List<_PromptedAction> _promptedActions = [
    _PromptedAction(
      'Whitelist',
      Icons.person_add,
      'player',
      (p) => 'whitelist add $p',
    ),
    _PromptedAction(
      'Unwhitelist',
      Icons.person_remove,
      'player',
      (p) => 'whitelist remove $p',
    ),
    _PromptedAction('Kick', Icons.logout, 'player', (p) => 'kick $p'),
    _PromptedAction('Announce', Icons.campaign, 'message', (m) => 'say $m'),
  ];

  static const List<_Choice> _bedrockTimes = [
    _Choice('Sunrise', Icons.wb_twilight, 'sunrise'),
    _Choice('Day', Icons.wb_sunny, 'day'),
    _Choice('Noon', Icons.light_mode, 'noon'),
    _Choice('Sunset', Icons.wb_twilight, 'sunset'),
    _Choice('Night', Icons.nightlight_round, 'night'),
    _Choice('Midnight', Icons.bedtime, 'midnight'),
  ];

  static const List<_Choice> _javaTimes = [
    _Choice('Day', Icons.wb_sunny, 'day'),
    _Choice('Noon', Icons.light_mode, 'noon'),
    _Choice('Night', Icons.nightlight_round, 'night'),
    _Choice('Midnight', Icons.bedtime, 'midnight'),
  ];

  static const List<_Choice> _weathers = [
    _Choice('Clear', Icons.wb_sunny, 'clear'),
    _Choice('Rain', Icons.water_drop, 'rain'),
    _Choice('Thunder', Icons.thunderstorm, 'thunder'),
  ];

  static const List<_Choice> _difficulties = [
    _Choice('Peaceful', Icons.spa, 'peaceful'),
    _Choice('Easy', Icons.sentiment_satisfied, 'easy'),
    _Choice('Normal', Icons.sentiment_neutral, 'normal'),
    _Choice('Hard', Icons.local_fire_department, 'hard'),
  ];

  static const Map<String, int> _timeTicks = {
    'sunrise': 0,
    'day': 1000,
    'noon': 6000,
    'sunset': 12000,
    'night': 13000,
    'midnight': 18000,
  };

  ConnectionController get _connection =>
      Provider.of<ConnectionController>(context, listen: false);
  Model get _model => Provider.of<Model>(context, listen: false);

  Future<void> _send(String command) async {
    if (!CommandUtils.isAccepted(command)) {
      ToastUtils.showToastError(CommandUtils.rejectionMessage);
      return;
    }
    await _connection.executeMinecraftCommand(
      _model,
      command,
      source: 'control',
    );
    if (!mounted) return;
    setState(() => _lastCommand = command);
  }

  /// Queries every game rule. Spaced out because the WebSocket server rate
  /// limits to five messages a second and would start rejecting them.
  Future<void> _loadGamerules() async {
    setState(() => _loadingRules = true);
    final rules = _model.minecraftEdition == MinecraftEdition.java
        ? JavaIds.gamerules
        : BedrockIds.gamerules;
    _model.beginGameruleRefresh();
    try {
      for (final rule in rules) {
        if (!mounted) return;
        await _connection.sendQuietly('gamerule $rule');
        // Four requests per second stays below the bridge's shared limit while
        // finishing sooner than the former three-per-second loop.
        await Future.delayed(const Duration(milliseconds: 250));
      }
      // Bedrock's send-command helper returns before its console reply. Give
      // the final rule a moment to arrive before publishing the batch.
      await Future.delayed(const Duration(milliseconds: 400));
    } finally {
      _model.completeGameruleRefresh();
      if (mounted) setState(() => _loadingRules = false);
    }
  }

  Future<void> _setTime(String value) async {
    final ticks = _timeTicks[value];
    if (ticks != null) _model.recordDaytime(ticks);
    await _send('time set $value');
    unawaited(_refreshTimeAfterCommand());
  }

  Future<void> _refreshTimeAfterCommand() async {
    await Future.delayed(const Duration(milliseconds: 500));
    await _connection.sendQuietly('time query daytime');
  }

  Future<void> _promptAndSend(_PromptedAction action) async {
    final value = await DialogUtils.promptForInput(
      context,
      action.placeholder,
      suggestions: action.placeholder == 'player'
          ? _model.onlinePlayers
          : const [],
    );
    if (value == null || !mounted) return;
    await _send(action.build(value.trim()));
  }

  Future<void> _restartServer() async {
    final confirmed = await DialogUtils.confirmAction(
      context,
      title: 'Restart Server',
      message:
          'Everyone currently playing will be disconnected while the server restarts. Continue?',
      confirmLabel: 'Restart',
    );
    if (!confirmed || !mounted) return;
    await _connection.restartServer(_model);
  }

  Future<void> _startServer() => _connection.startServer(_model);

  Future<void> _stopServer() async {
    final confirmed = await DialogUtils.confirmAction(
      context,
      title: 'Stop Server',
      message:
          'This stops the Minecraft container. Players will be disconnected, '
          'but the Admincraft bridge stays available so you can start it again. Continue?',
      confirmLabel: 'Stop',
    );
    if (!confirmed || !mounted) return;
    await _connection.stopServer(_model);
  }

  // ---------------------------------------------------------------------------
  // Building blocks
  // ---------------------------------------------------------------------------

  Widget _card({
    required String title,
    Widget? trailing,
    required Widget child,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }

  /// A row of choices where the active one is filled in, so the current value
  /// is visible rather than only settable.
  Widget _choiceRow(
    List<_Choice> choices,
    String? selected,
    Future<void> Function(String) onPick,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: choices.map((choice) {
        final isSelected = selected == choice.value;
        final scheme = Theme.of(context).colorScheme;
        return ChoiceChip(
          showCheckmark: false,
          avatar: Icon(
            choice.icon,
            size: 18,
            color: isSelected ? scheme.onSecondaryContainer : scheme.primary,
          ),
          label: Text(choice.label),
          selected: isSelected,
          selectedColor: scheme.secondaryContainer,
          side: BorderSide(
            color: isSelected ? scheme.primary : scheme.outlineVariant,
            width: isSelected ? 1.5 : 1,
          ),
          onSelected: (_) => onPick(choice.value),
        );
      }).toList(),
    );
  }

  Widget _timeCard(WorldState world) {
    return _card(
      title: 'Time',
      trailing: IconButton(
        icon: const Icon(Icons.refresh),
        tooltip: 'Refresh from server',
        onPressed: () => _connection.sendQuietly('time query daytime'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                world.timeIcon,
                size: 44,
                color: world.daytime == null
                    ? Theme.of(context).disabledColor
                    : (world.isDay ? Colors.amber : Colors.indigo.shade200),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    world.timeLabel,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    world.daytime == null
                        ? 'Not queried yet'
                        : '${world.clock}  ·  tick ${world.daytime}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _choiceRow(
            _model.minecraftEdition == MinecraftEdition.java
                ? _javaTimes
                : _bedrockTimes,
            null,
            _setTime,
          ),
        ],
      ),
    );
  }

  Widget _playersCard(Model model) {
    final world = model.world;
    final names = model.onlinePlayers.toList()..sort();

    return _card(
      title: 'Players',
      trailing: IconButton(
        icon: const Icon(Icons.refresh),
        tooltip: 'Refresh player list',
        onPressed: () => _connection.sendQuietly('list'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            world.playersOnline == null
                ? 'Not queried yet'
                : '${world.playersOnline} of ${world.playerLimit} online',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (names.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: names
                  .map(
                    (name) => Chip(
                      avatar: const Icon(Icons.person, size: 16),
                      label: Text(name),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _promptedActions
                .map(
                  (action) => ActionChip(
                    avatar: Icon(action.icon, size: 18),
                    label: Text(action.label),
                    onPressed: () => _promptAndSend(action),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _gamerulesCard(WorldState world) {
    final known = world.gamerules;
    final booleanRules = known.entries
        .where((entry) => entry.value == 'true' || entry.value == 'false')
        .toList();

    return Card(
      key: const ValueKey('gamerules-card'),
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: false,
        onExpansionChanged: (expanded) =>
            setState(() => _gamerulesExpanded = expanded),
        tilePadding: const EdgeInsets.symmetric(horizontal: 14),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        title: Row(
          children: [
            Expanded(
              child: Text(
                'Game rules',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (_loadingRules)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              IconButton(
                icon: const Icon(Icons.download),
                tooltip: 'Load current values',
                onPressed: _loadGamerules,
              ),
          ],
        ),
        subtitle: !_gamerulesExpanded
            ? Text(
                booleanRules.isEmpty
                    ? 'Collapsed · values not loaded'
                    : 'Collapsed · ${booleanRules.length} values loaded',
                style: Theme.of(context).textTheme.bodySmall,
              )
            : null,
        children: [
          if (booleanRules.isEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _loadingRules
                    ? 'Reading rules from the server...'
                    : 'Load the current values to switch rules on and off.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            )
          else
            ...booleanRules.map((entry) {
              final info = BedrockGamerules.forName(entry.key);
              return SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  info.label,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (info.description.isNotEmpty)
                      Text(
                        info.description,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    // The raw name still matters: it is what you type into a
                    // command, and what the server reports back.
                    Text(
                      entry.key,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontFamily: 'Monocraft',
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ],
                ),
                isThreeLine: info.description.isNotEmpty,
                value: entry.value == 'true',
                onChanged: (next) => _send('gamerule ${entry.key} $next'),
              );
            }),
        ],
      ),
    );
  }

  Widget _responsePanel(Model model) {
    final lines = ConsoleOutputFormatter.visibleLines(
      model.output,
      hideCommonNoise: model.hideCommonConsoleNoise,
      containing: model.consoleFilterPattern,
    );
    final tail = lines.length <= 8 ? lines : lines.sublist(lines.length - 8);

    final latest = tail.isEmpty
        ? 'Waiting for output...'
        : ConsoleOutputFormatter.formatLine(
            tail.last,
            model.consoleTimestampMode,
          );
    final scheme = Theme.of(context).colorScheme;
    final consoleStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontFamily: model.terminalFont,
      fontFamilyFallback: const ['Miracode', 'monospace'],
      fontSize: model.terminalFontSize,
      height: 1.25,
    );

    return DecoratedBox(
      key: const ValueKey('control-response-panel'),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _responseExpanded = !_responseExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.terminal, size: 19),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Server response',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        if (!_responseExpanded)
                          Text(
                            latest,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: consoleStyle,
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    _responseExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_up,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            child: !_responseExpanded
                ? const SizedBox.shrink()
                : ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 180),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_lastCommand != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                'Last sent: $_lastCommand',
                                style: consoleStyle?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: scheme.primary,
                                ),
                              ),
                            ),
                          if (tail.isEmpty)
                            Text(latest, style: consoleStyle)
                          else
                            ...tail.map(
                              (line) => Text(
                                ConsoleOutputFormatter.formatLine(
                                  line,
                                  model.consoleTimestampMode,
                                ),
                                style: consoleStyle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isEnabled) {
      return const Center(child: Text('Connect to enable the Control Panel'));
    }

    // Watched, not read: the cards follow the server log as it arrives.
    final model = Provider.of<Model>(context);
    if (!model.connectionSecurity.isDirectRcon &&
        !model.supportsBridgeCapability('commands')) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'This bridge credential is read-only. Use Overview diagnostics or the admincraft terminal commands to inspect the server.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final world = model.world;
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

    // The response is a full-width bottom surface, visually part of the page
    // rather than a floating card over the scrolling controls.
    return Column(
      children: [
        Expanded(child: _buildCards(model, world)),
        if (!keyboardVisible) _responsePanel(model),
      ],
    );
  }

  Widget _buildCards(Model model, WorldState world) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _timeCard(world),
          _card(
            title: 'Weather',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _choiceRow(_weathers, world.lastWeather, (value) async {
                  _model.recordWeather(value);
                  await _send('weather $value');
                }),
                if (world.lastWeather == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'The server cannot report the current weather, so this shows what was last set from here.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
          _card(
            title: 'Difficulty',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _choiceRow(_difficulties, world.lastDifficulty, (value) async {
                  _model.recordDifficulty(value);
                  await _send('difficulty $value');
                }),
                if (world.lastDifficulty == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Updated when the server reports a difficulty or you change it here.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
          _playersCard(model),
          _gamerulesCard(world),
          if (model.connectionSecurity.supportsServerManagement &&
              (model.supportsBridgeCapability('start') ||
                  model.supportsBridgeCapability('restart') ||
                  model.supportsBridgeCapability('stop')))
            _card(
              title: 'Server',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (model.supportsBridgeCapability('start'))
                    FilledButton.tonalIcon(
                      onPressed: _startServer,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Start Server'),
                    ),
                  if (model.supportsBridgeCapability('restart'))
                    OutlinedButton.icon(
                      onPressed: _restartServer,
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('Restart Server'),
                    ),
                  if (model.supportsBridgeCapability('stop'))
                    OutlinedButton.icon(
                      onPressed: _stopServer,
                      icon: const Icon(Icons.stop_rounded),
                      label: const Text('Stop Server'),
                    ),
                ],
              ),
            )
          else
            _card(
              title: 'Server',
              child: Text(
                model.connectionSecurity.isDirectRcon
                    ? 'Starting, stopping and restarting need the Admincraft bridge. A direct RCON connection cannot control the container.'
                    : 'This bridge credential does not grant container lifecycle control.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}

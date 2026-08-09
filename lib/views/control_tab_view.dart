import 'package:admincraft/controllers/connection_controller.dart';
import 'package:admincraft/models/model.dart';
import 'package:admincraft/utils/command_utils.dart';
import 'package:admincraft/utils/dialog_utils.dart';
import 'package:admincraft/utils/toast_utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// A command sent with a single tap.
class _QuickAction {
  final String label;
  final IconData icon;
  final String command;

  const _QuickAction(this.label, this.icon, this.command);
}

/// A command that needs one value from the user before it can be sent.
class _PromptedAction {
  final String label;
  final IconData icon;
  final String placeholder;
  final String Function(String value) build;

  const _PromptedAction(this.label, this.icon, this.placeholder, this.build);
}

class ControlTab extends StatelessWidget {
  final bool isEnabled;
  const ControlTab({super.key, required this.isEnabled});

  static const List<_QuickAction> _playerActions = [
    _QuickAction('Who is online', Icons.people, 'list'),
    _QuickAction('Show whitelist', Icons.list_alt, 'whitelist list'),
    _QuickAction('Reload whitelist', Icons.refresh, 'whitelist reload'),
  ];

  static final List<_PromptedAction> _promptedActions = [
    _PromptedAction('Whitelist player', Icons.person_add, 'player', (player) => 'whitelist add $player'),
    _PromptedAction('Unwhitelist player', Icons.person_remove, 'player', (player) => 'whitelist remove $player'),
    _PromptedAction('Kick player', Icons.logout, 'player', (player) => 'kick $player'),
    _PromptedAction('Announce', Icons.campaign, 'message', (message) => 'say $message'),
  ];

  static const List<_QuickAction> _timeActions = [
    _QuickAction('Day', Icons.wb_sunny, 'time set day'),
    _QuickAction('Noon', Icons.light_mode, 'time set noon'),
    _QuickAction('Night', Icons.nightlight_round, 'time set night'),
    _QuickAction('Midnight', Icons.bedtime, 'time set midnight'),
  ];

  static const List<_QuickAction> _weatherActions = [
    _QuickAction('Clear', Icons.wb_cloudy_outlined, 'weather clear'),
    _QuickAction('Rain', Icons.water_drop, 'weather rain'),
    _QuickAction('Thunder', Icons.thunderstorm, 'weather thunder'),
  ];

  static const List<_QuickAction> _difficultyActions = [
    _QuickAction('Peaceful', Icons.spa, 'difficulty peaceful'),
    _QuickAction('Easy', Icons.sentiment_satisfied, 'difficulty easy'),
    _QuickAction('Normal', Icons.sentiment_neutral, 'difficulty normal'),
    _QuickAction('Hard', Icons.local_fire_department, 'difficulty hard'),
  ];

  Future<void> _send(BuildContext context, String command) async {
    if (!CommandUtils.isAccepted(command)) {
      ToastUtils.showToastError(CommandUtils.rejectionMessage);
      return;
    }

    final model = Provider.of<Model>(context, listen: false);
    final connection = Provider.of<ConnectionController>(context, listen: false);
    await connection.executeMinecraftCommand(model, command);
  }

  Future<void> _promptAndSend(BuildContext context, _PromptedAction action) async {
    final value = await DialogUtils.promptForInput(context, action.placeholder);
    if (value == null || !context.mounted) return;
    await _send(context, action.build(value.trim()));
  }

  Future<void> _restartServer(BuildContext context) async {
    final confirmed = await DialogUtils.confirmAction(
      context,
      title: 'Restart Server',
      message: 'Everyone currently playing will be disconnected while the server restarts. Continue?',
      confirmLabel: 'Restart',
    );
    if (!confirmed || !context.mounted) return;

    final model = Provider.of<Model>(context, listen: false);
    final connection = Provider.of<ConnectionController>(context, listen: false);
    await connection.restartServer(model);
  }

  Widget _section(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: children),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isEnabled) {
      return const Center(
        child: Text('Connect to enable the Control Panel'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _section(context, 'Players', [
            ..._playerActions.map((action) => ActionChip(
                  avatar: Icon(action.icon, size: 18),
                  label: Text(action.label),
                  onPressed: () => _send(context, action.command),
                )),
            ..._promptedActions.map((action) => ActionChip(
                  avatar: Icon(action.icon, size: 18),
                  label: Text(action.label),
                  onPressed: () => _promptAndSend(context, action),
                )),
          ]),
          _section(
            context,
            'Time',
            _timeActions
                .map((action) => ActionChip(
                      avatar: Icon(action.icon, size: 18),
                      label: Text(action.label),
                      onPressed: () => _send(context, action.command),
                    ))
                .toList(),
          ),
          _section(
            context,
            'Weather',
            _weatherActions
                .map((action) => ActionChip(
                      avatar: Icon(action.icon, size: 18),
                      label: Text(action.label),
                      onPressed: () => _send(context, action.command),
                    ))
                .toList(),
          ),
          _section(
            context,
            'Difficulty',
            _difficultyActions
                .map((action) => ActionChip(
                      avatar: Icon(action.icon, size: 18),
                      label: Text(action.label),
                      onPressed: () => _send(context, action.command),
                    ))
                .toList(),
          ),
          _section(context, 'Server', [
            ElevatedButton.icon(
              onPressed: () => _restartServer(context),
              icon: const Icon(Icons.restart_alt),
              label: const Text('Restart Server'),
            ),
          ]),
        ],
      ),
    );
  }
}

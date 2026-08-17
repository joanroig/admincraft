import 'package:admincraft/controllers/connection_controller.dart';
import 'package:admincraft/models/connection_security.dart';
import 'package:admincraft/models/model.dart';
import 'package:admincraft/utils/command_completion.dart';
import 'package:admincraft/utils/dialog_utils.dart';
import 'package:admincraft/utils/toast_utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TerminalController {
  final BuildContext context;

  TerminalController(this.context);

  Future<bool> executeCommand(
    String command,
    TextEditingController commandController,
  ) async {
    final model = Provider.of<Model>(context, listen: false);
    final connectionController = Provider.of<ConnectionController>(
      context,
      listen: false,
    );

    command = command.trim();
    if (command.isEmpty) return false;

    final missing = CommandCompletion.missingRequiredArgument(
      command,
      edition: model.minecraftEdition,
      includeMinecraftCommands:
          model.connectionSecurity.isDirectRcon ||
          model.supportsBridgeCapability('commands'),
      includeBridgeManagement:
          model.connectionSecurity.supportsServerManagement,
      bridgeCapabilities: model.advertisedBridgeCommandCapabilities,
    );
    if (missing != null) {
      ToastUtils.showToastError('Complete ${missing.hint} before sending.');
      return false;
    }

    await model.addCommandToHistory(command);
    await connectionController.executeMinecraftCommand(model, command);
    commandController.clear();
    return true;
  }

  Future<void> handleCommandInput(
    String command,
    TextEditingController commandController,
  ) async {
    final placeholders = _extractPlaceholders(command);

    if (placeholders.isEmpty) {
      commandController.text = command;
      await executeCommand(command, commandController);
      return;
    }

    final inputs = <String>[];

    for (final placeholder in placeholders) {
      final input = await DialogUtils.promptForInput(context, placeholder);
      if (input == null) return;
      inputs.add(input);
    }

    var filledCommand = command;
    for (int i = 0; i < placeholders.length; i++) {
      filledCommand = filledCommand.replaceFirst(
        '<${placeholders[i]}>',
        inputs[i],
      );
    }

    // commandController.text = filledCommand;
    await executeCommand(filledCommand, commandController);
  }

  List<String> _extractPlaceholders(String command) {
    final regex = RegExp(r'<(\w+)>');
    return regex.allMatches(command).map((match) => match.group(1)!).toList();
  }
}

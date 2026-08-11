import 'package:admincraft/models/model.dart';
import 'package:admincraft/data/bedrock_commands.dart';
import 'package:admincraft/models/bedrock_command.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DialogUtils {
  static IconData _categoryIcon(String category) {
    switch (category) {
      case 'Players':
        return Icons.group;
      case 'Items':
        return Icons.inventory_2;
      case 'World':
        return Icons.public;
      case 'Server':
        return Icons.dns;
      default:
        return Icons.terminal;
    }
  }

  /// The command name at full strength with its arguments dimmed, so the name
  /// reads first while the shape stays visible.
  static Widget _syntax(BedrockCommand command, ThemeData theme) {
    final base = theme.textTheme.bodyMedium;
    return RichText(
      text: TextSpan(children: [
        TextSpan(text: command.name, style: base?.copyWith(fontWeight: FontWeight.bold)),
        for (final arg in command.args)
          TextSpan(
            text: ' ${arg.hint}',
            style: base?.copyWith(color: base.color?.withValues(alpha: 0.55)),
          ),
      ]),
    );
  }

  /// Browsable command reference, grouped by category and searchable by name
  /// or description.
  static void showDefaultCommandsPopup(BuildContext context, Function(String) onCommandSelected) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        var query = '';

        return StatefulBuilder(
          builder: (context, setState) {
            final matches = BedrockCommands.all.where((command) {
              if (query.isEmpty) return true;
              final needle = query.toLowerCase();
              return command.name.contains(needle) ||
                  command.description.toLowerCase().contains(needle) ||
                  command.category.toLowerCase().contains(needle);
            }).toList();

            // Grouped so the list reads as sections rather than one long run.
            final categories = matches.map((command) => command.category).toSet().toList();

            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Commands'),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Search commands',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (value) => setState(() => query = value),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: matches.isEmpty
                          ? Center(
                              child: Text('No command matches "$query"',
                                  style: theme.textTheme.bodySmall),
                            )
                          : ListView(
                              shrinkWrap: true,
                              children: [
                                for (final category in categories) ...[
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(4, 10, 4, 6),
                                    child: Row(
                                      children: [
                                        Icon(_categoryIcon(category),
                                            size: 16, color: theme.colorScheme.primary),
                                        const SizedBox(width: 6),
                                        Text(
                                          category.toUpperCase(),
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(color: theme.colorScheme.primary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  for (final command
                                      in matches.where((c) => c.category == category))
                                    InkWell(
                                      onTap: () {
                                        Navigator.of(context).pop();
                                        // Only the name: the arguments are
                                        // what completion is for.
                                        onCommandSelected(command.name);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 8),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _syntax(command, theme),
                                            const SizedBox(height: 2),
                                            Text(command.description,
                                                style: theme.textTheme.bodySmall),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Asks for the passphrase protecting a config transfer.
  ///
  /// When [confirm] is set the passphrase is entered twice: a typo on export
  /// would only surface later, on the device that can no longer read the file.
  static Future<String?> promptForPassphrase(
    BuildContext context, {
    required String title,
    required String message,
    required bool confirm,
  }) {
    var value = '';
    var repeated = '';
    var visible = false;

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final matches = !confirm || value == repeated;
            final canSubmit = value.isNotEmpty && matches;

            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(message, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 12),
                  TextField(
                    autofocus: true,
                    obscureText: !visible,
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: 'Passphrase',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                            visible ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => visible = !visible),
                      ),
                    ),
                    onChanged: (text) => setState(() => value = text),
                    onSubmitted: (_) {
                      if (canSubmit) Navigator.of(context).pop(value);
                    },
                  ),
                  if (confirm) ...[
                    const SizedBox(height: 10),
                    TextField(
                      obscureText: !visible,
                      enableSuggestions: false,
                      autocorrect: false,
                      decoration: InputDecoration(
                        labelText: 'Repeat passphrase',
                        border: const OutlineInputBorder(),
                        errorText: value.isNotEmpty && !matches
                            ? 'Does not match'
                            : null,
                      ),
                      onChanged: (text) => setState(() => repeated = text),
                      onSubmitted: (_) {
                        if (canSubmit) Navigator.of(context).pop(value);
                      },
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed:
                      canSubmit ? () => Navigator.of(context).pop(value) : null,
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Asks the user to confirm an action that is disruptive or hard to undo,
  /// such as restarting the server while people are playing.
  static Future<bool> confirmAction(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  static Future<String?> promptForInput(BuildContext context, String placeholder) {
    final TextEditingController inputController = TextEditingController();
    final FocusNode focusNode = FocusNode();

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Enter $placeholder'),
              content: TextField(
                controller: inputController,
                focusNode: focusNode,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Enter $placeholder',
                ),
                onChanged: (value) {
                  // Rebuild the UI to update the state of the OK button
                  setState(() {});
                },
                onSubmitted: (value) {
                  if (inputController.text.trim().isNotEmpty) {
                    Navigator.of(context).pop(inputController.text.trim());
                  }
                },
              ),
              actions: [
                TextButton(
                  onPressed: inputController.text.trim().isNotEmpty
                      ? () {
                          Navigator.of(context).pop(inputController.text.trim());
                        }
                      : null,
                  child: const Text('OK'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(null);
                  },
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static void showClearHistoryDialog(BuildContext context, Function resetHistoryIndex) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Command History'),
          content: const Text('Are you sure you want to clear all command history?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Provider.of<Model>(context, listen: false).clearCommandHistory();
                resetHistoryIndex(); // Call resetHistoryIndex after clearing history
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }

  static void showHistoryPopup(BuildContext context, TextEditingController commandController, Function resetHistoryIndex, Function setCursorToEnd) {
    final model = Provider.of<Model>(context, listen: false);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Command History'),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: model.commandHistory.length,
                        itemBuilder: (context, index) {
                          final command = model.commandHistory[index];
                          return ListTile(
                            title: Text(command),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                setState(() {
                                  model.removeCommandFromHistory(index);
                                  commandController.clear();
                                  resetHistoryIndex();
                                });
                              },
                            ),
                            onTap: () {
                              resetHistoryIndex();
                              commandController.text = command;
                              setCursorToEnd();
                              Navigator.of(context).pop();
                            },
                          );
                        },
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        showClearHistoryDialog(context, resetHistoryIndex); // Pass resetHistoryIndex as an argument
                      },
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

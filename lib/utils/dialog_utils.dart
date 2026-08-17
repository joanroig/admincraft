import 'package:admincraft/models/model.dart';
import 'package:admincraft/data/minecraft_commands.dart';
import 'package:admincraft/models/bedrock_command.dart';
import 'package:admincraft/models/connection_security.dart';
import 'package:admincraft/utils/command_utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DialogUtils {
  /// Keeps the catalogue's existing section order while making each section
  /// predictable to scan. Sorting the complete list would mix the categories.
  static List<BedrockCommand> sortCommandsWithinCategories(
    Iterable<BedrockCommand> commands,
  ) {
    final source = commands.toList();
    final categories = source
        .map((command) => command.category)
        .toSet()
        .toList();
    return [
      for (final category in categories)
        ...([...source.where((command) => command.category == category)]..sort(
          (left, right) =>
              left.name.toLowerCase().compareTo(right.name.toLowerCase()),
        )),
    ];
  }

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
      text: TextSpan(
        children: [
          TextSpan(
            text: command.name,
            style: base?.copyWith(fontWeight: FontWeight.bold),
          ),
          for (final arg in command.args)
            TextSpan(
              text: ' ${arg.hint}',
              style: base?.copyWith(color: base.color?.withValues(alpha: 0.55)),
            ),
        ],
      ),
    );
  }

  static List<Widget> _commandRows(
    List<BedrockCommand> commands,
    ThemeData theme,
    ValueChanged<String> onCommandSelected,
  ) {
    return [
      for (var index = 0; index < commands.length; index++) ...[
        InkWell(
          onTap: () => onCommandSelected(commands[index].name),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _syntax(commands[index], theme),
                const SizedBox(height: 2),
                Text(
                  commands[index].description,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        if (index < commands.length - 1)
          Divider(
            height: 1,
            indent: 8,
            endIndent: 8,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
          ),
      ],
    ];
  }

  /// Browsable command reference, grouped by category and searchable by name
  /// or description.
  static void showDefaultCommandsPopup(
    BuildContext context,
    Function(String) onCommandSelected,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        final model = Provider.of<Model>(context, listen: false);
        final commands = sortCommandsWithinCategories(
          MinecraftCommands.all(
            model.minecraftEdition,
            includeMinecraftCommands:
                model.connectionSecurity.isDirectRcon ||
                model.supportsBridgeCapability('commands'),
            includeBridgeManagement:
                model.connectionSecurity.supportsServerManagement,
            bridgeCapabilities: model.advertisedBridgeCommandCapabilities,
          ),
        );
        var query = '';

        return StatefulBuilder(
          builder: (context, setState) {
            final matches = commands.where((command) {
              if (query.isEmpty) return true;
              final needle = query.toLowerCase();
              return command.name.contains(needle) ||
                  command.description.toLowerCase().contains(needle) ||
                  command.category.toLowerCase().contains(needle);
            }).toList();

            // Grouped so the list reads as sections rather than one long run.
            final categories = matches
                .map((command) => command.category)
                .toSet()
                .toList();

            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Commands (${matches.length})'),
                  IconButton(
                    tooltip: 'Close commands',
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
                              child: Text(
                                'No command matches "$query"',
                                style: theme.textTheme.bodySmall,
                              ),
                            )
                          : Scrollbar(
                              child: ListView(
                                shrinkWrap: true,
                                children: [
                                  for (final category in categories) ...[
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        4,
                                        10,
                                        4,
                                        6,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            _categoryIcon(category),
                                            size: 16,
                                            color: theme.colorScheme.primary,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            category.toUpperCase(),
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  color:
                                                      theme.colorScheme.primary,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ..._commandRows(
                                      matches
                                          .where(
                                            (command) =>
                                                command.category == category,
                                          )
                                          .toList(),
                                      theme,
                                      (command) {
                                        Navigator.of(context).pop();
                                        onCommandSelected(command);
                                      },
                                    ),
                                  ],
                                ],
                              ),
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
                          visible ? Icons.visibility : Icons.visibility_off,
                        ),
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
                  onPressed: canSubmit
                      ? () => Navigator.of(context).pop(value)
                      : null,
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

  static Future<String?> promptForInput(
    BuildContext context,
    String placeholder, {
    Iterable<String> suggestions = const [],
  }) {
    final TextEditingController inputController = TextEditingController();
    final FocusNode focusNode = FocusNode();
    final options = suggestions.toSet().toList()
      ..sort(
        (left, right) => left.toLowerCase().compareTo(right.toLowerCase()),
      );

    final result = showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            final query = inputController.text.trim().toLowerCase();
            final matches = options
                .where(
                  (option) =>
                      query.isEmpty || option.toLowerCase().contains(query),
                )
                .take(5)
                .toList();

            return AlertDialog(
              title: Text('Enter $placeholder'),
              content: SizedBox(
                width: 340,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: inputController,
                      focusNode: focusNode,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Enter $placeholder',
                        prefixIcon: options.isEmpty
                            ? null
                            : const Icon(Icons.person_search_outlined),
                      ),
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) {
                        if (inputController.text.trim().isNotEmpty) {
                          Navigator.of(
                            context,
                          ).pop(inputController.text.trim());
                        }
                      },
                    ),
                    if (matches.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 180),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: matches.length,
                          itemBuilder: (context, index) {
                            final player = matches[index];
                            return ListTile(
                              dense: true,
                              visualDensity: VisualDensity.compact,
                              leading: const Icon(Icons.person_outline),
                              title: Text(player),
                              onTap: () {
                                inputController.value = TextEditingValue(
                                  text: player,
                                  selection: TextSelection.collapsed(
                                    offset: player.length,
                                  ),
                                );
                                focusNode.requestFocus();
                                setState(() {});
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: inputController.text.trim().isNotEmpty
                      ? () {
                          Navigator.of(
                            context,
                          ).pop(inputController.text.trim());
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
    return result.whenComplete(() {
      inputController.dispose();
      focusNode.dispose();
    });
  }

  static void showClearHistoryDialog(
    BuildContext context,
    Function resetHistoryIndex,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Command History'),
          content: const Text(
            'Are you sure you want to clear all command history?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Provider.of<Model>(
                  context,
                  listen: false,
                ).clearCommandHistory();
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

  static void showHistoryPopup(
    BuildContext context,
    TextEditingController commandController,
    Function resetHistoryIndex,
    Function setCursorToEnd,
  ) {
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
                    tooltip: 'Close history',
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
                      child: ListView.separated(
                        itemCount: model.commandHistory.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: Theme.of(
                            context,
                          ).colorScheme.outlineVariant.withValues(alpha: 0.55),
                        ),
                        itemBuilder: (context, index) {
                          final command = model.commandHistory[index];
                          final favorite = model.favoriteCommands.contains(
                            command,
                          );
                          return ListTile(
                            title: Text(command),
                            leading: IconButton(
                              tooltip: favorite
                                  ? 'Remove from favorites'
                                  : 'Add to favorites',
                              icon: Icon(
                                favorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                              ),
                              onPressed: () async {
                                if (favorite) {
                                  await model.removeFavoriteCommand(command);
                                } else {
                                  await model.addFavoriteCommand(command);
                                }
                                setState(() {});
                              },
                            ),
                            trailing: IconButton(
                              tooltip: 'Delete from history',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                await model.removeCommandFromHistory(index);
                                commandController.clear();
                                resetHistoryIndex();
                                setState(() {});
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
                        showClearHistoryDialog(
                          context,
                          resetHistoryIndex,
                        ); // Pass resetHistoryIndex as an argument
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

  static void showFavoritesPopup(
    BuildContext context,
    TextEditingController commandController,
    Function resetHistoryIndex,
    Function setCursorToEnd,
  ) {
    showDialog(
      context: context,
      builder: (context) => _FavoritesDialog(
        commandController: commandController,
        resetHistoryIndex: resetHistoryIndex,
        setCursorToEnd: setCursorToEnd,
      ),
    );
  }
}

class _FavoritesDialog extends StatefulWidget {
  final TextEditingController commandController;
  final Function resetHistoryIndex;
  final Function setCursorToEnd;

  const _FavoritesDialog({
    required this.commandController,
    required this.resetHistoryIndex,
    required this.setCursorToEnd,
  });

  @override
  State<_FavoritesDialog> createState() => _FavoritesDialogState();
}

class _FavoritesDialogState extends State<_FavoritesDialog> {
  final TextEditingController _editor = TextEditingController();
  String? _editingOriginal;
  bool _showAddEditor = false;
  String? _error;

  @override
  void dispose() {
    _editor.dispose();
    super.dispose();
  }

  void _startAdding() {
    setState(() {
      _showAddEditor = true;
      _editingOriginal = null;
      _editor.clear();
      _error = null;
    });
  }

  void _startEditing(String command) {
    setState(() {
      _showAddEditor = false;
      _editingOriginal = command;
      _editor.text = command;
      _editor.selection = TextSelection.collapsed(offset: command.length);
      _error = null;
    });
  }

  void _cancelEditing() {
    setState(() {
      _showAddEditor = false;
      _editingOriginal = null;
      _editor.clear();
      _error = null;
    });
  }

  Future<void> _save(Model model) async {
    final command = _editor.text.trim();
    if (command.isEmpty) {
      setState(() => _error = 'Enter a command.');
      return;
    }
    if (!CommandUtils.isAccepted(command)) {
      setState(() => _error = CommandUtils.rejectionMessage);
      return;
    }
    if (model.favoriteCommands.any(
      (favorite) => favorite == command && favorite != _editingOriginal,
    )) {
      setState(() => _error = 'This command is already a favorite.');
      return;
    }

    final previous = _editingOriginal;
    if (previous == null) {
      await model.addFavoriteCommand(command);
    } else {
      await model.updateFavoriteCommand(previous, command);
    }
    if (mounted) _cancelEditing();
  }

  void _select(String command) {
    widget.resetHistoryIndex();
    widget.commandController.text = command;
    widget.setCursorToEnd();
    Navigator.of(context).pop();
  }

  Widget _editorField(Model model, {required bool inline}) {
    return TextField(
      key: const ValueKey('favorite-command-editor'),
      controller: _editor,
      autofocus: true,
      decoration: InputDecoration(
        labelText: inline ? 'Edit favorite command' : 'New favorite command',
        errorText: _error,
        border: const OutlineInputBorder(),
        isDense: inline,
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Cancel editing',
              onPressed: _cancelEditing,
              icon: const Icon(Icons.close),
            ),
            IconButton(
              tooltip: 'Save favorite command',
              onPressed: () => _save(model),
              icon: const Icon(Icons.check),
            ),
          ],
        ),
      ),
      onSubmitted: (_) => _save(model),
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<Model>();
    final favorites = model.favoriteCommands;
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.favorite),
          const SizedBox(width: 10),
          const Expanded(child: Text('Favorite commands')),
          IconButton(
            tooltip: 'Add favorite command',
            onPressed: _startAdding,
            icon: const Icon(Icons.add),
          ),
          IconButton(
            tooltip: 'Close favorites',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.sizeOf(context).height * 0.58,
        child: Column(
          children: [
            if (_showAddEditor) ...[
              _editorField(model, inline: false),
              const SizedBox(height: 12),
            ],
            Expanded(
              child: favorites.isEmpty
                  ? Center(
                      child: Text(
                        'No favorites yet. Add one here or use a heart in command history.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    )
                  : ListView.separated(
                      itemCount: favorites.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: scheme.outlineVariant.withValues(alpha: 0.55),
                      ),
                      itemBuilder: (context, index) {
                        final command = favorites[index];
                        if (_editingOriginal == command) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: _editorField(model, inline: true),
                          );
                        }
                        return ListTile(
                          leading: const Icon(Icons.favorite),
                          title: Text(command),
                          onTap: () => _select(command),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Edit favorite',
                                onPressed: () => _startEditing(command),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              IconButton(
                                tooltip: 'Delete favorite',
                                onPressed: () =>
                                    model.removeFavoriteCommand(command),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

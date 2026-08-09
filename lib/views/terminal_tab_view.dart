import 'package:admincraft/controllers/terminal_controller.dart';
import 'package:admincraft/data/bedrock_commands.dart';
import 'package:admincraft/models/bedrock_command.dart';
import 'package:admincraft/models/model.dart';
import 'package:admincraft/utils/command_completion.dart';
import 'package:admincraft/utils/command_utils.dart';
import 'package:admincraft/utils/completion_icons.dart';
import 'package:admincraft/utils/dialog_utils.dart';
import 'package:admincraft/views/widgets/item_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// Accepting the highlighted completion with the Tab key.
class _AcceptCompletionIntent extends Intent {
  const _AcceptCompletionIntent();
}

class TerminalTab extends StatefulWidget {
  final bool isEnabled;
  const TerminalTab({super.key, required this.isEnabled});

  @override
  State<TerminalTab> createState() => _TerminalTabState();
}

class _TerminalTabState extends State<TerminalTab> {
  final ScrollController _scrollController = ScrollController();
  late TerminalController _terminalController;
  final TextEditingController _commandController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  int _historyIndex = 0;
  late Model _model;
  List<Completion> _suggestions = const [];

  void _refreshSuggestions() {
    setState(() {
      _suggestions = CommandCompletion.suggest(
        _commandController.text,
        onlinePlayers: _model.onlinePlayers,
        usage: _model.commandUsage,
      );
    });
  }

  void _applySuggestion(String value) {
    _setText(CommandCompletion.apply(_commandController.text, value));
    _refreshSuggestions();
  }

  /// Replaces the input and leaves the caret at the end.
  ///
  /// The caret is set twice on purpose. A field that regains focus selects its
  /// whole contents, so setting the selection only before the focus change
  /// leaves everything highlighted and the next keystroke wipes the line. The
  /// post-frame pass reasserts it once focus has settled.
  void _setText(String value) {
    final caret = TextSelection.collapsed(offset: value.length);
    _commandController.value = TextEditingValue(text: value, selection: caret);
    _focusNode.requestFocus();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _commandController.selection = caret;
    });
  }

  @override
  void initState() {
    super.initState();
    _model = Provider.of<Model>(context, listen: false);

    // Initialize controllers with context
    _terminalController = TerminalController(context);

    // Initialize the history index
    _resetHistoryIndex();

    // Assigned directly rather than through _refreshSuggestions: setState is
    // not available until the first build.
    _suggestions = CommandCompletion.suggest(
      '',
      onlinePlayers: _model.onlinePlayers,
      usage: _model.commandUsage,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isEnabled) {
      return _buildDisabledState();
    }

    // Auto-scroll to bottom when logs are updated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: _model.output.isEmpty
                    ? _buildLoadingAnimation()
                    : ListView(
                        controller: _scrollController,
                        children: _formatOutput(_model.output, _model.userCommands),
                      ),
              ),
              const SizedBox(height: 10),
              _buildCommandControls(),
              _buildSuggestions(),
              _buildSyntaxHint(),
              const SizedBox(height: 10),
              _buildCommandInput(),
            ],
          ),
          _buildScrollToBottomButton(),
        ],
      ),
    );
  }

  Widget _buildDisabledState() {
    _model.clearOutput();
    return const Center(child: Text('Connect to enable the Terminal.'));
  }

  Widget _buildLoadingAnimation() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  List<Widget> _formatOutput(String output, Set<String> userCommands) {
    final widgets = <Widget>[];
    final lines = output.split('\n');

    for (var line in lines) {
      if (line.trim().isNotEmpty) {
        // Check for non-empty lines
        final isUserCommand = userCommands.contains(line);
        widgets.add(
          MouseRegion(
            cursor: isUserCommand ? SystemMouseCursors.click : SystemMouseCursors.basic,
            child: GestureDetector(
              onTap: isUserCommand
                  ? () {
                      _setText(line);
                    }
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 0.0),
                child: Text(
                  line,
                  style: TextStyle(
                    fontWeight: isUserCommand ? FontWeight.bold : FontWeight.normal,
                    color: isUserCommand ? Colors.blue : Theme.of(context).textTheme.bodyMedium?.color,
                    decoration: isUserCommand ? TextDecoration.underline : TextDecoration.none,
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }
    return widgets;
  }

  Widget _buildCommandControls() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.list),
          onPressed: () {
            // Picking a command types it into the input and hands over to the
            // completion strip, rather than interrogating the user with one
            // dialog per placeholder.
            DialogUtils.showDefaultCommandsPopup(
              context,
              (command) async {
                _setText('$command ');
                _refreshSuggestions();
              },
            );
          },
          tooltip: 'Show default commands',
        ),
        IconButton(
          icon: const Icon(Icons.arrow_upward),
          onPressed: _historyIndex > 0 ? _navigateCommandHistoryUp : null,
        ),
        IconButton(
          icon: const Icon(Icons.arrow_downward),
          onPressed: _historyIndex < _model.commandHistory.length ? _navigateCommandHistoryDown : null,
        ),
        IconButton(
          icon: const Icon(Icons.history),
          onPressed: _model.commandHistory.isNotEmpty
              ? () => DialogUtils.showHistoryPopup(
                    context,
                    _commandController,
                    () => _resetHistoryIndex(),
                    () => _setCursorToEnd(),
                  )
              : null,
          tooltip: 'Show command history',
        ),
      ],
    );
  }

  /// Completions for whatever is being typed, as a single scrolling strip.
  ///
  /// Deliberately compact: this sits directly above the input and is on screen
  /// constantly, so it stays one row. The full syntax and descriptions live in
  /// the command list dialog, where there is room for them.
  Widget _buildSuggestions() {
    if (_suggestions.isEmpty) return const SizedBox.shrink();
    // Chips must not take focus: tapping one would pull focus out of the input
    // and the field would select its whole contents on the way back.
    return ExcludeFocus(child: _buildValueChips());
  }

  static IconData _categoryIcon(String? category) {
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

  Widget _buildValueChips() {
    final scheme = Theme.of(context).colorScheme;

    // Tall enough for a chip with a leading icon: a shorter strip clips the
    // avatar out entirely rather than scaling it down.
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final suggestion = _suggestions[index];
          final color = CompletionIcons.colorFor(suggestion.type, scheme);

          // Command names have no argument type; they are recognised by
          // category instead so the strip is still readable at a glance.
          final command = suggestion.type == null ? BedrockCommands.byName[suggestion.value] : null;

          // Items get their real pixel artwork; everything else keeps a
          // symbolic icon, since there is no artwork for a game rule.
          final Widget avatar = suggestion.type == ArgType.item
              ? ItemIcon(suggestion.value, size: 18, fallbackColor: color)
              : Icon(
                  command != null
                      ? _categoryIcon(command.category)
                      : CompletionIcons.forType(suggestion.type, suggestion.value),
                  size: 18,
                  color: color,
                );

          return ActionChip(
            avatar: avatar,
            // The first entry is what Tab accepts, so it is marked as such.
            side: index == 0 ? BorderSide(color: color, width: 1.4) : null,
            label: Text(suggestion.value),
            tooltip: command != null
                ? '${command.syntax}\n${command.description}'
                : (suggestion.detail.isEmpty ? null : suggestion.detail),
            onPressed: () => _applySuggestion(suggestion.value),
          );
        },
      ),
    );
  }

  /// Shows the syntax of the command being typed, with the argument currently
  /// under the cursor emphasised, so the expected shape is visible while
  /// typing rather than only in the command list.
  Widget _buildSyntaxHint() {
    final text = _commandController.text;
    final command = CommandCompletion.commandFor(text);
    final rejected = text.trim().isNotEmpty && !CommandUtils.isAccepted(text.trim());

    if (command == null && !rejected) return const SizedBox.shrink();

    final base = Theme.of(context).textTheme.bodySmall;

    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (command != null) _syntaxLine(command, CommandCompletion.activeArgIndex(text), base),
          if (command != null)
            Text(command.description, style: base?.copyWith(fontStyle: FontStyle.italic)),
          if (rejected)
            Text(
              CommandUtils.rejectionMessage,
              style: base?.copyWith(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    );
  }

  Widget _syntaxLine(BedrockCommand command, int activeIndex, TextStyle? base) {
    final spans = <TextSpan>[
      TextSpan(text: command.name, style: base?.copyWith(fontWeight: FontWeight.bold)),
    ];

    for (var i = 0; i < command.args.length; i++) {
      final isActive = i == activeIndex;
      spans.add(TextSpan(
        text: ' ${command.args[i].hint}',
        style: base?.copyWith(
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          color: isActive ? Theme.of(context).colorScheme.primary : base.color?.withValues(alpha: 0.6),
        ),
      ));
    }

    return RichText(text: TextSpan(children: spans));
  }

  Widget _buildCommandInput() {
    return Row(
      children: [
        Expanded(
          // Tab is the conventional completion key in a console, and Flutter
          // would otherwise consume it to move focus out of the field.
          child: Shortcuts(
            shortcuts: const {SingleActivator(LogicalKeyboardKey.tab): _AcceptCompletionIntent()},
            child: Actions(
              actions: {
                _AcceptCompletionIntent: CallbackAction<_AcceptCompletionIntent>(
                  onInvoke: (_) {
                    if (_suggestions.isNotEmpty) _applySuggestion(_suggestions.first.value);
                    return null;
                  },
                ),
              },
              child: TextField(
            controller: _commandController,
            focusNode: _focusNode,
            decoration: const InputDecoration(
              labelText: 'Enter command',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _refreshSuggestions(),
            onSubmitted: (command) async {
              await _terminalController.executeCommand(command, _commandController);
              _resetHistoryIndex();
              _refreshSuggestions();
              _focusNode.requestFocus();
            },
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        IconButton(
          icon: const Icon(Icons.play_arrow, color: Colors.white),
          onPressed: () async {
            await _terminalController.executeCommand(_commandController.text, _commandController);
            _resetHistoryIndex();
            _focusNode.requestFocus();
          },
          style: IconButton.styleFrom(backgroundColor: Colors.green),
        ),
      ],
    );
  }

  Widget _buildScrollToBottomButton() {
    return Positioned(
      bottom: 120,
      right: 16,
      child: FloatingActionButton(
        onPressed: _scrollToBottom,
        backgroundColor: const Color.fromRGBO(0, 0, 0, 0.5),
        child: const Icon(Icons.arrow_downward),
      ),
    );
  }

  void _navigateCommandHistoryUp() {
    if (_historyIndex > 0) {
      setState(() {
        _historyIndex--;
        if (_historyIndex >= 0 && _historyIndex < _model.commandHistory.length) {
          _setText(_model.commandHistory[_historyIndex]);
        }
      });
    }
  }

  void _navigateCommandHistoryDown() {
    if (_historyIndex < _model.commandHistory.length - 1) {
      setState(() {
        _historyIndex++;
        _setText(_model.commandHistory[_historyIndex]);
      });
    } else {
      setState(() {
        _resetHistoryIndex();
        _setText('');
      });
    }
  }

  void _setCursorToEnd() => _setText(_commandController.text);

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  void _resetHistoryIndex() {
    setState(() {
      _historyIndex = _model.commandHistory.length;
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _scrollController.dispose();
    _commandController.dispose();
    super.dispose();
  }
}

import 'package:admincraft/controllers/terminal_controller.dart';
import 'package:admincraft/data/bedrock_commands.dart';
import 'package:admincraft/models/bedrock_command.dart';
import 'package:admincraft/models/model.dart';
import 'package:admincraft/utils/command_completion.dart';
import 'package:admincraft/utils/command_utils.dart';
import 'package:admincraft/utils/dialog_utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
      );
    });
  }

  void _applySuggestion(String value) {
    _commandController.text = CommandCompletion.apply(_commandController.text, value);
    _setCursorToEnd();
    _refreshSuggestions();
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
    _suggestions = CommandCompletion.suggest('', onlinePlayers: _model.onlinePlayers);
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
                      _commandController.text = line;
                      // Move the cursor to the end of the text
                      _commandController.selection = TextSelection.fromPosition(
                        TextPosition(offset: _commandController.text.length),
                      );
                      _focusNode.requestFocus(); // Ensure the focus is on the text field
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
            DialogUtils.showDefaultCommandsPopup(
              context,
              (command) async {
                await _terminalController.handleCommandInput(command, _commandController);
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

  /// Completions for whatever is being typed.
  ///
  /// Command names get a vertical list showing full syntax and description,
  /// since choosing a command is where that context matters. Argument values
  /// are chips: there are many more of them and the name is the whole story.
  Widget _buildSuggestions() {
    if (_suggestions.isEmpty) return const SizedBox.shrink();

    final completingCommand = !_commandController.text.trimLeft().contains(' ');
    return completingCommand ? _buildCommandList() : _buildValueChips();
  }

  Widget _buildCommandList() {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(maxHeight: 180),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = _suggestions[index];
          final command = BedrockCommands.byName[suggestion.value];

          return InkWell(
            onTap: () => _applySuggestion(suggestion.value),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    command?.syntax ?? suggestion.value,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (suggestion.detail.isNotEmpty)
                    Text(suggestion.detail, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildValueChips() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final suggestion = _suggestions[index];
          return ActionChip(
            label: Text(suggestion.value),
            tooltip: suggestion.detail.isEmpty ? null : suggestion.detail,
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
          _commandController.text = _model.commandHistory[_historyIndex];
          _setCursorToEnd();
        }
      });
    }
  }

  void _navigateCommandHistoryDown() {
    if (_historyIndex < _model.commandHistory.length - 1) {
      setState(() {
        _historyIndex++;
        _commandController.text = _model.commandHistory[_historyIndex];
        _setCursorToEnd();
      });
    } else {
      setState(() {
        _resetHistoryIndex();
        _commandController.clear();
        _setCursorToEnd();
      });
    }
  }

  void _setCursorToEnd() {
    _commandController.selection = TextSelection.fromPosition(
      TextPosition(offset: _commandController.text.length),
    );
    _focusNode.requestFocus(); // Ensure the focus is on the text field
  }

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

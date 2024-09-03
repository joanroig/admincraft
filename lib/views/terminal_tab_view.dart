import 'package:admincraft/controllers/terminal_controller.dart';
import 'package:admincraft/models/model.dart';
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

  @override
  void initState() {
    super.initState();
    _model = Provider.of<Model>(context, listen: false);

    // Initialize controllers with context
    _terminalController = TerminalController(context);

    // Initialize the history index
    _resetHistoryIndex();
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
                padding: EdgeInsets.symmetric(vertical: 0.0),
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
            onSubmitted: (command) async {
              await _terminalController.executeCommand(command, _commandController);
              _resetHistoryIndex();
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

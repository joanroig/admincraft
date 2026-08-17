import 'package:admincraft/controllers/terminal_controller.dart';
import 'package:admincraft/data/minecraft_commands.dart';
import 'package:admincraft/models/bedrock_command.dart';
import 'package:admincraft/models/connection_security.dart';
import 'package:admincraft/models/model.dart';
import 'package:admincraft/services/console_output_formatter.dart';
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

class _TerminalTabState extends State<TerminalTab> with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  late TerminalController _terminalController;
  final TextEditingController _commandController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  int _historyIndex = 0;
  late Model _model;
  List<Completion> _suggestions = const [];
  bool _searchVisible = false;
  bool _showScrollToBottom = false;
  String _lastRenderedOutput = '';

  void _refreshSuggestions() {
    setState(() {
      _suggestions = CommandCompletion.suggest(
        _commandController.text,
        onlinePlayers: _model.onlinePlayers,
        usage: _model.commandUsage,
        edition: _model.minecraftEdition,
        includeMinecraftCommands:
            _model.connectionSecurity.isDirectRcon ||
            _model.supportsBridgeCapability('commands'),
        includeBridgeManagement:
            _model.connectionSecurity.supportsServerManagement,
        bridgeCapabilities: _model.advertisedBridgeCapabilities,
      );
    });
  }

  void _applySuggestion(String value) {
    _setText(CommandCompletion.apply(_commandController.text, value));
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

    // Every route that changes the input goes through here, so refreshing the
    // completions here keeps them in step with the syntax hint, which reads
    // the controller directly on every build.
    _refreshSuggestions();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _model = Provider.of<Model>(context, listen: false);
    _scrollController.addListener(_syncScrollButton);

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
      edition: _model.minecraftEdition,
      includeMinecraftCommands:
          _model.connectionSecurity.isDirectRcon ||
          _model.supportsBridgeCapability('commands'),
      includeBridgeManagement:
          _model.connectionSecurity.supportsServerManagement,
      bridgeCapabilities: _model.advertisedBridgeCapabilities,
    );
  }

  @override
  void didChangeMetrics() {
    if (!_model.terminalAutoScroll) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  Widget build(BuildContext context) {
    // The terminal must react directly to streamed logs and to the explicit
    // history-loading boundary instead of relying on an ancestor to rebuild.
    context.watch<Model>();
    if (!widget.isEnabled) {
      return _buildDisabledState();
    }

    final outputChanged = _lastRenderedOutput != _model.output;
    _lastRenderedOutput = _model.output;
    // Follow new output, but do not yank the console down on unrelated
    // rebuilds after the user has deliberately scrolled up.
    if (_model.terminalAutoScroll && outputChanged && !_showScrollToBottom) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncScrollButton());
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 2, 8, 8),
      child: Stack(
        children: [
          Column(
            // Stretched so the syntax hint sits flush with the input rather
            // than centred on the width of its own text.
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildOutputTools(),
              Expanded(
                child: Container(
                  key: const ValueKey('console-surface'),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLowest
                        .withValues(alpha: 0.94),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outlineVariant.withValues(alpha: 0.7),
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _model.output.isEmpty
                      ? (_model.consoleHistoryLoading
                            ? _buildLoadingAnimation()
                            : _buildEmptyState())
                      : SelectionArea(
                          child: ListView(
                            key: const ValueKey('console-output-list'),
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            children: _formatOutput(
                              _model.output,
                              _model.userCommands,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 10),
              _buildCommandControls(),
              // Hint above, chips directly above the input: the chips are what
              // gets tapped, so they belong closest to where typing happens.
              _buildSyntaxHint(),
              _buildSuggestions(),
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
    return const Center(child: Text('Connect to enable the Terminal.'));
  }

  Widget _buildLoadingAnimation() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text('Loading recent server logs…'),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No recent server logs. New output will appear here.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  List<Widget> _formatOutput(String output, Set<String> userCommands) {
    final widgets = <Widget>[];
    final search = _searchController.text.trim().toLowerCase();
    final lines = ConsoleOutputFormatter.visibleLines(
      output,
      hideCommonNoise: _model.hideCommonConsoleNoise,
      containing: _model.consoleFilterPattern,
    );

    for (final line in lines) {
      if (search.isNotEmpty && !line.toLowerCase().contains(search)) continue;
      final isUserCommand = userCommands.contains(line);
      final shown = ConsoleOutputFormatter.formatLine(
        line,
        _model.consoleTimestampMode,
      );
      final normalized = shown.toLowerCase();
      final isError =
          normalized.contains('error') ||
          normalized.contains('failed') ||
          normalized.contains('exception') ||
          normalized.contains('unexpected');
      final foreground = isUserCommand
          ? Theme.of(context).colorScheme.primary
          : isError
          ? Theme.of(context).colorScheme.error
          : Theme.of(context).colorScheme.onSurface;
      final outputRow = MouseRegion(
        cursor: isUserCommand
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: GestureDetector(
          onTap: isUserCommand
              ? () {
                  _setText(line);
                }
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 2),
            decoration: isUserCommand
                ? BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(4),
                  )
                : null,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 22,
                  child: MouseRegion(
                    cursor: isUserCommand
                        ? SystemMouseCursors.click
                        : MouseCursor.defer,
                    child: Text(
                      isUserCommand ? r'$' : (isError ? '!' : '›'),
                      style: TextStyle(
                        fontFamily: _model.terminalFont,
                        fontFamilyFallback: const ['Miracode', 'monospace'],
                        fontSize: _model.terminalFontSize,
                        height: 1.25,
                        fontWeight: FontWeight.bold,
                        color: foreground.withValues(alpha: 0.78),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: MouseRegion(
                    cursor: isUserCommand
                        ? SystemMouseCursors.click
                        : MouseCursor.defer,
                    child: Text(
                      shown,
                      softWrap: true,
                      style: TextStyle(
                        fontFamily: _model.terminalFont,
                        fontFamilyFallback: const ['Miracode', 'monospace'],
                        fontSize: _model.terminalFontSize,
                        height: 1.25,
                        fontWeight: isUserCommand
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: foreground,
                        decoration: isUserCommand
                            ? TextDecoration.underline
                            : TextDecoration.none,
                        decorationColor: isUserCommand
                            ? foreground.withValues(alpha: 0.8)
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      if (isUserCommand) {
        // SelectionArea installs its own text cursor over selectable glyphs,
        // which otherwise wins over the row MouseRegion on Flutter web.
        // Commands are actions (click to reuse), so exclude just those rows
        // from selection and let their click cursor apply over the glyphs too.
        widgets.add(
          Tooltip(
            message: 'Click to reuse this command',
            child: SelectionContainer.disabled(child: outputRow),
          ),
        );
      } else {
        widgets.add(outputRow);
      }
    }
    return widgets;
  }

  Widget _buildOutputTools() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          if (_searchVisible)
            Expanded(
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search console output',
                  isDense: true,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    tooltip: 'Close search',
                    onPressed: () => setState(() {
                      _searchController.clear();
                      _searchVisible = false;
                    }),
                    icon: const Icon(Icons.close),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            )
          else
            Expanded(
              child: TextButton.icon(
                onPressed: () => setState(() => _searchVisible = true),
                style: TextButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  minimumSize: const Size.fromHeight(44),
                ),
                icon: const Icon(Icons.search),
                label: const Text('Search output'),
              ),
            ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: _model.terminalAutoScroll
                ? 'Disable automatic scrolling'
                : 'Enable automatic scrolling',
            onPressed: () async {
              final enabled = !_model.terminalAutoScroll;
              await _model.setTerminalAutoScroll(enabled);
              if (enabled) _scrollToBottom(animate: true);
            },
            icon: Icon(
              _model.terminalAutoScroll
                  ? Icons.vertical_align_bottom
                  : Icons.pause_circle_outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandControls() {
    return Row(
      // The parent stretches its children, so the row is told where to start
      // rather than filling and centring its buttons.
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        IconButton(
          icon: const Icon(Icons.list),
          onPressed: () {
            // Picking a command types it into the input and hands over to the
            // completion strip, rather than interrogating the user with one
            // dialog per placeholder.
            DialogUtils.showDefaultCommandsPopup(
              context,
              (command) async => _setText('$command '),
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
          onPressed: _historyIndex < _model.commandHistory.length
              ? _navigateCommandHistoryDown
              : null,
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
          final command = suggestion.type == null
              ? MinecraftCommands.byName(
                  _model.minecraftEdition,
                )[suggestion.value]
              : null;

          // Items get their real pixel artwork; everything else keeps a
          // symbolic icon, since there is no artwork for a game rule.
          final Widget avatar = suggestion.type == ArgType.item
              ? ItemIcon(suggestion.value, size: 18, fallbackColor: color)
              : Icon(
                  command != null
                      ? _categoryIcon(command.category)
                      : CompletionIcons.forType(
                          suggestion.type,
                          suggestion.value,
                        ),
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
    final command = CommandCompletion.commandFor(
      text,
      edition: _model.minecraftEdition,
      includeMinecraftCommands:
          _model.connectionSecurity.isDirectRcon ||
          _model.supportsBridgeCapability('commands'),
      includeBridgeManagement:
          _model.connectionSecurity.supportsServerManagement,
      bridgeCapabilities: _model.advertisedBridgeCapabilities,
    );
    final rejected =
        text.trim().isNotEmpty && !CommandUtils.isAccepted(text.trim());

    if (command == null && !rejected) return const SizedBox.shrink();

    final base = Theme.of(context).textTheme.bodySmall;

    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (command != null)
            _syntaxLine(command, CommandCompletion.activeArgIndex(text), base),
          if (command != null)
            Text(
              command.description,
              style: base?.copyWith(fontStyle: FontStyle.italic),
            ),
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
      TextSpan(
        text: command.name,
        style: base?.copyWith(fontWeight: FontWeight.bold),
      ),
    ];

    for (var i = 0; i < command.args.length; i++) {
      final isActive = i == activeIndex;
      spans.add(
        TextSpan(
          text: ' ${command.args[i].hint}',
          style: base?.copyWith(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : base.color?.withValues(alpha: 0.6),
          ),
        ),
      );
    }

    return RichText(text: TextSpan(children: spans));
  }

  Widget _buildCommandInput() {
    // Tab is the conventional completion key in a console, and Flutter would
    // otherwise consume it to move focus out of the field.
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.tab): _AcceptCompletionIntent(),
      },
      child: Actions(
        actions: {
          _AcceptCompletionIntent: CallbackAction<_AcceptCompletionIntent>(
            onInvoke: (_) {
              if (_suggestions.isNotEmpty) {
                _applySuggestion(_suggestions.first.value);
              }
              return null;
            },
          ),
        },
        child: TextField(
          controller: _commandController,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: 'Enter command',
            prefixText: r'> ',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              tooltip: 'Send command',
              icon: const Icon(Icons.send_rounded),
              onPressed: () => _submitCommand(_commandController.text),
            ),
          ),
          onChanged: (_) => _refreshSuggestions(),
          onSubmitted: _submitCommand,
        ),
      ),
    );
  }

  Widget _buildScrollToBottomButton() {
    if (!_showScrollToBottom) return const SizedBox.shrink();
    return Positioned(
      bottom: 120,
      right: 16,
      // Translucent so the log stays partly visible behind it, but tinted from
      // the scheme: a fixed black stayed dark in light mode and its icon
      // disappeared against it.
      child: FloatingActionButton(
        key: const ValueKey('console-scroll-bottom'),
        onPressed: () => _scrollToBottom(animate: true),
        backgroundColor: Theme.of(
          context,
        ).colorScheme.secondaryContainer.withValues(alpha: 0.85),
        foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
        child: const Icon(Icons.arrow_downward),
      ),
    );
  }

  // No setState here: _setText refreshes the completions, and that already
  // rebuilds, which also picks up the new history index.
  void _navigateCommandHistoryUp() {
    if (_historyIndex > 0) {
      _historyIndex--;
      if (_historyIndex >= 0 && _historyIndex < _model.commandHistory.length) {
        _setText(_model.commandHistory[_historyIndex]);
      }
    }
  }

  void _navigateCommandHistoryDown() {
    if (_historyIndex < _model.commandHistory.length - 1) {
      _historyIndex++;
      _setText(_model.commandHistory[_historyIndex]);
    } else {
      _historyIndex = _model.commandHistory.length;
      _setText('');
    }
  }

  void _setCursorToEnd() => _setText(_commandController.text);

  void _scrollToBottom({bool animate = false}) {
    if (!_scrollController.hasClients) return;
    final target = _scrollController.position.maxScrollExtent;
    if (!animate) {
      _scrollController.jumpTo(target);
      _finishScrollToBottom();
      return;
    }

    _scrollController
        .animateTo(
          target,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
        )
        .whenComplete(_finishScrollToBottom);
  }

  void _finishScrollToBottom() {
    if (!mounted) return;
    // The command area and wrapped log lines may settle one frame after the
    // animation measured its target. Snap only that small remainder instead
    // of rebuilding the list at an outdated extent, which caused a blank
    // flash followed by the log appearing from the top.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final position = _scrollController.position;
      if (position.extentAfter > 1) {
        position.jumpTo(position.maxScrollExtent);
      }
      if (_showScrollToBottom) {
        setState(() => _showScrollToBottom = false);
      }
    });
  }

  void _syncScrollButton() {
    if (!_scrollController.hasClients || !mounted) return;
    final show = _scrollController.position.extentAfter > 48;
    if (show != _showScrollToBottom) {
      setState(() => _showScrollToBottom = show);
    }
  }

  Future<void> _submitCommand(String command) async {
    final sent = await _terminalController.executeCommand(
      command,
      _commandController,
    );
    if (!sent) return;
    if (!mounted) return;
    _resetHistoryIndex();
    // Clearing a TextEditingController does not fire onChanged. Route through
    // _setText so numeric suggestions and syntax hints close immediately.
    _setText('');
  }

  void _resetHistoryIndex() {
    setState(() {
      _historyIndex = _model.commandHistory.length;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_syncScrollButton);
    _focusNode.dispose();
    _scrollController.dispose();
    _commandController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

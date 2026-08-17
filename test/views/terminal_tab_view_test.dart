import 'package:admincraft/controllers/connection_controller.dart';
import 'package:admincraft/models/model.dart';
import 'package:admincraft/services/console_output_formatter.dart';
import 'package:admincraft/services/persistence_service.dart';
import 'package:admincraft/views/terminal_tab_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<Model> pumpTerminal(
    WidgetTester tester, {
    List<String> output = const [],
    bool isEnabled = true,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final model = Model(PersistenceService(preferences));
    for (final line in output) {
      model.appendOutputCommand(line);
    }

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: model),
          ChangeNotifierProvider(create: (_) => ConnectionController()),
        ],
        child: MaterialApp(
          home: Scaffold(body: TerminalTab(isEnabled: isEnabled)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return model;
  }

  testWidgets('console hides dates by default and clears numeric suggestions', (
    tester,
  ) async {
    await pumpTerminal(
      tester,
      output: const [
        '[2026-08-16 15:28:38:683 INFO] Running AutoCompaction...',
        '[2026-08-16 15:28:39:683 INFO] Server ready',
      ],
    );

    expect(find.text('Server ready'), findsOneWidget);
    final serverReady = tester.widget<Text>(find.text('Server ready'));
    expect(serverReady.style?.height, 1.25);
    expect(serverReady.strutStyle, isNull);
    expect(find.textContaining('AutoCompaction'), findsNothing);
    expect(find.textContaining('2026-08-16'), findsNothing);

    final input = find.byType(TextField).last;
    await tester.enterText(input, 'give Steve stone 64');
    await tester.pump();
    expect(find.text('64'), findsOneWidget);

    await tester.tap(find.byTooltip('Send command'));
    await tester.pumpAndSettle();

    expect(tester.widget<TextField>(input).controller?.text, isEmpty);
    expect(find.text('64'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty console stops loading after history snapshot completes', (
    tester,
  ) async {
    final model = await pumpTerminal(tester);

    expect(
      find.text('No recent server logs. New output will appear here.'),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);

    model.beginConsoleHistoryLoad();
    await tester.pump();
    expect(find.text('Loading recent server logs…'), findsOneWidget);

    model.completeConsoleHistoryLoad();
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(
      find.text('No recent server logs. New output will appear here.'),
      findsOneWidget,
    );
  });

  testWidgets('disconnecting keeps the saved transcript mounted', (
    tester,
  ) async {
    await pumpTerminal(
      tester,
      output: List.generate(40, (index) => 'Saved line $index'),
      isEnabled: false,
    );

    expect(find.text('Saved line 39'), findsOneWidget);
    expect(find.byKey(const ValueKey('console-output-list')), findsOneWidget);
    expect(
      find.text('Disconnected — saved console output remains available.'),
      findsNothing,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField).last).enabled,
      isNot(false),
    );
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is IconButton && widget.tooltip == 'Send command',
            ),
          )
          .onPressed,
      isNull,
    );
    await tester.enterText(find.byType(TextField).last, 'say after reconnect');
    expect(find.text('say after reconnect'), findsOneWidget);
  });

  testWidgets('send is enabled only for a connected non-empty command', (
    tester,
  ) async {
    await pumpTerminal(tester, output: const ['Server ready']);
    final input = find.byType(TextField).last;
    final send = find.byWidgetPredicate(
      (widget) => widget is IconButton && widget.tooltip == 'Send command',
    );

    expect(tester.widget<IconButton>(send).onPressed, isNull);
    await tester.enterText(input, 'say hello');
    await tester.pump();
    expect(tester.widget<IconButton>(send).onPressed, isNotNull);
    await tester.enterText(input, '   ');
    await tester.pump();
    expect(tester.widget<IconButton>(send).onPressed, isNull);
  });

  test('history replay notifies listeners once after the snapshot', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final model = Model(PersistenceService(preferences));
    model.beginConsoleHistoryLoad();
    var notifications = 0;
    model.addListener(() => notifications++);

    model.appendOutputCommand('First history line', eventId: 'history-1');
    model.appendOutputCommand('Second history line', eventId: 'history-2');
    expect(notifications, 0);

    model.completeConsoleHistoryLoad();
    expect(notifications, 1);
  });

  test('bulk console observations notify listeners only once', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final model = Model(PersistenceService(preferences));
    model.appendOutputCommand('keepInventory = false');
    model.appendOutputCommand('Player joined the game');
    var notifications = 0;
    model.addListener(() => notifications++);

    model.beginGameruleRefresh();
    model.appendOutputCommand('keepInventory = true');
    model.appendOutputCommand('doDaylightCycle = false');
    expect(notifications, 0);

    model.completeGameruleRefresh();
    expect(notifications, 1);
    expect(model.world.gamerules['keepInventory'], 'true');
    expect(model.world.gamerules['doDaylightCycle'], 'false');
    expect(model.output, contains('Player joined the game'));
    expect(model.output, isNot(contains('keepInventory')));
    expect(model.output, isNot(contains('doDaylightCycle')));
  });

  testWidgets('saved command text uses a clickable mouse cursor', (
    tester,
  ) async {
    final model = await pumpTerminal(tester);
    await model.addUserCommand('say reusable command');
    model.appendOutputCommand('say reusable command', isUserCommand: true);
    await tester.pump();

    final textElement = find.text('say reusable command').evaluate().single;
    MouseRegion? nearestMouseRegion;
    SelectionContainer? nearestSelectionContainer;
    textElement.visitAncestorElements((element) {
      final widget = element.widget;
      if (widget is MouseRegion) {
        nearestMouseRegion = widget;
      }
      if (widget is SelectionContainer) {
        nearestSelectionContainer = widget;
        return false;
      }
      return true;
    });
    expect(nearestMouseRegion?.cursor, SystemMouseCursors.click);
    expect(nearestSelectionContainer?.delegate, isNull);

    await tester.tap(find.text('say reusable command'));
    await tester.pump();
    final input = tester.widget<TextField>(find.byType(TextField).last);
    expect(input.controller?.text, 'say reusable command');
    expect(
      input.controller?.text,
      isNot(contains(ConsoleOutputFormatter.userCommandMarker)),
    );
  });

  testWidgets('history hearts commands and favorites can be added and edited', (
    tester,
  ) async {
    final model = await pumpTerminal(tester);
    await model.addCommandToHistory('say from history');
    await tester.pump();

    await tester.tap(find.byTooltip('Show command history'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add to favorites'));
    await tester.pump();
    expect(model.favoriteCommands, contains('say from history'));
    await tester.tap(find.byTooltip('Close history'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Show favorite commands'));
    await tester.pumpAndSettle();
    expect(find.text('Favorite commands'), findsOneWidget);
    expect(find.text('Clear All'), findsNothing);

    await tester.tap(find.byTooltip('Add favorite command'));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('favorite-command-editor')),
      'time set day',
    );
    await tester.tap(find.byTooltip('Save favorite command'));
    await tester.pumpAndSettle();
    expect(model.favoriteCommands, contains('time set day'));
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(Divider),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Edit favorite').first);
    await tester.pump();
    final inlineEditor = find.byKey(const ValueKey('favorite-command-editor'));
    expect(
      find.ancestor(of: inlineEditor, matching: find.byType(ListView)),
      findsOneWidget,
    );
    await tester.enterText(inlineEditor, 'say edited favorite');
    await tester.tap(find.byTooltip('Save favorite command'));
    await tester.pumpAndSettle();
    expect(model.favoriteCommands, contains('say edited favorite'));
    expect(model.favoriteCommands, isNot(contains('say from history')));

    await tester.tap(find.text('say edited favorite'));
    await tester.pumpAndSettle();
    final input = tester.widget<TextField>(find.byType(TextField).last);
    expect(input.controller?.text, 'say edited favorite');
  });

  testWidgets('help output is not styled as a command previously sent', (
    tester,
  ) async {
    final model = await pumpTerminal(tester);
    model.appendOutputCommand('admincraft help', isUserCommand: true);
    model.appendOutputCommand('Admincraft bridge commands:');
    model.appendOutputCommand('admincraft status');
    await tester.pump();

    expect(find.text(r'$'), findsOneWidget);
    expect(find.text('›'), findsNWidgets(2));
  });

  testWidgets('scroll-to-bottom action appears only away from the tail', (
    tester,
  ) async {
    await pumpTerminal(
      tester,
      output: List.generate(
        300,
        (index) => index.isEven
            ? 'Output line $index'
            : 'Wrapped output line $index with enough detail to occupy more than one visual row in a narrow console.',
      ),
    );

    const button = ValueKey('console-scroll-bottom');
    expect(find.byKey(button), findsNothing);

    await tester.drag(
      find.byKey(const ValueKey('console-output-list')),
      const Offset(0, 5000),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(button), findsOneWidget);

    final scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byKey(const ValueKey('console-output-list')),
        matching: find.byType(Scrollable),
      ),
    );
    final before = scrollable.position.pixels;
    final bottom = scrollable.position.minScrollExtent;

    await tester.tap(find.byKey(button));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(scrollable.position.pixels, lessThan(before));
    expect(scrollable.position.pixels, greaterThan(bottom));

    await tester.pumpAndSettle();
    expect(find.byKey(button), findsNothing);
    expect(
      scrollable.position.pixels,
      moreOrLessEquals(scrollable.position.minScrollExtent, epsilon: 1),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('large transcripts build only the visible console rows', (
    tester,
  ) async {
    await pumpTerminal(
      tester,
      output: List.generate(1000, (index) => 'Virtualized line $index'),
    );

    final builtRows = find.textContaining('Virtualized line').evaluate().length;
    expect(builtRows, lessThan(100));
    expect(find.text('Virtualized line 999'), findsOneWidget);
  });

  testWidgets('known incomplete commands remain editable instead of running', (
    tester,
  ) async {
    final model = await pumpTerminal(tester, output: const ['Server ready']);
    final input = find.byType(TextField).last;

    await tester.enterText(input, 'time');
    await tester.tap(find.byTooltip('Send command'));
    await tester.pump();

    expect(tester.widget<TextField>(input).controller?.text, 'time');
    expect(model.output, isNot(contains('\ntime\n')));
  });

  testWidgets('command browser includes bridge management commands', (
    tester,
  ) async {
    await pumpTerminal(tester);

    await tester.tap(find.byTooltip('Show default commands'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Search commands'),
      'admincraft',
    );
    await tester.pump();

    expect(
      find.descendant(
        of: find.byType(InkWell),
        matching: find.text('admincraft'),
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Inspect and manage the bridge; logs accepts an optional line count',
      ),
      findsOneWidget,
    );
  });

  testWidgets('log count appears only for the admincraft logs action', (
    tester,
  ) async {
    await pumpTerminal(tester);
    final input = find.byType(TextField).last;

    await tester.enterText(input, 'admincraft status');
    await tester.pump();
    Finder syntaxContaining(String value) => find.byWidgetPredicate(
      (widget) =>
          widget is RichText && widget.text.toPlainText().contains(value),
    );
    expect(syntaxContaining('[count]'), findsNothing);

    await tester.enterText(input, 'admincraft logs ');
    await tester.pump();
    expect(syntaxContaining('[count]'), findsOneWidget);
    expect(find.textContaining('default 250'), findsOneWidget);
  });

  testWidgets('console tools and long lines fit a narrow viewport', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 720);
    addTearDown(tester.view.reset);

    await pumpTerminal(
      tester,
      output: const [
        'A deliberately long server line that should wrap cleanly instead of clipping beyond the terminal surface.',
      ],
    );
    await tester.tap(find.text('Search output'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('console-surface')), findsOneWidget);
    expect(
      find.widgetWithText(TextField, 'Search console output'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('scrolling up pauses tail following when new output arrives', (
    tester,
  ) async {
    final model = await pumpTerminal(
      tester,
      output: List.generate(80, (index) => 'Output line $index'),
    );
    await tester.drag(
      find.byKey(const ValueKey('console-output-list')),
      const Offset(0, 500),
    );
    await tester.pumpAndSettle();
    final scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byKey(const ValueKey('console-output-list')),
        matching: find.byType(Scrollable),
      ),
    );
    final before = scrollable.position.pixels;

    model.appendOutputCommand('A new line while reading history');
    await tester.pump();
    await tester.pump();

    expect(scrollable.position.pixels, moreOrLessEquals(before, epsilon: 1));
    expect(find.byKey(const ValueKey('console-scroll-bottom')), findsOneWidget);
  });

  test('console transcript persists per server', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final first = Model(PersistenceService(preferences));
    await first.addCommandToHistory('say persisted command');
    await first.addUserCommand('say persisted command');
    first.appendOutputCommand('say persisted command');
    await Future<void>.delayed(Duration.zero);

    final reopened = Model(PersistenceService(preferences));
    expect(reopened.output, contains('say persisted command'));
    expect(reopened.commandHistory, contains('say persisted command'));
    expect(reopened.userCommands, contains('say persisted command'));
  });

  test(
    'timestamped bridge backlog is deduplicated across app launches',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final first = Model(PersistenceService(preferences));
      first.appendOutputCommand('Server ready', eventId: 'event-1');
      first.appendOutputCommand('Server ready', eventId: 'event-1');
      await Future<void>.delayed(Duration.zero);

      expect('Server ready'.allMatches(first.output), hasLength(1));

      final reopened = Model(PersistenceService(preferences));
      reopened.appendOutputCommand('Server ready', eventId: 'event-1');
      expect('Server ready'.allMatches(reopened.output), hasLength(1));
    },
  );
}

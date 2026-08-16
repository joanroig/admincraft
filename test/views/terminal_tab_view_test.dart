import 'package:admincraft/controllers/connection_controller.dart';
import 'package:admincraft/models/model.dart';
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
        child: const MaterialApp(
          home: Scaffold(body: TerminalTab(isEnabled: true)),
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
    expect(serverReady.style?.height, 1.08);
    expect(serverReady.strutStyle?.forceStrutHeight, isTrue);
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

  testWidgets('scroll-to-bottom action appears only away from the tail', (
    tester,
  ) async {
    await pumpTerminal(
      tester,
      output: List.generate(80, (index) => 'Output line $index'),
    );

    const button = ValueKey('console-scroll-bottom');
    expect(find.byKey(button), findsNothing);

    await tester.drag(find.byType(ListView).first, const Offset(0, 500));
    await tester.pumpAndSettle();
    expect(find.byKey(button), findsOneWidget);

    await tester.tap(find.byKey(button));
    await tester.pumpAndSettle();
    expect(find.byKey(button), findsNothing);
    final scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byKey(const ValueKey('console-output-list')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(
      scrollable.position.pixels,
      moreOrLessEquals(scrollable.position.maxScrollExtent, epsilon: 1),
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
}

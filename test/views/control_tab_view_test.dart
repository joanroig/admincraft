import 'package:admincraft/controllers/connection_controller.dart';
import 'package:admincraft/models/model.dart';
import 'package:admincraft/services/persistence_service.dart';
import 'package:admincraft/views/control_tab_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('server response is full width and follows console formatting', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final model = Model(PersistenceService(preferences));
    model.appendOutputCommand(
      '[2026-08-16 15:28:38:683 INFO] Running AutoCompaction...',
    );
    model.appendOutputCommand(
      '[2026-08-16 15:28:39:683 INFO] There are 0/10 players online',
    );
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: model),
          ChangeNotifierProvider(create: (_) => ConnectionController()),
        ],
        child: const MaterialApp(
          home: Scaffold(body: ControlTab(isEnabled: true)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('There are 0/10 players online'), findsOneWidget);
    expect(find.textContaining('AutoCompaction'), findsNothing);
    expect(find.textContaining('2026-08-16'), findsNothing);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('control-response-panel')))
          .width,
      390,
    );
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('opening controls does not start a duplicate status poll', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final model = Model(PersistenceService(preferences));
    final connection = _RecordingConnectionController();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: model),
          ChangeNotifierProvider<ConnectionController>.value(value: connection),
        ],
        child: const MaterialApp(
          home: Scaffold(body: ControlTab(isEnabled: true)),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(connection.quietCommands, isEmpty);
    expect(find.byTooltip('Refresh difficulty from server'), findsNothing);
  });

  testWidgets('time selection updates immediately before server confirmation', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final model = Model(PersistenceService(preferences));
    final connection = _RecordingConnectionController();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: model),
          ChangeNotifierProvider<ConnectionController>.value(value: connection),
        ],
        child: const MaterialApp(
          home: Scaffold(body: ControlTab(isEnabled: true)),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Night'));
    await tester.pump();

    expect(model.world.daytime, 13000);
    expect(model.world.timeLabel, 'Night');
    expect(connection.sentCommands, ['time set night']);
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('game rules start collapsed to keep server actions reachable', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final model = Model(PersistenceService(preferences));
    model.appendOutputCommand('[INFO] keepInventory = true');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: model),
          ChangeNotifierProvider(create: (_) => ConnectionController()),
        ],
        child: const MaterialApp(
          home: Scaffold(body: ControlTab(isEnabled: true)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Live commands'), findsNothing);
    expect(find.byKey(const ValueKey('gamerules-card')), findsOneWidget);
    expect(find.byType(SwitchListTile), findsNothing);
    await tester.ensureVisible(find.text('Game rules'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Game rules'));
    await tester.pumpAndSettle();
    expect(find.byType(SwitchListTile), findsOneWidget);
    expect(find.text('Restart Server'), findsOneWidget);
  });

  testWidgets(
    'selected controls keep their icon clear and players autocomplete',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final model = Model(PersistenceService(preferences));
      model.recordDifficulty('normal');
      model.appendOutputCommand(
        '[2026-08-16 18:00:00:000 INFO] Player connected: Steve, xuid: 1',
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: model),
            ChangeNotifierProvider(create: (_) => ConnectionController()),
          ],
          child: const MaterialApp(
            home: Scaffold(body: ControlTab(isEnabled: true)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final normal = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Normal'),
      );
      expect(normal.selected, isTrue);
      expect(normal.showCheckmark, isFalse);

      final kick = find.widgetWithText(ActionChip, 'Kick');
      await tester.ensureVisible(kick);
      await tester.pumpAndSettle();
      await tester.tap(kick);
      await tester.pumpAndSettle();
      final dialog = find.byType(AlertDialog);
      expect(
        find.descendant(of: dialog, matching: find.text('Steve')),
        findsOneWidget,
      );
      await tester.tap(
        find.descendant(of: dialog, matching: find.text('Steve')),
      );
      await tester.pump();
      final input = tester.widget<TextField>(
        find.descendant(of: dialog, matching: find.byType(TextField)),
      );
      expect(input.controller?.text, 'Steve');
    },
  );

  testWidgets('server response tray stays out of the keyboard workspace', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final model = Model(PersistenceService(preferences));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: model),
          ChangeNotifierProvider(create: (_) => ConnectionController()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(viewInsets: EdgeInsets.only(bottom: 300)),
              child: ControlTab(isEnabled: true),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('control-response-panel')), findsNothing);
  });

  testWidgets('read-only bridge capability hides mutation controls', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final model = Model(PersistenceService(preferences));
    model.updateBridgeHello(
      protocol: 2,
      capabilities: const ['logs', 'status', 'health', 'version'],
      permission: 'readonly',
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: model),
          ChangeNotifierProvider(create: (_) => ConnectionController()),
        ],
        child: const MaterialApp(
          home: Scaffold(body: ControlTab(isEnabled: true)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('credential is read-only'), findsOneWidget);
    expect(find.text('Restart Server'), findsNothing);
    expect(find.text('Normal'), findsNothing);
  });
}

class _RecordingConnectionController extends ConnectionController {
  final List<String> quietCommands = [];
  final List<String> sentCommands = [];

  @override
  Future<void> executeMinecraftCommand(
    Model model,
    String command, {
    String source = 'terminal',
  }) async {
    sentCommands.add(command);
  }

  @override
  Future<void> sendQuietly(String command) async {
    quietCommands.add(command);
  }
}

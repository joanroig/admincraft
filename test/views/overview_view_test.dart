import 'package:admincraft/controllers/connection_controller.dart';
import 'package:admincraft/models/model.dart';
import 'package:admincraft/services/persistence_service.dart';
import 'package:admincraft/views/overview_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'recent activity follows console filtering and timestamp settings',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'consoleTimestampMode': 'hidden',
        'consoleFilterPattern': 'ready',
      });
      final preferences = await SharedPreferences.getInstance();
      final model = Model(PersistenceService(preferences));
      model.appendOutputCommand(
        '[2026-08-16 17:00:00:000 INFO] Running AutoCompaction...',
      );
      model.appendOutputCommand('[2026-08-16 17:00:01:000 INFO] Server ready');
      model.appendOutputCommand(
        '[2026-08-16 17:00:02:000 INFO] There are 0/10 players online:',
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: model),
            ChangeNotifierProvider(create: (_) => ConnectionController()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: OverviewView(onOpenConsole: () {}, onEditServer: () {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Server ready'), findsOneWidget);
      final recent = tester.widget<Text>(find.text('Server ready'));
      expect(recent.style?.height, 1.25);
      expect(recent.strutStyle, isNull);
      expect(find.textContaining('2026-08-16'), findsNothing);
      expect(find.textContaining('AutoCompaction'), findsNothing);
      expect(find.textContaining('players online'), findsNothing);
      expect(find.text('Quick actions'), findsNothing);
    },
  );

  testWidgets('diagnostics shows bridge details and command audit', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final model = Model(PersistenceService(preferences));
    model.updateBridgeHello(
      protocol: 2,
      capabilities: const ['logs', 'status', 'commands'],
      version: '1.2.0',
      permission: 'command',
      connectedAt: DateTime.utc(2026, 8, 17, 10),
    );
    model.updateServerRuntimeState('running');
    await model.recordCommandAudit('list', source: 'terminal', outcome: 'sent');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: model),
          ChangeNotifierProvider(create: (_) => ConnectionController()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: OverviewView(onOpenConsole: () {}, onEditServer: () {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Diagnostics'));
    await tester.pumpAndSettle();

    expect(find.text('Connection diagnostics'), findsOneWidget);
    expect(find.text('1.2.0'), findsOneWidget);
    expect(find.text('command'), findsOneWidget);
    expect(find.text('running'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('list'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('list'), findsOneWidget);
    expect(find.textContaining('terminal · sent'), findsOneWidget);
  });
}

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

  testWidgets(
    'automatic world refresh never sends an invalid difficulty query',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final model = Model(PersistenceService(preferences));
      final connection = _RecordingConnectionController();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: model),
            ChangeNotifierProvider<ConnectionController>.value(
              value: connection,
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: ControlTab(isEnabled: true)),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(connection.quietCommands, contains('time query daytime'));
      expect(connection.quietCommands, contains('list'));
      expect(connection.quietCommands, isNot(contains('difficulty')));
      expect(find.byTooltip('Refresh difficulty from server'), findsNothing);
    },
  );
}

class _RecordingConnectionController extends ConnectionController {
  final List<String> quietCommands = [];

  @override
  Future<void> sendQuietly(String command) async {
    quietCommands.add(command);
  }
}

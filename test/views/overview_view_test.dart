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
        'consoleFilterPattern': 'players',
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

      expect(find.text('There are 0/10 players online:'), findsOneWidget);
      final recent = tester.widget<Text>(
        find.text('There are 0/10 players online:'),
      );
      expect(recent.style?.height, 1.08);
      expect(recent.strutStyle?.forceStrutHeight, isTrue);
      expect(find.textContaining('2026-08-16'), findsNothing);
      expect(find.textContaining('AutoCompaction'), findsNothing);
      expect(find.text('Server ready'), findsNothing);
      expect(find.text('Quick actions'), findsNothing);
    },
  );
}

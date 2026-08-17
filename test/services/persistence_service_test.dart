import 'package:admincraft/models/app_theme.dart';
import 'package:admincraft/models/command_audit_entry.dart';
import 'package:admincraft/services/persistence_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('app theme defaults to dirt and persists by stable name', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final persistence = PersistenceService(preferences);

    expect(persistence.appTheme, AppTheme.dirt);

    await persistence.saveAppTheme(AppTheme.obsidian);

    expect(PersistenceService(preferences).appTheme, AppTheme.obsidian);
    expect(preferences.getString('appTheme'), 'obsidian');
  });

  test('unknown app themes safely fall back to dirt', () async {
    SharedPreferences.setMockInitialValues({'appTheme': 'missing-theme'});
    final preferences = await SharedPreferences.getInstance();

    expect(PersistenceService(preferences).appTheme, AppTheme.dirt);
  });

  test(
    'console defaults to Consolas without timestamps or routine noise',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final persistence = PersistenceService(preferences);

      expect(persistence.terminalFont, 'Consolas');
      expect(persistence.maxOutLines, 1000);
      expect(persistence.consoleTimestampMode, 'hidden');
      expect(persistence.hideCommonConsoleNoise, isTrue);
    },
  );

  test('command audit is stored separately for each server', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final persistence = PersistenceService(preferences);
    final entry = CommandAuditEntry(
      occurredAt: DateTime.utc(2026, 8, 17, 12),
      command: 'admincraft status',
      source: 'terminal',
      outcome: 'sent',
    );

    await persistence.saveCommandAudit('server-a', [entry]);

    expect(persistence.commandAudit('server-a').single.command, entry.command);
    expect(persistence.commandAudit('server-b'), isEmpty);
    expect(persistence.consoleOutput('server-a'), isEmpty);
  });
}

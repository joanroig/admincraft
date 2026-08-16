import 'package:admincraft/models/app_theme.dart';
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
      expect(persistence.consoleTimestampMode, 'hidden');
      expect(persistence.hideCommonConsoleNoise, isTrue);
    },
  );
}

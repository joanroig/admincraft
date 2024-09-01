import 'package:shared_preferences/shared_preferences.dart';

class CommandHistoryController {
  static const _commandHistoryKey = 'commandHistory';

  final SharedPreferences _prefs;
  List<String> _history = [];
  int _currentIndex = -1;

  CommandHistoryController(this._prefs);

  Future<void> loadHistory() async {
    _history = _prefs.getStringList(_commandHistoryKey) ?? [];
  }

  Future<void> addCommand(String command) async {
    if (command.isNotEmpty) {
      _history.add(command);
      await _prefs.setStringList(_commandHistoryKey, _history);
    }
  }

  List<String> get history => _history;

  bool get hasHistory => _history.isNotEmpty;

  bool canNavigateUp() => _currentIndex > 0;

  bool canNavigateDown() => _currentIndex < _history.length - 1;

  void navigateUp() {
    if (canNavigateUp()) {
      _currentIndex--;
      _notifyCurrentCommand();
    }
  }

  void navigateDown() {
    if (canNavigateDown()) {
      _currentIndex++;
      _notifyCurrentCommand();
    }
  }

  void clearSelected() {
    if (_currentIndex >= 0 && _currentIndex < _history.length) {
      _history.removeAt(_currentIndex);
      _currentIndex = _history.isEmpty ? -1 : _history.length - 1;
      _prefs.setStringList(_commandHistoryKey, _history);
      _notifyCurrentCommand();
    }
  }

  void _notifyCurrentCommand() {
    // Notify the UI or any listeners about the current command
  }
}

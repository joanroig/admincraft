import 'dart:convert';

import 'package:admincraft/models/app_notification.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationController with ChangeNotifier {
  static const _storageKey = 'notificationHistory';
  static const _maximumEntries = 100;
  static const _popupsKey = 'notificationPopupsEnabled';

  final SharedPreferences _preferences;
  late List<AppNotification> _entries;

  NotificationController(this._preferences) {
    _entries = (_preferences.getStringList(_storageKey) ?? const [])
        .map((value) {
          try {
            return AppNotification.fromJson(
              jsonDecode(value) as Map<String, dynamic>,
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<AppNotification>()
        .toList();
  }

  List<AppNotification> get entries => List.unmodifiable(_entries.reversed);
  int get unreadCount => _entries.where((entry) => !entry.read).length;
  bool get popupsEnabled => _preferences.getBool(_popupsKey) ?? true;

  Future<void> setPopupsEnabled(bool value) async {
    await _preferences.setBool(_popupsKey, value);
    notifyListeners();
  }

  void add({
    required AppNotificationKind kind,
    required String title,
    required String message,
  }) {
    final now = DateTime.now().toUtc();
    _entries.add(
      AppNotification(
        id: now.microsecondsSinceEpoch.toString(),
        kind: kind,
        title: title,
        message: message,
        createdAt: now,
      ),
    );
    if (_entries.length > _maximumEntries) {
      _entries = _entries.sublist(_entries.length - _maximumEntries);
    }
    _persist();
    notifyListeners();
  }

  void markAllRead() {
    if (_entries.every((entry) => entry.read)) return;
    _entries = _entries.map((entry) => entry.copyWith(read: true)).toList();
    _persist();
    notifyListeners();
  }

  void clear() {
    _entries = [];
    _persist();
    notifyListeners();
  }

  void _persist() {
    _preferences.setStringList(
      _storageKey,
      _entries.map((entry) => jsonEncode(entry.toJson())).toList(),
    );
  }
}

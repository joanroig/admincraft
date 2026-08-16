import 'package:admincraft/controllers/notification_controller.dart';
import 'package:admincraft/models/app_notification.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('notification history persists and can be marked read', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final controller = NotificationController(preferences);

    controller.add(
      kind: AppNotificationKind.error,
      title: 'Disconnected',
      message: 'The connection closed.',
    );
    expect(controller.unreadCount, 1);

    controller.markAllRead();
    final restored = NotificationController(preferences);
    expect(restored.entries.single.message, 'The connection closed.');
    expect(restored.unreadCount, 0);
  });
}

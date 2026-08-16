import 'package:admincraft/controllers/notification_controller.dart';
import 'package:admincraft/utils/toast_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('notification banners do not block controls underneath', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    ToastUtils.initialize(NotificationController(preferences));
    var taps = 0;

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: ToastUtils.navigatorKey,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 62),
              child: SizedBox(
                width: 300,
                height: 48,
                child: FilledButton(
                  key: const ValueKey('under-notification'),
                  onPressed: () => taps++,
                  child: const Text('Underlying action'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    ToastUtils.showInfo('Connected', 'The server is ready.');
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Connected'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('under-notification')));
    await tester.pump();
    expect(taps, 1);

    ToastUtils.dismissPopups();
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });
}

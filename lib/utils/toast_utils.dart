import 'package:admincraft/controllers/notification_controller.dart';
import 'package:admincraft/models/app_notification.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class ToastUtils {
  static NotificationController? _notifications;

  static void initialize(NotificationController notifications) {
    _notifications = notifications;
  }

  static void showToastError(String message) {
    _notifications?.add(
      kind: AppNotificationKind.error,
      title: 'Connection or command error',
      message: message,
    );
    if (_notifications?.popupsEnabled == false) return;
    toastification.show(
      type: ToastificationType.error,
      style: ToastificationStyle.flat,
      autoCloseDuration: const Duration(seconds: 8),
      title: const Text('Error'),
      description: Text(message),
      alignment: Alignment.topRight,
      margin: const EdgeInsets.fromLTRB(12, 64, 12, 8),
      animationDuration: const Duration(milliseconds: 100),
    );
  }

  static void showToastSuccess(String message) {
    _notifications?.add(
      kind: AppNotificationKind.success,
      title: 'Completed',
      message: message,
    );
    if (_notifications?.popupsEnabled == false) return;
    toastification.show(
      type: ToastificationType.success,
      style: ToastificationStyle.flat,
      autoCloseDuration: const Duration(seconds: 2),
      title: Text(message),
      alignment: Alignment.topRight,
      margin: const EdgeInsets.fromLTRB(12, 64, 12, 8),
      animationDuration: const Duration(milliseconds: 100),
    );
  }

  static void showInfo(String title, String message) {
    _notifications?.add(
      kind: AppNotificationKind.info,
      title: title,
      message: message,
    );
    if (_notifications?.popupsEnabled == false) return;
    toastification.show(
      type: ToastificationType.info,
      style: ToastificationStyle.flat,
      autoCloseDuration: const Duration(seconds: 5),
      title: Text(title),
      description: Text(message),
      alignment: Alignment.topRight,
      margin: const EdgeInsets.fromLTRB(12, 64, 12, 8),
      animationDuration: const Duration(milliseconds: 100),
    );
  }
}

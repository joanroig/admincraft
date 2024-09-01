import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class ToastUtils {
  static void showToastError(String message) {
    toastification.show(
      type: ToastificationType.error,
      style: ToastificationStyle.flat,
      autoCloseDuration: const Duration(seconds: 5),
      title: const Text('Error'),
      description: Text(message),
      alignment: Alignment.bottomCenter,
      animationDuration: const Duration(milliseconds: 100),
    );
  }

  static void showToastSuccess(String message) {
    toastification.show(
      type: ToastificationType.success,
      style: ToastificationStyle.flat,
      autoCloseDuration: const Duration(seconds: 2),
      title: Text(message),
      alignment: Alignment.bottomCenter,
      animationDuration: const Duration(milliseconds: 100),
    );
  }
}

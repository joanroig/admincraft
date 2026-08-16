import 'dart:async';

import 'package:admincraft/controllers/notification_controller.dart';
import 'package:admincraft/models/app_notification.dart';
import 'package:flutter/material.dart';

class ToastUtils {
  static NotificationController? _notifications;
  static final navigatorKey = GlobalKey<NavigatorState>();
  static OverlayEntry? _popupEntry;
  static Timer? _popupTimer;

  static void initialize(NotificationController notifications) {
    _notifications = notifications;
  }

  static void showToastError(String message) {
    final added = _notifications?.add(
      kind: AppNotificationKind.error,
      title: 'Connection or command error',
      message: message,
    );
    if (added == false || _notifications?.popupsEnabled == false) return;
    _showPopup(
      kind: AppNotificationKind.error,
      title: 'Error',
      message: message,
      duration: const Duration(milliseconds: 3500),
    );
  }

  static void showToastSuccess(String message) {
    final added = _notifications?.add(
      kind: AppNotificationKind.success,
      title: 'Completed',
      message: message,
    );
    if (added == false || _notifications?.popupsEnabled == false) return;
    _showPopup(
      kind: AppNotificationKind.success,
      title: message,
      duration: const Duration(milliseconds: 1400),
    );
  }

  static void showInfo(String title, String message) {
    final added = _notifications?.add(
      kind: AppNotificationKind.info,
      title: title,
      message: message,
    );
    if (added == false || _notifications?.popupsEnabled == false) return;
    _showPopup(
      kind: AppNotificationKind.info,
      title: title,
      message: message,
      duration: const Duration(milliseconds: 2400),
    );
  }

  static void _showPopup({
    required AppNotificationKind kind,
    required String title,
    String? message,
    required Duration duration,
  }) {
    // Popups are only a glanceable hint; the inbox keeps the durable copy.
    // The visual card ignores pointers so controls underneath remain usable.
    // A separate, tightly bounded close button is the only interactive part
    // of the overlay.
    dismissPopups();
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;

    _popupEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: SafeArea(
                bottom: false,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      12,
                      kToolbarHeight + 6,
                      12,
                      0,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: _CompactNotification(
                        kind: kind,
                        title: title,
                        message: message,
                        duration: duration,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  12,
                  kToolbarHeight + 6,
                  12,
                  0,
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 1, right: 3),
                        child: IconButton(
                          key: const ValueKey('dismiss-notification-popup'),
                          tooltip: 'Dismiss notification',
                          visualDensity: VisualDensity.compact,
                          color: Theme.of(context).colorScheme.onInverseSurface,
                          onPressed: dismissPopups,
                          icon: const Icon(Icons.close, size: 18),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    overlay.insert(_popupEntry!);
    _popupTimer = Timer(duration, dismissPopups);
  }

  static void dismissPopups() {
    _popupTimer?.cancel();
    _popupTimer = null;
    _popupEntry?.remove();
    _popupEntry = null;
  }
}

class _CompactNotification extends StatelessWidget {
  final AppNotificationKind kind;
  final String title;
  final String? message;
  final Duration duration;

  const _CompactNotification({
    required this.kind,
    required this.title,
    required this.duration,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final (icon, accent) = switch (kind) {
      AppNotificationKind.error => (
        Icons.error_outline,
        dark ? Colors.red.shade300 : Colors.red.shade700,
      ),
      AppNotificationKind.warning => (
        Icons.warning_amber,
        dark ? Colors.orange.shade300 : Colors.orange.shade800,
      ),
      AppNotificationKind.success => (
        Icons.check_circle_outline,
        dark ? Colors.greenAccent.shade100 : Colors.green.shade800,
      ),
      AppNotificationKind.info => (Icons.info_outline, scheme.inversePrimary),
    };
    final detail = message?.trim();

    return Material(
      elevation: 6,
      color: scheme.inverseSurface,
      shadowColor: Colors.black.withValues(alpha: 0.55),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: accent.withValues(alpha: 0.75)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: accent, size: 20),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: scheme.onInverseSurface,
                        ),
                      ),
                      if (detail != null &&
                          detail.isNotEmpty &&
                          detail != title)
                        Text(
                          detail,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: scheme.onInverseSurface.withValues(
                                  alpha: 0.82,
                                ),
                              ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 30),
              ],
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: duration,
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 2,
              color: accent,
              backgroundColor: accent.withValues(alpha: 0.18),
            ),
          ),
        ],
      ),
    );
  }
}

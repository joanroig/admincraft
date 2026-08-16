import 'package:admincraft/controllers/notification_controller.dart';
import 'package:admincraft/models/app_notification.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NotificationInboxButton extends StatelessWidget {
  const NotificationInboxButton({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NotificationController?>();
    if (controller == null) return const SizedBox.shrink();
    final count = controller.unreadCount;
    return Badge(
      isLabelVisible: count > 0,
      label: Text(count > 9 ? '9+' : '$count'),
      alignment: AlignmentDirectional.topEnd,
      offset: const Offset(-4, 5),
      largeSize: 17,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox.square(
        dimension: 48,
        child: IconButton(
          tooltip: 'Notification history',
          onPressed: () => showNotificationInbox(context),
          icon: Icon(
            count > 0 ? Icons.notifications_outlined : Icons.notifications_none,
          ),
        ),
      ),
    );
  }
}

Future<void> showNotificationInbox(BuildContext context) async {
  final controller = context.read<NotificationController>();
  controller.markAllRead();
  await showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => const FractionallySizedBox(
      heightFactor: 0.72,
      child: _NotificationInbox(),
    ),
  );
}

class _NotificationInbox extends StatelessWidget {
  const _NotificationInbox();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NotificationController>();
    final entries = controller.entries;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 10, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Notifications',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              TextButton.icon(
                onPressed: entries.isEmpty ? null : controller.clear,
                icon: const Icon(Icons.delete_sweep_outlined),
                label: const Text('Clear'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: entries.isEmpty
              ? const Center(child: Text('No notifications yet.'))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return ListTile(
                      isThreeLine: true,
                      leading: Icon(
                        _icon(entry.kind),
                        color: _color(entry.kind, context),
                      ),
                      title: Text(entry.title),
                      subtitle: Text(
                        '${entry.message}\n${_when(entry.createdAt)}',
                        maxLines: 6,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  static IconData _icon(AppNotificationKind kind) => switch (kind) {
    AppNotificationKind.info => Icons.info_outline,
    AppNotificationKind.success => Icons.check_circle_outline,
    AppNotificationKind.warning => Icons.warning_amber,
    AppNotificationKind.error => Icons.error_outline,
  };

  static Color _color(AppNotificationKind kind, BuildContext context) =>
      switch (kind) {
        AppNotificationKind.error => Theme.of(context).colorScheme.error,
        AppNotificationKind.warning => Colors.orange,
        AppNotificationKind.success => Colors.green,
        AppNotificationKind.info => Theme.of(context).colorScheme.primary,
      };

  static String _when(DateTime value) {
    final local = value.toLocal();
    final date =
        '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
    final time =
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }
}

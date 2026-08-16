enum AppNotificationKind { info, success, warning, error }

class AppNotification {
  final String id;
  final AppNotificationKind kind;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool read;

  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.message,
    required this.createdAt,
    this.read = false,
  });

  AppNotification copyWith({bool? read, DateTime? createdAt}) => AppNotification(
    id: id,
    kind: kind,
    title: title,
    message: message,
    createdAt: createdAt ?? this.createdAt,
    read: read ?? this.read,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'title': title,
    'message': message,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'read': read,
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      kind: AppNotificationKind.values.firstWhere(
        (value) => value.name == json['kind'],
        orElse: () => AppNotificationKind.info,
      ),
      title: json['title'] as String? ?? 'Admincraft',
      message: json['message'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now().toUtc(),
      read: json['read'] as bool? ?? false,
    );
  }
}
